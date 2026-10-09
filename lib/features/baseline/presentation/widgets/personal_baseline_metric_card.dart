import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../measurements/domain/models/measurement.dart';
import '../../../profile/domain/models/health_profile.dart';
import '../../domain/models/personal_baseline.dart';

class PersonalBaselineMetricCard extends StatelessWidget {
  const PersonalBaselineMetricCard({
    super.key,
    required this.baseline,
    required this.unitSystem,
  });

  final MetricBaseline baseline;
  final UnitSystem unitSystem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Metric Name + Trend Chip
          Row(
            children: [
              _buildMetricIcon(baseline.type),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  baseline.type.displayName,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (baseline.hasSufficientData)
                _buildTrendChip(baseline.recentTrend, isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          // Content: Established Range or Cold Start State
          if (baseline.hasSufficientData) ...[
            _buildEstablishedContent(context, isDark),
          ] else ...[
            _buildInsufficientContent(context, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildEstablishedContent(BuildContext context, bool isDark) {
    final rangeText = baseline.formatPersonalRange(unitSystem);
    final primary = baseline.primaryStats!;
    final secondary = baseline.secondaryStats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT PERSONAL RANGE',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.neutral500,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          rangeText,
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.neutral50 : AppColors.neutral900,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Statistics row
        Container(
          padding: AppSpacing.paddingAllMd,
          decoration: BoxDecoration(
            color: isDark ? AppColors.neutral900 : AppColors.neutral50,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color: isDark ? AppColors.neutral800 : AppColors.neutral200,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                label: 'Median',
                value: baseline.type == MeasurementType.bloodPressure && secondary != null
                    ? '${primary.formatMedian()}/${secondary.formatMedian()}'
                    : primary.formatMedian(decimals: _decimalsForType(baseline.type)),
                isDark: isDark,
              ),
              Container(width: 1, height: 28, color: AppColors.neutral300),
              _buildStatColumn(
                label: 'Average',
                value: baseline.type == MeasurementType.bloodPressure && secondary != null
                    ? '${primary.formatAverage(decimals: 0)}/${secondary.formatAverage(decimals: 0)}'
                    : primary.formatAverage(decimals: 1),
                isDark: isDark,
              ),
              Container(width: 1, height: 28, color: AppColors.neutral300),
              _buildStatColumn(
                label: 'Readings',
                value: '${primary.measurementCount}',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsufficientContent(BuildContext context, bool isDark) {
    final detailText = baseline.statusMessage == 'Not enough history yet'
        ? 'Need at least ${baseline.window.minEntries} readings in ${baseline.window.displayName.toLowerCase()} to establish a personal range.'
        : baseline.statusMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.pending_outlined,
              size: 20.0,
              color: AppColors.neutral400,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Not enough history yet',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.neutral200 : AppColors.neutral800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          detailText,
          style: const TextStyle(fontSize: 12.0, color: AppColors.neutral500),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.addMeasurement),
          icon: const Icon(Icons.add, size: 16.0),
          label: const Text('Record Reading'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.0,
            color: AppColors.neutral500,
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.neutral100 : AppColors.neutral900,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChip(RecentTrend trend, bool isDark) {
    final (color, icon) = switch (trend) {
      RecentTrend.stable => (AppColors.statusStable, Icons.horizontal_rule),
      RecentTrend.increased ||
      RecentTrend.higherThanBaseline =>
        (AppColors.statusIncreased, Icons.arrow_upward),
      RecentTrend.decreased ||
      RecentTrend.lowerThanBaseline =>
        (AppColors.statusDecreased, Icons.arrow_downward),
      RecentTrend.insufficientData => (AppColors.neutral400, Icons.help_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.0, color: color),
          const SizedBox(width: 4.0),
          Text(
            trend.displayName,
            style: TextStyle(
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricIcon(MeasurementType type) {
    final iconData = switch (type) {
      MeasurementType.heartRate => Icons.favorite,
      MeasurementType.bloodPressure => Icons.speed,
      MeasurementType.temperature => Icons.thermostat,
      MeasurementType.weight => Icons.monitor_weight,
      MeasurementType.bloodGlucose => Icons.water_drop,
    };

    final color = switch (type) {
      MeasurementType.heartRate => AppColors.statusUrgent,
      MeasurementType.bloodPressure => AppColors.primary500,
      MeasurementType.temperature => AppColors.statusIncreased,
      MeasurementType.weight => AppColors.secondary500,
      MeasurementType.bloodGlucose => AppColors.statusDecreased,
    };

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20.0),
    );
  }

  int _decimalsForType(MeasurementType type) {
    return switch (type) {
      MeasurementType.heartRate => 0,
      MeasurementType.bloodPressure => 0,
      MeasurementType.temperature => 1,
      MeasurementType.weight => 1,
      MeasurementType.bloodGlucose => 1,
    };
  }
}
