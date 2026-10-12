import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/safety/safety_boundaries.dart';
import '../../../../core/safety/widgets/clinical_disclaimer_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_button.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/app_loading_state.dart';
import '../../../../core/theme/components/app_status_chip.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../family/data/family_repository.dart';
import '../../../family/presentation/widgets/profile_switcher_pill.dart';
import '../../../measurements/domain/models/measurement.dart';
import '../../../medications/data/medication_repository.dart';
import '../../../medications/domain/models/medication.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/domain/models/health_profile.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/models/dashboard_summary.dart';

/// Width at which the dashboard switches to a two-column bento layout.
const double kDashboardWideBreakpoint = 900.0;

/// Max content width so the dashboard never stretches edge-to-edge on desktop.
const double kDashboardMaxWidth = 1120.0;

/// Icon + accent colour identity for each vital.
({IconData icon, Color color}) vitalVisual(MeasurementType type) => switch (type) {
      MeasurementType.heartRate => (icon: Icons.favorite, color: const Color(0xFFE11D48)),
      MeasurementType.bloodPressure => (icon: Icons.speed, color: const Color(0xFF4F46E5)),
      MeasurementType.weight =>
        (icon: Icons.monitor_weight_outlined, color: const Color(0xFF0D9488)),
      MeasurementType.temperature => (icon: Icons.thermostat, color: const Color(0xFFEA580C)),
      MeasurementType.bloodGlucose => (icon: Icons.water_drop, color: const Color(0xFFD97706)),
    };

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authRepositoryProvider).currentUser;
    final selfAsync = ref.watch(myProfileProvider);
    final currentAsync = ref.watch(currentProfileProvider);
    final self = selfAsync.valueOrNull;
    final current = currentAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: (self != null && current != null)
            ? Align(
                alignment: Alignment.centerLeft,
                child: ProfileSwitcherPill(selfProfile: self, currentProfile: current),
              )
            : const Text('HealthBase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user_outlined),
            tooltip: 'Clinical & Safety Policy',
            onPressed: () => showClinicalDisclaimerSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: currentAsync.when(
          loading: () => const AppLoadingState(message: 'Loading health dashboard...'),
          error: (err, _) => _DashboardError(
            message: 'We could not load your dashboard.',
            onRetry: () => ref.invalidate(currentProfileProvider),
          ),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Health profile not initialized.'));
            }

            final isSelf = self == null || profile.id == self.id;
            final name = isSelf
                ? (profile.displayName ?? authUser?.displayName ?? 'Welcome')
                : (profile.displayName ?? 'Family member');

            return _DashboardContent(
              profile: profile,
              displayName: name,
              isViewingSelf: isSelf,
              greeting: DashboardSummary.getTimeOfDayGreeting(),
              isMetric: profile.preferredUnits != UnitSystem.imperial,
            );
          },
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingAllLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.neutral400),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: AppTypography.bodyLarge),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: 'Try again', icon: Icons.refresh, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({
    required this.profile,
    required this.displayName,
    required this.isViewingSelf,
    required this.greeting,
    required this.isMetric,
  });

  final HealthProfile profile;
  final String displayName;
  final bool isViewingSelf;
  final String greeting;
  final bool isMetric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryStreamProvider(profile.id));

    return summaryAsync.when(
      loading: () => const AppLoadingState(message: 'Analyzing health records...'),
      error: (e, _) => _DashboardError(
        message: 'We could not read your health records.',
        onRetry: () => ref.invalidate(dashboardSummaryStreamProvider(profile.id)),
      ),
      data: (summary) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= kDashboardWideBreakpoint;

            final header = _Header(
              greeting: greeting,
              displayName: displayName,
              isViewingSelf: isViewingSelf,
              hasTodayCheck: summary.hasTodayCheck,
            );

            final primary = <Widget>[
              if (isViewingSelf && !profile.isOnboardingCompleted) ...[
                const _OnboardingNotice(),
                const SizedBox(height: AppSpacing.lg),
              ],
              _DailyCheckCard(summary: summary),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel(title: 'YOUR TREND'),
              const SizedBox(height: AppSpacing.sm),
              _BaselineProgressCard(summary: summary),
              const SizedBox(height: AppSpacing.lg),
              _TodayMedicationsCard(profileId: profile.id),
            ];

            final secondary = <Widget>[
              const _SectionLabel(
                title: 'YOUR HEALTH TODAY',
                subtitle: 'Tap a vital to view its trend, or tap + to log a reading.',
              ),
              const SizedBox(height: AppSpacing.md),
              _VitalsGrid(summary: summary, isMetric: isMetric),
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel(title: 'QUICK ACTIONS'),
              const SizedBox(height: AppSpacing.md),
              const _ShortcutGrid(),
            ];

            final body = isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: secondary,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...primary,
                      const SizedBox(height: AppSpacing.xl),
                      ...secondary,
                    ],
                  );

            return ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                // Clear the floating "Log" button on phones.
                isWide ? AppSpacing.xl : 96,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: kDashboardMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        const SizedBox(height: AppSpacing.lg),
                        body,
                        const SizedBox(height: AppSpacing.xl),
                        const _DisclaimerFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Header & notices
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.displayName,
    required this.isViewingSelf,
    required this.hasTodayCheck,
  });

  final String greeting;
  final String displayName;
  final bool isViewingSelf;
  final bool hasTodayCheck;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isViewingSelf ? '$greeting, $displayName' : "$displayName's health",
          style: AppTypography.headlineLarge.copyWith(
            color: isDark ? AppColors.neutral50 : AppColors.neutral900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              isViewingSelf ? 'How am I doing?' : 'Viewing a family profile',
              style: AppTypography.titleMedium.copyWith(
                color: isViewingSelf ? AppColors.primary600 : AppColors.statusSyncing,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasTodayCheck)
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
      ],
    );
  }
}

