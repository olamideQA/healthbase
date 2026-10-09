import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/trends/domain/models/trend_chart_data.dart';

class MetricChartView extends StatefulWidget {
  const MetricChartView({
    super.key,
    required this.series,
    this.onPointSelected,
  });

  final MetricTrendSeries series;
  final ValueChanged<ChartDataPoint?>? onPointSelected;

  @override
  State<MetricChartView> createState() => _MetricChartViewState();
}

class _MetricChartViewState extends State<MetricChartView> {
  ChartDataPoint? _selectedPoint;

  @override
  void didUpdateWidget(MetricChartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series != widget.series) {
      _selectedPoint = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final series = widget.series;
    final points = series.points;

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final isBp = series.type == MeasurementType.bloodPressure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend for Blood Pressure
        if (isBp) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildLegendItem('Systolic', AppColors.primary500),
                const SizedBox(width: AppSpacing.md),
                _buildLegendItem('Diastolic', AppColors.secondary500),
              ],
            ),
          ),
        ],

        // Chart Container
        SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              minY: series.minY,
              maxY: series.maxY,
              minX: 0,
              maxX: (points.length - 1).toDouble().clamp(1.0, double.infinity),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _calculateGridInterval(series.minY, series.maxY),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: _calculateGridInterval(series.minY, series.maxY),
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Text(
                          value.round().toString(),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: _calculateXInterval(points.length),
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) {
                        return const SizedBox.shrink();
                      }
                      final p = points[idx];
                      final fmt = series.period == TrendPeriod.year1
                          ? DateFormat('MMM')
                          : DateFormat('M/d');
                      return Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          fmt.format(p.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => isDark ? AppColors.neutral800 : AppColors.neutral900,
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (touchedSpots) {
                    if (touchedSpots.isEmpty) return [];
                    final idx = touchedSpots.first.spotIndex;
                    if (idx < 0 || idx >= points.length) return [];
                    final point = points[idx];

                    return [
                      LineTooltipItem(
                        isBp
                            ? '${point.formatDisplayValue()}\n${DateFormat('MMM d, h:mm a').format(point.timestamp)}'
                            : '${point.formatDisplayValue(decimals: _decimalsForType(series.type))}\n${DateFormat('MMM d, h:mm a').format(point.timestamp)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ];
                  },
                ),
                touchCallback: (event, response) {
                  if (response != null &&
                      response.lineBarSpots != null &&
                      response.lineBarSpots!.isNotEmpty) {
                    final idx = response.lineBarSpots!.first.spotIndex;
                    if (idx >= 0 && idx < points.length) {
                      setState(() {
                        _selectedPoint = points[idx];
                      });
                      widget.onPointSelected?.call(points[idx]);
                    }
                  }
                },
              ),
              lineBarsData: [
                // Primary Line (Systolic for BP, Main Value for others)
                LineChartBarData(
                  spots: [
                    for (int i = 0; i < points.length; i++)
                      FlSpot(i.toDouble(), points[i].primaryValue),
                  ],
                  isCurved: points.length > 2,
                  curveSmoothness: 0.2,
                  color: AppColors.primary500,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: points.length <= 30,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3.5,
                        color: AppColors.primary500,
                        strokeWidth: 1.5,
                        strokeColor: isDark ? AppColors.neutral900 : Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: !isBp,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary500.withAlpha(50),
                        AppColors.primary500.withAlpha(0),
                      ],
                    ),
                  ),
                ),

                // Secondary Line (Diastolic for BP only)
                if (isBp) ...[
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), points[i].secondaryValue ?? 0.0),
                    ],
                    isCurved: points.length > 2,
                    curveSmoothness: 0.2,
                    color: AppColors.secondary500,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: points.length <= 30,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3.5,
                          color: AppColors.secondary500,
                          strokeWidth: 1.5,
                          strokeColor: isDark ? AppColors.neutral900 : Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Dedicated Inspection Details Card (Activated by tap)
        const SizedBox(height: AppSpacing.md),
        _buildInspectedPointCard(_selectedPoint ?? points.last, isDark, isBp),
      ],
    );
  }

  Widget _buildInspectedPointCard(ChartDataPoint point, bool isDark, bool isBp) {
    final dateFormat = DateFormat('EEEE, MMM d, y • h:mm a');

    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral800 : AppColors.neutral50,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: isDark ? AppColors.neutral700 : AppColors.neutral200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppColors.primary500.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.touch_app_outlined,
              size: 20,
              color: AppColors.primary500,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'INSPECTED READING',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.neutral500,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      point.source.displayName,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isBp
                      ? point.formatDisplayValue()
                      : point.formatDisplayValue(decimals: _decimalsForType(widget.series.type)),
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateFormat.format(point.timestamp),
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  double _calculateGridInterval(double min, double max) {
    final diff = max - min;
    if (diff <= 5) return 1;
    if (diff <= 20) return 5;
    if (diff <= 60) return 10;
    if (diff <= 120) return 20;
    return 50;
  }

  double _calculateXInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 30) return 5;
    if (count <= 90) return 15;
    return 30;
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
