import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../env/app_env.dart';

/// One free Premium trial per physical device, across email accounts.
class DeviceTrial {
  static const blockedMessage = 'Maximum free trials have been used from this device.';
  static const _prefKey = 'hc_trial_device_hash';
  static const _channel = MethodChannel('cura/health_connect');

  static Future<String> fingerprint() async {
    var raw = 'unavailable';
    try {
      final id = await _channel.invokeMethod<String>('androidId');
      if (id != null && id.isNotEmpty) raw = id;
    } catch (_) {}
    return sha256.convert(utf8.encode('cura-trial:$raw')).toString();
  }

  /// Returns null when this device may start a trial.
  static Future<String?> claim() async {
    final hash = await fingerprint();
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getString(_prefKey) ?? '').isNotEmpty) {
      return blockedMessage;
    }

    final remote = await _claimRemote(hash);
    if (remote == false) {
      await prefs.setString(_prefKey, hash);
      return blockedMessage;
    }

    await prefs.setString(_prefKey, hash);
    return null;
  }

  /// true = newly claimed, false = already used, null = server not reachable.
  static Future<bool?> _claimRemote(String hash) async {
    if (!AppEnv.isSupabaseConfigured) return null;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'claim-device-trial',
        body: {'device_hash': hash},
      );
      final data = response.data;
      if (data is Map && data['allowed'] is bool) {
        return data['allowed'] as bool;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