class _OnboardingNotice extends StatelessWidget {
  const _OnboardingNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
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
            onPressed: () => context.push(AppRoutes.onboarding),
            child: const Text('Setup'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.neutral300 : AppColors.neutral600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Daily check, baseline progress, medications
// ---------------------------------------------------------------------------

class _DailyCheckCard extends StatelessWidget {
  const _DailyCheckCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final check = summary.todayDailyCheck;
    final isDone = check != null;

    return AppCard(
      title: "Today's Health Check",
      subtitle: isDone
          ? 'Feeling: ${check.feeling.displayName} • Medications: ${check.medicationStatus.displayName}'
          : 'A 60-second guided wellness check-in',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isDone
                ? (check.symptoms.isNotEmpty
                    ? 'Symptoms: ${check.symptoms.map((s) => s.displayName).join(", ")}'
                    : 'No symptoms reported today.')
                : 'Track how you feel, your medications and any symptoms to build your personal history.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: isDone ? "Review Today's Check" : "Start Today's Check",
            variant: isDone ? AppButtonVariant.secondary : AppButtonVariant.primary,
            icon: isDone ? Icons.check : Icons.fact_check_outlined,
            onPressed: () => context.push(AppRoutes.dailyCheck),
          ),
        ],
      ),
    );
  }
}

class _BaselineProgressCard extends StatelessWidget {
  const _BaselineProgressCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    // Focus on the vital closest to unlocking; default to heart rate.
    final candidates = summary.metrics.values.toList()
      ..sort((a, b) => b.effectiveReadingCount.compareTo(a.effectiveReadingCount));
    final focus = candidates.isNotEmpty && candidates.first.effectiveReadingCount > 0
        ? candidates.first
        : summary.heartRate;
    final count = focus.effectiveReadingCount.clamp(0, kBaselineUnlockReadings);
    final remaining = kBaselineUnlockReadings - count;
    final visual = vitalVisual(focus.type);

