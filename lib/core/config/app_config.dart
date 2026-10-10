/// Application environment and runtime configuration.
/// 
/// Values can be injected at build time using `--dart-define-from-file=.env.json`
/// or individually via `--dart-define=SUPABASE_URL=...`
class AppConfig {
  const AppConfig._();

  static const String appName = 'HealthBase';
  static const String appTagline = 'Your health. Your baseline. Your history.';
  static const String appVersion = '0.1.0';

  // Raw build-time injections (empty when no --dart-define is passed).
  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Compiled-in fallback project (used until repository secrets are set).
  // TODO(security): remove these defaults once SUPABASE_URL /
  // SUPABASE_ANON_KEY secrets are configured and the anon key is rotated.
  static const String _fallbackUrl =
      'https://bnyirihxshgwsahmotjh.supabase.co';
  static const String _fallbackAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJueWlyaWh4c2hnd3NhaG1vdGpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEzOTI2MzEsImV4cCI6MjEwNjk2ODYzMX0.Ux3uwXkaNHxca5YpfBRi6L1I8YVFxeXPi6P_l2kVYP4';

  /// Supabase project URL (build secret wins, fallback otherwise).
  static String get supabaseUrl =>
      _envUrl.isNotEmpty ? _envUrl : _fallbackUrl;

  /// Supabase client publishable anon key (build secret wins, fallback
  /// otherwise).
  ///
  /// NOTE: The service-role key must NEVER be included or referenced here.
  static String get supabaseAnonKey =>
      _envAnonKey.isNotEmpty ? _envAnonKey : _fallbackAnonKey;

  /// Ensures that critical configuration keys are present before application startup.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
