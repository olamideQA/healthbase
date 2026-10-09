import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/baseline/presentation/screens/personal_baseline_screen.dart';
import '../../features/daily_check/presentation/screens/daily_check_screen.dart';
import '../../features/measurements/presentation/screens/add_measurement_screen.dart';
import '../../features/measurements/presentation/screens/measurements_history_screen.dart';
import '../../features/timeline/presentation/screens/timeline_screen.dart';
import '../../features/insights/presentation/screens/what_changed_screen.dart';
import '../../features/trends/presentation/screens/trends_screen.dart';
import '../../features/medications/presentation/screens/medications_screen.dart';
import '../../features/medications/presentation/screens/add_medication_screen.dart';
import '../theme/design_system_gallery.dart';

class AppRoutes {
  const AppRoutes._();

  static const String root = '/';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String dashboard = '/dashboard';
  static const String onboarding = '/onboarding';
  static const String profile = '/profile';
  static const String baseline = '/baseline';
  static const String timeline = '/timeline';
  static const String measurements = '/measurements';
  static const String addMeasurement = '/measurements/add';
  static const String dailyCheck = '/daily-check';
  static const String trends = '/trends';
  static const String whatChanged = '/what-changed';
  static const String medications = '/medications';
  static const String addMedication = '/medications/add';
  static const String designSystem = '/design-system';
}

/// Create configured GoRouter with authentication and onboarding guards.
GoRouter createAppRouter({
  required AuthRepository authRepository,
  bool? Function()? isOnboardingCompleted,
}) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.root,
        redirect: (context, state) => AppRoutes.dashboard,
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.baseline,
        builder: (context, state) => const PersonalBaselineScreen(),
      ),
      GoRoute(
        path: AppRoutes.timeline,
        builder: (context, state) => const TimelineScreen(),
      ),
      GoRoute(
        path: AppRoutes.measurements,
        builder: (context, state) => const MeasurementsHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.addMeasurement,
        builder: (context, state) => const AddMeasurementScreen(),
      ),
      GoRoute(
        path: AppRoutes.dailyCheck,
        builder: (context, state) => const DailyCheckScreen(),
      ),
      GoRoute(
        path: AppRoutes.trends,
        builder: (context, state) => const TrendsScreen(),
      ),
      GoRoute(
        path: AppRoutes.whatChanged,
        builder: (context, state) => const WhatChangedScreen(),
      ),
      GoRoute(
        path: AppRoutes.medications,
        builder: (context, state) => const MedicationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.addMedication,
        builder: (context, state) => const AddMedicationScreen(),
      ),
      GoRoute(
        path: AppRoutes.designSystem,
        builder: (context, state) => const DesignSystemGalleryScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authRepository.currentUser != null;
      final location = state.uri.path;
      final isAuthRoute = location.startsWith('/auth');
      final isDevRoute = location.startsWith('/design-system');

      if (!isAuthenticated && !isAuthRoute && !isDevRoute) {
        return AppRoutes.login;
      }

      if (isAuthenticated) {
        final completed = isOnboardingCompleted?.call();

        if (location == AppRoutes.login || location == AppRoutes.register) {
          if (completed == false) {
            return AppRoutes.onboarding;
          }
          return AppRoutes.dashboard;
        }

        if (completed == false &&
            location != AppRoutes.onboarding &&
            !isDevRoute) {
          return AppRoutes.onboarding;
        }

        if (completed == true && location == AppRoutes.onboarding) {
          return AppRoutes.dashboard;
        }
      }

      return null;
    },
  );
}
