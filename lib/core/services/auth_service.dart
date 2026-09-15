import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_account.dart';
import '../network/supabase_repository.dart';

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

  AuthService({this.backendRepository});

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }

  Future<List<UserAccount>> getUsers() async {
    final prefs = await _prefs;
    return UserAccount.listFromJsonString(prefs.getString(_usersKey));
  }

  Future<void> _saveUsers(List<UserAccount> users) async {
    final prefs = await _prefs;
    await prefs.setString(_usersKey, UserAccount.listToJsonString(users));
  }

  Future<String?> getSessionUserId() async {
    final prefs = await _prefs;
    return prefs.getString(_sessionUserIdKey);
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

  Future<UserAccount?> findByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    final users = await getUsers();
    try {
      return users.firstWhere((u) => u.email == normalized);
    } catch (_) {
      return null;
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

    final existing = await findByEmail(normalizedEmail);
    if (existing != null) {
      throw AuthException('An account with this email already exists. Please sign in.');
    }

    String id = _uuid.v4();

    // If Supabase is configured, register with hosted Auth
    if (backendRepository != null && backendRepository!.isConfigured) {
      try {
        final authRes = await backendRepository!.signUp(
          email: normalizedEmail,
          password: password,
          fullName: name,
          bloodType: bloodType,
        );
        if (authRes?.user?.id != null) {
          id = authRes!.user!.id;
        }
      } catch (e) {
        debugPrint('[AuthService] Supabase remote sign up error (falling back to offline): $e');
      }
    }

    final hash = hashPassword(password, id);
    final user = UserAccount(
      id: id,
      fullName: name,
      email: normalizedEmail,
      passwordHash: hash,
      bloodType: bloodType,
      createdAt: DateTime.now(),
    );

    final users = await getUsers();
    users.add(user);
    await _saveUsers(users);

    final prefs = await _prefs;
    await prefs.setString(_sessionUserIdKey, user.id);
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

    // Try remote sign in if configured
    if (backendRepository != null && backendRepository!.isConfigured) {
      try {
        final authRes = await backendRepository!.signIn(
          email: normalizedEmail,
          password: password,
        );
        if (authRes?.user != null) {
          final remoteUser = authRes!.user!;
          final localUser = await findByEmail(normalizedEmail);
          final user = localUser ??
              UserAccount(
                id: remoteUser.id,
                fullName: (remoteUser.userMetadata?['full_name'] as String?) ?? 'User',
                email: normalizedEmail,
                passwordHash: hashPassword(password, remoteUser.id),
                bloodType: (remoteUser.userMetadata?['blood_type'] as String?) ?? 'Unknown',
                createdAt: DateTime.now(),
              );
          final prefs = await _prefs;
          await prefs.setString(_sessionUserIdKey, user.id);
          return user;
        }
      } catch (e) {
        debugPrint('[AuthService] Remote signIn error: $e');
      }
    }

    final user = await findByEmail(normalizedEmail);
    if (user == null) {
      throw AuthException('No account found for this email. Create an account first.');
    }

    final hash = hashPassword(password, user.id);
    if (hash != user.passwordHash) {
      throw AuthException('Incorrect password. Please try again.');
    }

    final prefs = await _prefs;
    await prefs.setString(_sessionUserIdKey, user.id);
    return user;
  }

  Future<void> signOut() async {
    if (backendRepository != null && backendRepository!.isConfigured) {
      try {
        await backendRepository!.signOut();
      } catch (e) {
        debugPrint('[AuthService] Remote signOut error: $e');
      }
    }
    final prefs = await _prefs;
    await prefs.remove(_sessionUserIdKey);
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
