import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/safety/safety_boundaries.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/app_loading_state.dart';
import '../../../measurements/domain/models/measurement.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/trends_repository.dart';
import '../../domain/models/trend_chart_data.dart';
import '../widgets/metric_chart_view.dart';
import '../widgets/trend_insufficient_view.dart';

final selectedTrendMetricProvider =
    StateProvider.autoDispose<MeasurementType>((ref) => MeasurementType.heartRate);

final selectedTrendPeriodProvider =
    StateProvider.autoDispose<TrendPeriod>((ref) => TrendPeriod.days30);

class TrendsScreen extends ConsumerWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final selectedMetric = ref.watch(selectedTrendMetricProvider);
    final selectedPeriod = ref.watch(selectedTrendPeriodProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends & Charts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View timeline history',
            onPressed: () => context.push(AppRoutes.timeline),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'View personal baseline',
            onPressed: () => context.push(AppRoutes.baseline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addMeasurement),
        icon: const Icon(Icons.add),
        label: const Text('Record Vital'),
        backgroundColor: AppColors.primary500,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () =>
              const AppLoadingState(message: 'Loading trend history...'),
          error: (err, _) => Center(child: Text('Error loading profile: $err')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profile not found.'));
            }

            final seriesAsync = ref.watch(
              trendSeriesStreamProvider((
                profileId: profile.id,
                type: selectedMetric,
                period: selectedPeriod,
                unitSystem: profile.preferredUnits,
              )),
            );

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(trendSeriesStreamProvider);
              },
              child: ListView(
                padding: AppSpacing.paddingAllLg,
                children: [
                  // 1. Metric Selector Horizontal Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: MeasurementType.values.map((type) {
                        final isSelected = type == selectedMetric;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(type.displayName),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                ref.read(selectedTrendMetricProvider.notifier).state = type;
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 2. Period Selector Segmented Buttons
                  Center(
                    child: SegmentedButton<TrendPeriod>(
                      segments: TrendPeriod.values.map((p) {
                        return ButtonSegment<TrendPeriod>(
                          value: p,
                          label: Text(p.displayName),
                        );
                      }).toList(),
                      selected: {selectedPeriod},
                      onSelectionChanged: (newSelection) {
                        ref.read(selectedTrendPeriodProvider.notifier).state =
                            newSelection.first;
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 3. Clinical Disclaimer Banner
                  Container(
                    padding: AppSpacing.paddingAllMd,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(
                        color: isDark ? AppColors.neutral700 : AppColors.neutral200,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.insights_outlined,
                          size: 18,
                          color: AppColors.primary600,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            SafetyBoundaries.baselineExplanation,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 4. Chart or Insufficient Data View
                  seriesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => Center(child: Text('Error: $err')),
                    data: (series) {
                      if (!series.hasData) {
                        return TrendInsufficientView(
                          type: selectedMetric,
                          period: selectedPeriod,
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${selectedMetric.displayName} Trend',
                                      style: AppTypography.titleMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${series.count} readings',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.neutral500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                MetricChartView(series: series),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Statistical Summary Block
                          _buildSummaryStats(series, isDark),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 80.0), // Padding for FAB
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryStats(MetricTrendSeries series, bool isDark) {
    final isBp = series.type == MeasurementType.bloodPressure;

    String formatVal(double? primary, double? secondary) {
      if (primary == null) return '--';
      if (isBp && secondary != null) {
        return '${primary.round()}/${secondary.round()} ${series.unit}';
      }
      final decimals = series.type == MeasurementType.heartRate ? 0 : 1;
      return decimals == 0
          ? '${primary.round()} ${series.unit}'
          : '${primary.toStringAsFixed(decimals)} ${series.unit}';
    }

    return AppCard(
      title: 'Period Summary',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCol('Average', formatVal(series.average, series.secondaryAverage), isDark),
          Container(width: 1, height: 32, color: AppColors.neutral300),
          _buildStatCol('Median', formatVal(series.median, series.secondaryMedian), isDark),
          Container(width: 1, height: 32, color: AppColors.neutral300),
          _buildStatCol('Readings', '${series.count}', isDark),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.neutral100 : AppColors.neutral900,
          ),
        ),
      ],
    );
  }
}
