import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_account.dart';

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

    final id = _uuid.v4();
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