    return AppCard(
      title: 'Current Baseline Directions',
      subtitle: count == 0
          ? 'HealthBase compares each reading to your own normal, not a population average.'
          : remaining > 0
              ? 'Log $remaining more ${focus.type.displayName.toLowerCase()} '
                  'reading${remaining == 1 ? '' : 's'} to unlock your personal baseline.'
              : 'Your personal baseline is active and tracking changes over time.',
      trailing: TextButton(
        onPressed: () => context.push(AppRoutes.baseline),
        child: const Text('Baselines'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(visual.icon, color: visual.color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(focus.type.displayName, style: AppTypography.titleSmall),
              const Spacer(),
              Text('$count / $kBaselineUnlockReadings readings',
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: count / kBaselineUnlockReadings,
              minHeight: 8,
              color: visual.color,
              backgroundColor: visual.color.withAlpha(30),
            ),
          ),
          if (remaining > 0) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: count == 0 ? 'Log your first reading' : 'Log ${focus.type.displayName}',
              icon: Icons.add,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.push(
                '${AppRoutes.addMeasurement}?type=${focus.type.name}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayMedicationsCard extends ConsumerWidget {
  const _TodayMedicationsCard({required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(activeMedicationsStreamProvider(profileId));

    return medsAsync.maybeWhen(
      data: (meds) {
        final now = DateTime.now();
        final active = meds.where((m) => m.isCurrentlyActive(now)).toList()
          ..sort((a, b) => (a.reminderTime ?? '99:99').compareTo(b.reminderTime ?? '99:99'));

        return AppCard(
          title: 'Medications',
          subtitle: active.isEmpty
              ? 'No active medications'
              : '${active.length} active · as entered from your prescriber',
          trailing: TextButton(
            onPressed: () => context.go(AppRoutes.medications),
            child: const Text('View all'),
          ),
          child: active.isEmpty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push(AppRoutes.addMedication),
                    icon: const Icon(Icons.add),
                    label: const Text('Add a medication'),
                  ),
                )
              : Column(
                  children: [
                    for (final med in active.take(3)) _MedicationRow(medication: med),
                    if (active.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          '+${active.length - 3} more',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500),
                        ),
                      ),
                  ],
                ),
        );
      },
      // Medications are supplementary on the dashboard; never block it.
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _MedicationRow extends StatelessWidget {
  const _MedicationRow({required this.medication});

  final Medication medication;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0x1F8B5CF6),
            child: Icon(Icons.medication_outlined, size: 18, color: AppColors.statusSyncing),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medication.name,
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  medication.dosage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500),
                ),
              ],
            ),
          ),
          Text(
            medication.reminderTime ?? medication.frequency.displayName,
            style: AppTypography.labelMedium.copyWith(color: AppColors.neutral600),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vitals
// ---------------------------------------------------------------------------

class _VitalsGrid extends StatelessWidget {
  const _VitalsGrid({required this.summary, required this.isMetric});

  final DashboardSummary summary;
  final bool isMetric;

  @override
  Widget build(BuildContext context) {
    final glucose = summary.bloodGlucose.latest?.glucoseMmolL;
    final weight = summary.weight.latest?.weightKg;
    final temp = summary.temperature.latest?.temperatureCelsius;
    final bp = summary.bloodPressure.latest;

    final cards = <Widget>[
      _VitalCard(
        title: 'Heart rate',
        state: summary.heartRate,
        valueText: summary.heartRate.latest?.heartRateBpm?.toInt().toString() ?? '--',
        unitText: 'BPM',
      ),
      _VitalCard(
        title: 'Blood pressure',
        state: summary.bloodPressure,
        valueText: (bp?.systolicMmhg != null && bp?.diastolicMmhg != null)
            ? '${bp!.systolicMmhg!.toInt()}/${bp.diastolicMmhg!.toInt()}'
            : '--',
        unitText: 'mmHg',
      ),
      _VitalCard(
        title: 'Weight',
        state: summary.weight,
        valueText: weight == null
            ? '--'
            : (isMetric ? weight : UnitConverter.kgToLbs(weight)).toStringAsFixed(1),
        unitText: isMetric ? 'kg' : 'lbs',
      ),
      _VitalCard(
        title: 'Temperature',
        state: summary.temperature,
        valueText: temp == null
            ? '--'
            : (isMetric ? temp : UnitConverter.celsiusToFahrenheit(temp)).toStringAsFixed(1),
        unitText: isMetric ? '°C' : '°F',
      ),
      _VitalCard(
        title: 'Blood glucose',
        state: summary.bloodGlucose,
        valueText: glucose == null
            ? '--'
            : (isMetric ? glucose : glucose * 18.0182).toStringAsFixed(isMetric ? 1 : 0),
        unitText: isMetric ? 'mmol/L' : 'mg/dL',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        final gap = AppSpacing.md;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final c in cards) SizedBox(width: width, child: c)],
        );
      },
    );
  }
}

