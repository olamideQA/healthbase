import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_card.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/trends/domain/models/trend_chart_data.dart';

class TrendInsufficientView extends StatelessWidget {
  const TrendInsufficientView({
    super.key,
    required this.type,
    required this.period,
  });

  final MeasurementType type;
  final TrendPeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.show_chart,
                size: 36.0,
                color: AppColors.neutral400,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'More data needed',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'No ${type.displayName.toLowerCase()} readings logged in ${period.displayName.toLowerCase()}. Log readings to visualize your longitudinal trends.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.neutral500,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.addMeasurement),
              icon: const Icon(Icons.add, size: 16.0),
              label: const Text('Record Reading'),
            ),
          ],
        ),
      ),
    );
  }
}
