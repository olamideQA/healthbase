import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/safety/safety_boundaries.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import '../../domain/models/health_insight.dart';

class InsightEvidenceSheet extends StatelessWidget {
  const InsightEvidenceSheet({
    super.key,
    required this.insight,
  });

  final HealthInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final evidence = insight.evidence;
    final dateFormat = DateFormat('MMM d, y • h:mm a');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: AppSpacing.paddingAllLg,
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${insight.title} Evidence',
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            insight.explanation,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.neutral300 : AppColors.neutral700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          // Scrollable evidence content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Comparison Table
                  Text(
                    'STATISTICAL COMPARISON',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.neutral500,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildComparisonTable(evidence, isDark),
                  const SizedBox(height: AppSpacing.lg),

                  // Traceable Underlying Measurements
                  Text(
                    'UNDERLYING MEASUREMENTS (${evidence.readings.length})',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.neutral500,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (evidence.readings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text('No measurement records logged yet.'),
                    )
                  else
                    ...evidence.readings.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                        padding: AppSpacing.paddingAllSm,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.neutral800 : AppColors.neutral50,
                          borderRadius: AppSpacing.roundedSm,
                          border: Border.all(
                            color: isDark ? AppColors.neutral700 : AppColors.neutral200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.isRecentWindow
                                    ? AppColors.primary500.withAlpha(30)
                                    : AppColors.neutral400.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.isRecentWindow ? 'Recent' : 'Baseline',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: item.isRecentWindow
                                      ? AppColors.primary600
                                      : AppColors.neutral600,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                dateFormat.format(item.recordedAt),
                                style: AppTypography.bodySmall,
                              ),
                            ),
                            Text(
                              item.formatDisplayValue(
                                decimals: insight.type == MeasurementType.heartRate ||
                                        insight.type == MeasurementType.bloodPressure
                                    ? 0
                                    : 1,
                              ),
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: AppSpacing.lg),

                  // Safety disclaimer
                  Container(
                    padding: AppSpacing.paddingAllMd,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppColors.neutral600,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            SafetyBoundaries.baselineExplanation,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.neutral600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(InsightEvidence evidence, bool isDark) {
    final decimals = insight.type == MeasurementType.heartRate ||
            insight.type == MeasurementType.bloodPressure
        ? 0
        : 1;

    String formatVal(double? primary, double? secondary) {
      if (primary == null) return '--';
      if (secondary != null) {
        return '${primary.round()}/${secondary.round()} ${evidence.unit}';
      }
      return decimals == 0
          ? '${primary.round()} ${evidence.unit}'
          : '${primary.toStringAsFixed(decimals)} ${evidence.unit}';
    }

    return Table(
      border: TableBorder.all(
        color: isDark ? AppColors.neutral700 : AppColors.neutral200,
        borderRadius: AppSpacing.roundedSm,
      ),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.0),
        2: FlexColumnWidth(1.0),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: isDark ? AppColors.neutral800 : AppColors.neutral100,
          ),
          children: const [
            Padding(
              padding: AppSpacing.paddingAllSm,
              child: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            Padding(
              padding: AppSpacing.paddingAllSm,
              child: Text('Recent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            Padding(
              padding: AppSpacing.paddingAllSm,
              child: Text('Baseline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        TableRow(
          children: [
            const Padding(
              padding: AppSpacing.paddingAllSm,
              child: Text('Count', style: TextStyle(fontSize: 12)),
            ),
            Padding(
              padding: AppSpacing.paddingAllSm,
              child: Text('${evidence.recentCount}', style: const TextStyle(fontSize: 12)),
            ),
            Padding(
              padding: AppSpacing.paddingAllSm,
              child: Text('${evidence.baselineCount}', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        TableRow(
          children: [
            const Padding(
              padding: AppSpacing.paddingAllSm,
              child: Text('Average', style: TextStyle(fontSize: 12)),
            ),
            Padding(
              padding: AppSpacing.paddingAllSm,
              child: Text(
                formatVal(evidence.recentAverage, evidence.recentSecondaryAverage),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Padding(
              padding: AppSpacing.paddingAllSm,
              child: Text(
                formatVal(evidence.baselineAverage, evidence.baselineSecondaryAverage),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            const Padding(
              padding: AppSpacing.paddingAllSm,
              child: Text('Median', style: TextStyle(fontSize: 12)),
            ),
            Padding(
              padding: AppSpacing.paddingAllSm,
              child: Text(
                formatVal(evidence.recentMedian, evidence.recentSecondaryMedian),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Padding(
              padding: AppSpacing.paddingAllSm,
              child: Text(
                formatVal(evidence.baselineMedian, evidence.baselineSecondaryMedian),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
