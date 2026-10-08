import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/safety/safety_boundaries.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_button.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/app_loading_state.dart';
import '../../../../core/theme/components/app_status_chip.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/domain/models/health_profile.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/models/dashboard_summary.dart';

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
          loading: () => const AppLoadingState(message: 'Loading health dashboard...'),
          error: (err, _) => Center(
            child: Text('Error loading dashboard: $err'),
          ),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Health profile not initialized.'));
            }

            final name = profile.displayName ?? authUser?.displayName ?? 'Welcome';
            final greeting = DashboardSummary.getTimeOfDayGreeting();
            final isMetric = profile.preferredUnits != UnitSystem.imperial;

            return _DashboardContent(
              profile: profile,
              displayName: name,
              greeting: greeting,
              isMetric: isMetric,
              isDark: isDark,
            );
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({
    required this.profile,
    required this.displayName,
    required this.greeting,
    required this.isMetric,
    required this.isDark,
  });

  final HealthProfile profile;
  final String displayName;
  final String greeting;
  final bool isMetric;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryStreamProvider(profile.id));

    return summaryAsync.when(
      loading: () => const AppLoadingState(message: 'Analyzing health records...'),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (summary) {
        return ListView(
          padding: AppSpacing.paddingAllLg,
          children: [
            // 1. Time-of-day Header & "How am I doing?"
            Text(
              '$greeting, $displayName',
              style: isDark
                  ? AppTypography.headlineLarge.copyWith(color: AppColors.neutral50)
                  : AppTypography.headlineLarge.copyWith(color: AppColors.neutral900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text(
                  'How am I doing?',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (summary.hasTodayCheck)
                  const AppStatusChip(
                    label: "Today's check complete",
                    backgroundColor: Color(0xFFE8F5E9),
                    textColor: Color(0xFF2E7D32),
                    icon: Icons.check_circle_outline,
                  )
                else
                  const AppStatusChip(
                    label: 'Check-in pending',
                    backgroundColor: Color(0xFFFEF3C7),
                    textColor: Color(0xFFB45309),
                    icon: Icons.schedule,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Onboarding notice if not complete
            if (!profile.isOnboardingCompleted) ...[
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
                        'Complete your onboarding to configure your preferred units and baseline.',
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

            // 2. Daily Health Check Card
            _buildDailyCheckSection(context, summary),
            const SizedBox(height: AppSpacing.xl),

            // 3. YOUR HEALTH TODAY (Most recent measurements)
            Text(
              'YOUR HEALTH TODAY',
              style: AppTypography.titleSmall.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.neutral300 : AppColors.neutral600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildHealthTodayGrid(context, summary),
            const SizedBox(height: AppSpacing.xl),

            // 4. YOUR TREND (Non-judgmental statistical indicators)
            Text(
              'YOUR TREND',
              style: AppTypography.titleSmall.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.neutral300 : AppColors.neutral600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Non-diagnostic statistical directions compared to your recent history.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTrendsSection(context, summary),
            const SizedBox(height: AppSpacing.xl),

            // 5. QUICK ACTIONS PANEL
            Text(
              'QUICK ACTIONS',
              style: AppTypography.titleSmall.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.neutral300 : AppColors.neutral600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildQuickActions(context, summary),
            const SizedBox(height: AppSpacing.xl),

            // 6. Clinical Baseline Explanation Disclaimer
            Container(
              padding: AppSpacing.paddingAllMd,
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: AppSpacing.roundedSm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.neutral600),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      SafetyBoundaries.baselineExplanation,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.neutral600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 7. Danger Zone: Account Deletion (Compliance)
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
    );
  }

  Widget _buildDailyCheckSection(BuildContext context, DashboardSummary summary) {
    final check = summary.todayDailyCheck;
    final isDone = check != null;

    return AppCard(
      title: "Today's Health Check",
      subtitle: isDone
          ? 'Feeling: ${check.feeling.displayName} • Medications: ${check.medicationStatus.displayName}'
          : 'Complete your 60-second guided wellness check-in',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDone) ...[
            Text(
              check.symptoms.isNotEmpty
                  ? 'Symptoms: ${check.symptoms.map((s) => s.displayName).join(", ")}'
                  : 'No symptoms reported today.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: "Review Today's Check",
              variant: AppButtonVariant.secondary,
              icon: Icons.check,
              onPressed: () => context.push('/daily-check'),
            ),
          ] else ...[
            const Text(
              'Track how you feel, your required heart rate, and any daily symptoms to establish your longitudinal baseline.',
              style: TextStyle(fontSize: 13.0, color: AppColors.neutral600),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: "Start Today's Check",
              icon: Icons.fact_check_outlined,
              onPressed: () => context.push('/daily-check'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthTodayGrid(BuildContext context, DashboardSummary summary) {
    return Column(
      children: [
        // Heart Rate & Blood Pressure
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Heart rate',
                state: summary.heartRate,
                valueText: summary.heartRate.latest?.heartRateBpm != null
                    ? '${summary.heartRate.latest!.heartRateBpm!.toInt()}'
                    : '--',
                unitText: 'BPM',
                onTap: () => context.push('/measurements/add'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetricTile(
                title: 'Blood pressure',
                state: summary.bloodPressure,
                valueText: summary.bloodPressure.latest?.systolicMmhg != null
                    ? '${summary.bloodPressure.latest!.systolicMmhg!.toInt()}/${summary.bloodPressure.latest!.diastolicMmhg!.toInt()}'
                    : '--',
                unitText: 'mmHg',
                onTap: () => context.push('/measurements/add'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Weight & Temperature
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Weight',
                state: summary.weight,
                valueText: summary.weight.latest?.weightKg != null
                    ? (isMetric
                        ? summary.weight.latest!.weightKg!.toStringAsFixed(1)
                        : UnitConverter.kgToLbs(summary.weight.latest!.weightKg!)
                            .toStringAsFixed(1))
                    : '--',
                unitText: isMetric ? 'kg' : 'lbs',
                onTap: () => context.push('/measurements/add'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetricTile(
                title: 'Temperature',
                state: summary.temperature,
                valueText: summary.temperature.latest?.temperatureCelsius != null
                    ? (isMetric
                        ? summary.temperature.latest!.temperatureCelsius!.toStringAsFixed(1)
                        : UnitConverter.celsiusToFahrenheit(
                                summary.temperature.latest!.temperatureCelsius!)
                            .toStringAsFixed(1))
                    : '--',
                unitText: isMetric ? '°C' : '°F',
                onTap: () => context.push('/measurements/add'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Blood Glucose
        _buildMetricTile(
          title: 'Blood glucose',
          state: summary.bloodGlucose,
          valueText: summary.bloodGlucose.latest?.glucoseMmolL != null
              ? (isMetric
                  ? summary.bloodGlucose.latest!.glucoseMmolL!.toStringAsFixed(1)
                  : (summary.bloodGlucose.latest!.glucoseMmolL! * 18.0182)
                      .toStringAsFixed(1))
              : '--',
          unitText: isMetric ? 'mmol/L' : 'mg/dL',
          onTap: () => context.push('/measurements/add'),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required MetricLatestState state,
    required String valueText,
    required String unitText,
    required VoidCallback onTap,
  }) {
    final hasData = state.hasReading;

    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral800 : AppColors.neutral50,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: isDark ? AppColors.neutral700 : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                ),
              ),
              if (!hasData)
                InkWell(
                  onTap: onTap,
                  child: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary600),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                valueText,
                style: AppTypography.metricLarge.copyWith(
                  color: hasData
                      ? (isDark ? AppColors.neutral50 : AppColors.neutral900)
                      : AppColors.neutral400,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                unitText,
                style: AppTypography.metricUnit,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (hasData)
            Text(
              _formatRecordedAt(state.latest!.recordedAt),
              style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500),
            )
          else
            Text(
              'No readings yet',
              style: AppTypography.bodySmall.copyWith(color: AppColors.neutral400),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendsSection(BuildContext context, DashboardSummary summary) {
    return AppCard(
      title: 'Current Baseline Directions',
      child: Column(
        children: [
          _buildTrendRow('Heart rate', summary.heartRate),
          const Divider(height: AppSpacing.md),
          _buildTrendRow('Blood pressure', summary.bloodPressure),
          const Divider(height: AppSpacing.md),
          _buildTrendRow('Weight', summary.weight),
          const Divider(height: AppSpacing.md),
          _buildTrendRow('Temperature', summary.temperature),
          const Divider(height: AppSpacing.md),
          _buildTrendRow('Blood glucose', summary.bloodGlucose),
        ],
      ),
    );
  }

  Widget _buildTrendRow(String title, MetricLatestState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
          ),
          AppStatusChip.trend(state.trend),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, DashboardSummary summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: summary.hasTodayCheck ? "Today's Check" : "Start Today's Check",
                icon: Icons.fact_check_outlined,
                onPressed: () => context.push('/daily-check'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: 'Record Vital',
                variant: AppButtonVariant.secondary,
                icon: Icons.add,
                onPressed: () => context.push('/measurements/add'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'View History',
                variant: AppButtonVariant.outline,
                icon: Icons.history,
                onPressed: () => context.push('/measurements'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: 'View Trends',
                variant: AppButtonVariant.outline,
                icon: Icons.insights_outlined,
                onPressed: () => context.push('/trends'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'What Changed?',
          variant: AppButtonVariant.outline,
          icon: Icons.compare_arrows_outlined,
          onPressed: () => context.push('/what-changed'),
        ),
      ],
    );
  }

  String _formatRecordedAt(DateTime recordedAt) {
    final now = DateTime.now();
    final diff = now.difference(recordedAt);

    if (diff.inMinutes < 60) {
      return diff.inMinutes <= 1 ? 'Just now' : '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24 && now.day == recordedAt.day) {
      final hour = recordedAt.hour.toString().padLeft(2, '0');
      final minute = recordedAt.minute.toString().padLeft(2, '0');
      return 'Today $hour:$minute';
    } else if (diff.inDays <= 1) {
      return 'Yesterday';
    } else {
      return '${recordedAt.year}-${recordedAt.month.toString().padLeft(2, '0')}-${recordedAt.day.toString().padLeft(2, '0')}';
    }
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
