import 'package:flutter/foundation.dart';

/// Type-safe environment configuration.
/// Supply values at build/run time via `--dart-define` or `--dart-define-from-file`.
class AppEnv {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Base URL for Edge Functions (defaults to `$SUPABASE_URL/functions/v1`).
  static const String aiGatewayUrl = String.fromEnvironment(
    'AI_GATEWAY_URL',
    defaultValue: '',
  );

  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  /// Debug-only demo persona. Ignored / forced off in release.
  static const bool _enableDemoDefine = bool.fromEnvironment(
    'ENABLE_DEMO',
    defaultValue: false,
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('YOUR_PROJECT') &&
      !supabaseUrl.contains('placeholder.supabase');

  static bool get enableDemo => kDebugMode && _enableDemoDefine;

  /// Alias used by tests and UI checks.
  static bool get isDemoEnabled => enableDemo;

  static String get functionsBaseUrl {
    if (aiGatewayUrl.isNotEmpty) return aiGatewayUrl.replaceAll(RegExp(r'/$'), '');
    if (supabaseUrl.isEmpty) return '';
    return '${supabaseUrl.replaceAll(RegExp(r'/$'), '')}/functions/v1';
  }

  /// Fails fast when mandatory production credentials are missing.
  static void validateRequired() {
    if (!isSupabaseConfigured) {
      throw StateError(
        'Missing Supabase credentials. Supply SUPABASE_URL and SUPABASE_ANON_KEY '
        'via --dart-define or --dart-define-from-file=env/production.json',
      );
    }
  }
}
