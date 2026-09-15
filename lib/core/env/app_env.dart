/// Type-safe environment configuration for Supabase and production services.
/// Values are supplied at build time via --dart-define or --dart-define-from-file.
/// No secrets are hardcoded in source.
class AppEnv {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Returns true if valid Supabase configuration was provided at compile/run time.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Fails fast if mandatory credentials are required in strict production mode.
  static void validateRequired() {
    if (!isSupabaseConfigured) {
      throw StateError(
        'Missing Supabase credentials! Supply SUPABASE_URL and SUPABASE_ANON_KEY '
        'via --dart-define or --dart-define-from-file=env/production.json',
      );
    }
  }
}
