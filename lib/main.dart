import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/db/app_database.dart';
import 'core/db/encrypted_database.dart';
import 'core/routing/app_router.dart';
import 'core/security/secure_session_storage.dart';
import 'core/security/security_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/profile/data/profile_repository.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final router = createAppRouter(
    authRepository: authRepo,
    isOnboardingCompleted: () => ref.read(myProfileProvider).value?.isOnboardingCompleted,
  );
  // Password-reset links open the app via the auth-callback scheme: when
  // Supabase reports a recovery session, land on the reset screen.
  // Guarded for tests, where Supabase is never initialized.
  try {
    final sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        router.go(AppRoutes.resetPassword);
      }
    });
    ref.onDispose(sub.cancel);
  } catch (_) {
    // No Supabase in widget tests — routing still works.
  }
  return router;
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the encrypted local database before anything can use it.
  final security = SecurityService();
  final db = await openEncryptedAppDatabase(security);

  // Initialize Supabase client with production config. Sessions persist
  // in secure storage (never plaintext); auth debug logging stays off so
  // tokens cannot leak into device logs.
  if (AppConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
        debug: false,
        authOptions: FlutterAuthClientOptions(
          localStorage: SecureSessionStorage(security),
        ),
      );
      AppLogger.info('Supabase initialized successfully.');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize Supabase', e, stack);
    }
  } else {
    AppLogger.warning('Supabase configuration missing.');
  }

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        securityServiceProvider.overrideWithValue(security),
      ],
      child: const HealthBaseApp(),
    ),
  );
}

/// Root widget for HealthBase.
class HealthBaseApp extends ConsumerWidget {
  const HealthBaseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
