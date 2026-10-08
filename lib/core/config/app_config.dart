/// Application environment and runtime configuration.
/// 
/// Values can be injected at build time using `--dart-define-from-file=.env.json`
/// or individually via `--dart-define=SUPABASE_URL=...`
class AppConfig {
  const AppConfig._();

  static const String appName = 'HealthBase';
  static const String appTagline = 'Your health. Your baseline. Your history.';
  static const String appVersion = '0.1.0';

  /// Supabase project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bnyirihxshgwsahmotjh.supabase.co',
  );

  /// Supabase client publishable anon key.
  /// 
  /// NOTE: The service-role key must NEVER be included or referenced here.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJueWlyaWh4c2hnd3NhaG1vdGpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEzOTI2MzEsImV4cCI6MjEwNjk2ODYzMX0.Ux3uwXkaNHxca5YpfBRi6L1I8YVFxeXPi6P_l2kVYP4',
  );

  /// Ensures that critical configuration keys are present before application startup.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
