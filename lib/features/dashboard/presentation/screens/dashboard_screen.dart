import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_button.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/app_loading_state.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../daily_check/data/daily_check_repository.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/domain/models/health_profile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authRepositoryProvider).currentUser;
    final profileAsync = ref.watch(myProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthBase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Health Profile',
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.style_outlined),
            tooltip: 'Design System Gallery',
            onPressed: () => context.push('/design-system'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/auth/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const AppLoadingState(message: 'Loading health profile...'),
          error: (err, _) => Center(
            child: Text('Error loading profile: $err'),
          ),
          data: (profile) {
            final name = profile?.displayName ?? authUser?.displayName ?? 'Welcome';
            final isMetric = profile?.preferredUnits != null
                ? profile!.preferredUnits == UnitSystem.metric
                : true;

            return ListView(
              padding: AppSpacing.paddingAllLg,
              children: [
                Text(
                  'Good day, $name',
                  style: isDark
                      ? AppTypography.headlineLarge.copyWith(color: AppColors.neutral50)
                      : AppTypography.headlineLarge.copyWith(color: AppColors.neutral900),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  authUser?.email ?? '',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                ),
                const SizedBox(height: AppSpacing.xl),

                if (profile?.isOnboardingCompleted != true) ...[
                  Container(
                    padding: AppSpacing.paddingAllMd,
                    decoration: BoxDecoration(
                      color: AppColors.primary100.withAlpha(80),
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(color: AppColors.neutral300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary700),
                        const SizedBox(width: AppSpacing.md),
                        const Expanded(
                          child: Text(
                            'Complete your onboarding to configure your unit preferences and baseline.',
                            style: TextStyle(fontSize: 13.0, color: AppColors.neutral900),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/onboarding'),
                          child: const Text('Setup'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                if (profile != null) ...[
                  _DailyCheckCard(profileId: profile.id),
                  const SizedBox(height: AppSpacing.lg),
                ],

                AppCard(
                  title: 'Health Measurements',
                  subtitle: 'Record vitals locally with offline-first synchronization',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Record Vital',
                              icon: Icons.add,
                              onPressed: () => context.push('/measurements/add'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppButton(
                              label: 'View History',
                              variant: AppButtonVariant.secondary,
                              icon: Icons.history,
                              onPressed: () => context.push('/measurements'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                AppCard(
                  title: 'Health Profile Status',
                  subtitle: profile?.isSelf == true ? 'Personal Primary Profile' : 'Dependent Profile',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Units: ${profile?.preferredUnits.name.toUpperCase() ?? 'METRIC'}',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Onboarding: ${profile?.isOnboardingCompleted == true ? 'Completed' : 'Pending'}',
                        style: AppTypography.bodyMedium,
                      ),
                      if (profile != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Height: ${profile.heightCm != null ? (isMetric ? '${profile.heightCm!.toStringAsFixed(1)} cm' : '${(profile.heightCm! / 2.54).toStringAsFixed(1)} in') : 'Not set'}',
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Weight: ${profile.weightKg != null ? (isMetric ? '${profile.weightKg!.toStringAsFixed(1)} kg' : '${(profile.weightKg! * 2.20462).toStringAsFixed(1)} lbs') : 'Not set'}',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'View & Edit Profile',
                        variant: AppButtonVariant.outline,
                        onPressed: () => context.push('/profile'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Danger Zone: Account Deletion (Apple/Google Compliance)
                AppCard(
                  title: 'Account Management',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Permanently delete your HealthBase account and all stored health measurements.',
                        style: TextStyle(fontSize: 13.0, color: AppColors.neutral500),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Delete My Account',
                        variant: AppButtonVariant.outline,
                        onPressed: () => _confirmAccountDeletion(context, ref),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _confirmAccountDeletion(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action is irreversible. All your personal data and health records will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.statusUrgent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success =
                  await ref.read(authControllerProvider.notifier).deleteAccount();
              if (success && context.mounted) {
                context.go('/auth/login');
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}

class _DailyCheckCard extends ConsumerWidget {
  const _DailyCheckCard({required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkAsync = ref.watch(todayCheckStreamProvider(profileId));

    return checkAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (check) {
        final isCompleted = check != null;
        return AppCard(
          title: "Today's Health Check",
          subtitle: isCompleted
              ? 'Feeling: ${check.feeling.displayName} • Recorded'
              : 'Keep your longitudinal wellness record up to date',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFFE8F5E9) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.schedule,
                  size: 14,
                  color: isCompleted ? const Color(0xFF2E7D32) : const Color(0xFFB45309),
                ),
                const SizedBox(width: 4),
                Text(
                  isCompleted ? 'Completed' : 'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? const Color(0xFF2E7D32) : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isCompleted) ...[
                Text(
                  check.symptoms.isNotEmpty
                      ? 'Reported: ${check.symptoms.map((s) => s.displayName).join(", ")}'
                      : 'No symptoms reported today',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.neutral600),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'View Check-In Details',
                  variant: AppButtonVariant.outline,
                  icon: Icons.check,
                  onPressed: () => context.push('/daily-check'),
                ),
              ] else ...[
                const Text(
                  'Record how you feel, your required heart rate, and any daily symptoms in under 60 seconds.',
                  style: TextStyle(fontSize: 13.0, color: AppColors.neutral600),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Start Daily Check',
                  icon: Icons.fact_check_outlined,
                  onPressed: () => context.push('/daily-check'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
