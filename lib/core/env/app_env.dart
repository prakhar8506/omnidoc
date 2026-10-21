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

  /// Web OAuth client ID from Google Cloud. Android requires this. iOS uses
  /// it as the server client. This is not a Supabase key.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  /// iOS OAuth client ID. Required on iPhone so Google can match the app.
  /// Android ignores it and matches the install by package name and certificate.
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
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
    String base;
    if (aiGatewayUrl.isNotEmpty) {
      base = aiGatewayUrl.replaceAll(RegExp(r'/$'), '');
    } else if (supabaseUrl.isEmpty) {
      return '';
    } else {
      base = '${supabaseUrl.replaceAll(RegExp(r'/$'), '')}/functions/v1';
    }
    // Normalize common misconfigs: .../functions → .../functions/v1
    if (base.endsWith('/functions')) {
      base = '$base/v1';
    } else if (!base.contains('/functions')) {
      base = '$base/functions/v1';
    }
    return base;
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