class _VitalCard extends StatelessWidget {
  const _VitalCard({
    required this.title,
    required this.state,
    required this.valueText,
    required this.unitText,
  });

  final String title;
  final MetricLatestState state;
  final String valueText;
  final String unitText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = vitalVisual(state.type);
    final hasData = state.hasReading;
    final addRoute = '${AppRoutes.addMeasurement}?type=${state.type.name}';

    return Semantics(
      button: true,
      label: hasData
          ? '$title $valueText $unitText. Open trend.'
          : '$title, no readings yet. Record a reading.',
      child: Material(
        color: isDark ? AppColors.neutral800 : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: BorderSide(color: isDark ? AppColors.neutral700 : AppColors.neutral200),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => hasData
              ? context.go('${AppRoutes.trends}?metric=${state.type.name}')
              : context.push(addRoute),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: visual.color, width: 4)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(visual.icon, size: 18, color: visual.color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 20,
                      tooltip: 'Record $title',
                      icon: Icon(Icons.add_circle_outline, color: visual.color),
                      onPressed: () => context.push(addRoute),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
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
                        Text(unitText, style: AppTypography.metricUnit),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasData ? _formatRecordedAt(state.latest!.recordedAt) : 'No readings yet',
                  style: AppTypography.bodySmall.copyWith(
                    color: hasData ? AppColors.neutral500 : AppColors.neutral400,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (hasData &&
                    !state.isBaselineUnlocked &&
                    state.trend == HealthTrendStatus.insufficientData) ...[
                  _MiniProgress(count: state.effectiveReadingCount, color: visual.color),
                  const SizedBox(height: 6),
                ],
                AppStatusChip.trend(state.trend),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniProgress extends StatelessWidget {
  const _MiniProgress({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = count.clamp(0, kBaselineUnlockReadings);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$clamped/$kBaselineUnlockReadings to baseline',
            style: AppTypography.caption.copyWith(color: AppColors.neutral500),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clamped / kBaselineUnlockReadings,
              minHeight: 4,
              color: color,
              backgroundColor: color.withAlpha(30),
            ),
          ),
        ],
      ),
    );
  }
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

// ---------------------------------------------------------------------------
// Shortcuts & footer
// ---------------------------------------------------------------------------

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid();

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label, String route})>[
      (icon: Icons.fact_check_outlined, label: "Today's Check", route: AppRoutes.dailyCheck),
      (icon: Icons.add_chart, label: 'Record Vital', route: AppRoutes.addMeasurement),
      (icon: Icons.list_alt_outlined, label: 'View History', route: AppRoutes.measurements),
      (icon: Icons.show_chart, label: 'View Trends', route: AppRoutes.trends),
      (icon: Icons.compare_arrows_outlined, label: 'What Changed?', route: AppRoutes.whatChanged),
      (icon: Icons.analytics_outlined, label: 'Personal Baseline', route: AppRoutes.baseline),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        final gap = AppSpacing.md;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
                  ),
                  onPressed: () => context.push(item.route),
                  icon: Icon(item.icon, size: 20),
                  label: Text(item.label, overflow: TextOverflow.ellipsis),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DisclaimerFooter extends StatelessWidget {
  const _DisclaimerFooter();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral800 : AppColors.neutral100,
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.neutral600),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SafetyBoundaries.generalDisclaimer,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  SafetyBoundaries.baselineExplanation,
                  style: AppTypography.caption.copyWith(color: AppColors.neutral500),
                ),
                const SizedBox(height: 6.0),
                InkWell(
                  onTap: () => showClinicalDisclaimerSheet(context),
                  child: Text(
                    'View Clinical Guidelines & Safety Policy →',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
