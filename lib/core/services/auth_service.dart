import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/user_account.dart';
import '../network/supabase_repository.dart';
import '../storage/secure_store.dart';
import 'google_auth.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  static const _usersKey = 'hc_users_v1';
  static const _sessionUserIdKey = 'hc_session_user_id';
  static const _uuid = Uuid();
  final HealthBackendRepository? backendRepository;

  /// True after register when Cura's greeting was accepted by the mailer.
  bool welcomeNoteSent = false;

  AuthService({this.backendRepository});

  String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }

  Future<List<UserAccount>> getUsers() async {
    return UserAccount.listFromJsonString(await SecureStore.readString(_usersKey));
  }

  Future<void> _saveUsers(List<UserAccount> users) async {
    await SecureStore.writeString(_usersKey, UserAccount.listToJsonString(users));
  }

  Future<void> _persistUserLocally(UserAccount user) async {
    final users = await getUsers();
    final index = users.indexWhere((u) => u.id == user.id || u.email == user.email);
    if (index >= 0) {
      users[index] = user;
    } else {
      users.add(user);
    }
    await _saveUsers(users);
  }

  Future<String?> getSessionUserId() async {
    return SecureStore.readString(_sessionUserIdKey);
  }

  Future<UserAccount?> getSessionUser() async {
    final id = await getSessionUserId();
    if (id == null) return null;
    final users = await getUsers();
    try {
      return users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Removes the local account record and session for [userId]. Used after a
  /// successful account deletion so no credentials or profile survive on device.
  Future<void> purgeLocalAccount(String userId) async {
    final users = await getUsers();
    users.removeWhere((u) => u.id == userId);
    await _saveUsers(users);
    await SecureStore.delete(_sessionUserIdKey);
  }

  Future<UserAccount?> findByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    final users = await getUsers();
    try {
      return users.firstWhere((u) => u.email == normalized);
    } catch (_) {
      return null;
    }
  }

  void _requireRemoteBackendInRelease() {
    if (kReleaseMode && (backendRepository == null || !backendRepository!.isConfigured)) {
      throw AuthException(
        'Supabase is not configured. Supply SUPABASE_URL and SUPABASE_ANON_KEY '
        'via --dart-define or --dart-define-from-file before signing in.',
      );
    }
  }

  Future<UserAccount> register({
    required String fullName,
    required String email,
    required String password,
    String bloodType = 'Unknown',
  }) async {
    final name = fullName.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (name.isEmpty) throw AuthException('Please enter your full name.');
    if (!_isValidEmail(normalizedEmail)) {
      throw AuthException('Please enter a valid email address.');
    }
    if (password.length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }

    _requireRemoteBackendInRelease();
    welcomeNoteSent = false;

    final useRemote = backendRepository != null &&
        backendRepository!.isConfigured &&
        !normalizedEmail.endsWith('.local');
    final existing = await findByEmail(normalizedEmail);
    if (existing != null && !kReleaseMode) {
      throw AuthException('An account with this email already exists. Please sign in.');
    }

    String id = _uuid.v4();

    if (useRemote) {
      try {
        final prepared = await backendRepository!.prepareAccount(
          email: normalizedEmail,
          password: password,
          fullName: name,
          bloodType: bloodType,
        );
        if (prepared != null) {
          id = prepared.userId;
          welcomeNoteSent = prepared.greeted;
          try {
            await backendRepository!.signIn(email: normalizedEmail, password: password);
          } catch (e) {
            debugPrint('[AuthService] Session after welcome was not attached');
          }
          // The account exists but no session came back, which means this
          // project still requires email confirmation. Say so instead of
          // dropping the person into an app that cannot reach their data.
          if (kReleaseMode && backendRepository!.currentUserId == null) {
            throw AuthException(
              'Your account was created, but we could not start a session. '
              'Please sign in with the same email and password.',
            );
          }
        } else if (kReleaseMode) {
          throw AuthException('Unable to create account. Please try again.');
        }
      } catch (e) {
        if (e is AuthException) rethrow;
        final message = e.toString().toLowerCase();
        if (message.contains('already registered') || message.contains('already been registered')) {
          throw AuthException('That email already has an account. Please sign in.');
        }
        if (kReleaseMode) {
          throw AuthException('Unable to create account. Please try again.');
        }
        debugPrint('[AuthService] Welcome account unavailable');
      }
    } else if (kReleaseMode) {
      throw AuthException(
        'Supabase is not configured. Please configure backend credentials.',
      );
    }

    final hash = kReleaseMode ? '' : hashPassword(password, id);
    final user = UserAccount(
      id: id,
      fullName: name,
      email: normalizedEmail,
      passwordHash: hash,
      bloodType: bloodType,
      createdAt: DateTime.now(),
    );

    await _persistUserLocally(user);

    await SecureStore.writeString(_sessionUserIdKey, user.id);
    return user;
  }

  Future<UserAccount> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_isValidEmail(normalizedEmail)) {
      throw AuthException('Please enter a valid email address.');
    }
    if (password.isEmpty) {
      throw AuthException('Please enter your password.');
    }

    _requireRemoteBackendInRelease();

    // Prefer remote sign-in when configured
    if (backendRepository != null && backendRepository!.isConfigured) {
      try {
        final authRes = await backendRepository!.signIn(
          email: normalizedEmail,
          password: password,
        );
        if (authRes?.user != null && authRes!.session != null) {
          final remoteUser = authRes.user!;
          final localUser = await findByEmail(normalizedEmail);
          final persisted = UserAccount(
            id: remoteUser.id,
            fullName: (remoteUser.userMetadata?['full_name'] as String?) ??
                localUser?.fullName ??
                'User',
            email: normalizedEmail,
            passwordHash: kReleaseMode ? '' : hashPassword(password, remoteUser.id),
            bloodType: (remoteUser.userMetadata?['blood_type'] as String?) ??
                localUser?.bloodType ??
                'Unknown',
            avatarPath: localUser?.avatarPath,
            createdAt: localUser?.createdAt ?? DateTime.now(),
          );
          // Always persist so getSessionUser works after remote sign-in
          await _persistUserLocally(persisted);

          await SecureStore.writeString(_sessionUserIdKey, persisted.id);
          return persisted;
        }
        if (kReleaseMode) {
          throw AuthException('Sign in failed. Please check your credentials.');
        }
      } catch (e) {
        if (e is AuthException) rethrow;
        debugPrint('[AuthService] Remote signIn error: $e');
        if (kReleaseMode) {
          final text = e.toString().toLowerCase();
          if (text.contains('invalid_credentials') || text.contains('invalid login')) {
            throw AuthException(
              'That email and password do not match an account. Create an account, or use Continue with Google.',
            );
          }
          if (text.contains('email not confirmed')) {
            throw AuthException('Confirm that email from your inbox, then sign in.');
          }
          throw AuthException('Could not reach the sign-in service. Check your connection and try again.');
        }
      }
    }

    // Local SharedPreferences offline auth — debug/profile only
    if (kReleaseMode) {
      throw AuthException(
        'Supabase is not configured. Please configure backend credentials.',
      );
    }

    final user = await findByEmail(normalizedEmail);
    if (user == null) {
      throw AuthException('No account found for this email. Create an account first.');
    }

    final hash = hashPassword(password, user.id);
    if (hash != user.passwordHash) {
      throw AuthException('Incorrect password. Please try again.');
    }

    await SecureStore.writeString(_sessionUserIdKey, user.id);
    return user;
  }

  /// Saves a Google account as the on-device session. Does not call Supabase.
  Future<({UserAccount user, bool isNew})> signInWithGoogleAccount({
    required String googleUserId,
    required String email,
    required String? fullName,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (!_isValidEmail(normalized)) {
      throw AuthException('Google did not share an email address.');
    }

    final local = await findByEmail(normalized);
    final providedName = (fullName ?? '').trim();
    final name = providedName.isNotEmpty
        ? providedName
        : (local?.fullName ?? normalized.split('@').first);
    final id = (local?.id ?? googleUserId.trim()).isNotEmpty
        ? (local?.id ?? googleUserId.trim())
        : normalized;
    final user = UserAccount(
      id: id,
      fullName: name,
      email: normalized,
      passwordHash: '',
      bloodType: local?.bloodType ?? 'Unknown',
      avatarPath: local?.avatarPath,
      createdAt: local?.createdAt ?? DateTime.now(),
    );
    await _persistUserLocally(user);
    await SecureStore.writeString(_sessionUserIdKey, user.id);
    return (user: user, isNew: local == null);
  }

  /// Writes the current Supabase user into the on-device session.
  /// Returns null when nobody is signed in remotely.
  /// [isNew] is true only when this email has never been stored on the device.
  Future<({UserAccount user, bool isNew})?> adoptRemoteSession() async {
    final remote = backendRepository?.remoteIdentity;
    if (remote == null || remote.id.isEmpty || remote.email.isEmpty) return null;

    final local = await findByEmail(remote.email);
    final name = remote.fullName.isNotEmpty
        ? remote.fullName
        : (local?.fullName ?? remote.email.split('@').first);
    final user = UserAccount(
      id: remote.id,
      fullName: name,
      email: remote.email,
      passwordHash: '',
      bloodType: remote.bloodType == 'Unknown'
          ? (local?.bloodType ?? 'Unknown')
          : remote.bloodType,
      avatarPath: local?.avatarPath,
      createdAt: local?.createdAt ?? remote.createdAt ?? DateTime.now(),
    );
    await _persistUserLocally(user);
    await SecureStore.writeString(_sessionUserIdKey, user.id);
    return (user: user, isNew: local == null);
  }

  Future<void> signOut() async {
    await GoogleAuth.signOut();
    if (backendRepository != null && backendRepository!.isConfigured) {
      try {
        await backendRepository!.signOut();
      } catch (e) {
        debugPrint('[AuthService] Remote signOut error: $e');
      }
    }
    await SecureStore.delete(_sessionUserIdKey);
  }

  Future<UserAccount> updateProfile(UserAccount updated) async {
    final users = await getUsers();
    final index = users.indexWhere((u) => u.id == updated.id);
    if (index < 0) throw AuthException('Account not found.');
    users[index] = updated;
    await _saveUsers(users);
    return updated;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
}
