import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keystore-backed storage. Existing SharedPreferences values are moved
/// across on the next read and then removed from the plain store.
class SecureStore {
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
  );

  static Future<String?> readString(String key) async {
    try {
      final current = await _secure.read(key: key);
      if (current != null) return current;
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(key);
    if (legacy == null) return null;
    try {
      await _secure.write(key: key, value: legacy);
      await prefs.remove(key);
    } catch (_) {}
    return legacy;
  }

  static Future<void> writeString(String key, String value) async {
    await _secure.write(key: key, value: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> delete(String key) async {
    try {
      await _secure.delete(key: key);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<List<String>> readStringList(String key) async {
    final raw = await readString(key);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList();
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getStringList(key);
    if (legacy == null) return [];
    await writeString(key, jsonEncode(legacy));
    return legacy;
  }

  static Future<void> writeStringList(String key, List<String> values) {
    return writeString(key, jsonEncode(values));
  }
}
