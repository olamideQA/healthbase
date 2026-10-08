import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/routing/app_router.dart';
import 'core/security/security_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/profile/data/profile_repository.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return createAppRouter(
    authRepository: authRepo,
    isOnboardingCompleted: () => ref.read(myProfileProvider).value?.isOnboardingCompleted,
  );
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase client with production config
  if (AppConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
        debug: kDebugMode,
      );
      AppLogger.info('Supabase initialized successfully.');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize Supabase', e, stack);
    }
  } else {
    AppLogger.warning('Supabase configuration missing.');
  }

  runApp(
    const ProviderScope(
      child: HealthBaseApp(),
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
