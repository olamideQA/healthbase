import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_card.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import '../../domain/models/health_insight.dart';
import 'insight_evidence_sheet.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.insight,
  });

  final HealthInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Metric Icon, Name, and Direction Badge
          Row(
            children: [
              _buildMetricIcon(insight.type),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  insight.title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildDirectionChip(insight.direction),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          // 3-Part Sentence Explanation
          Text(
            insight.explanation,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.neutral200 : AppColors.neutral800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Bottom Action: View Evidence or Record Reading
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (insight.hasSufficientData) ...[
                Text(
                  'Based on ${insight.evidence.readings.length} readings',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openEvidenceSheet(context),
                  icon: const Icon(Icons.analytics_outlined, size: 16.0),
                  label: const Text('View Evidence'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Text(
                    'Need more readings to compare',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.addMeasurement),
                  icon: const Icon(Icons.add, size: 16.0),
                  label: const Text('Record Reading'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _openEvidenceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InsightEvidenceSheet(insight: insight),
    );
  }

  Widget _buildDirectionChip(InsightDirection direction) {
    final (color, icon) = switch (direction) {
      InsightDirection.higher => (AppColors.statusIncreased, Icons.arrow_upward),
      InsightDirection.lower => (AppColors.statusDecreased, Icons.arrow_downward),
      InsightDirection.withinRange => (AppColors.statusStable, Icons.check_circle_outline),
      InsightDirection.insufficientData => (AppColors.neutral400, Icons.pending_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.0, color: color),
          const SizedBox(width: 4.0),
          Text(
            direction.displayName,
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
}
