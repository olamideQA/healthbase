import 'package:flutter/foundation.dart';
import '../../../measurements/domain/models/measurement.dart';

/// Supported historical time periods for trends and longitudinal charting.
enum TrendPeriod {
  days7('7 Days', Duration(days: 7)),
  days30('30 Days', Duration(days: 30)),
  days90('90 Days', Duration(days: 90)),
  year1('1 Year', Duration(days: 365));

  const TrendPeriod(this.displayName, this.duration);

  final String displayName;
  final Duration duration;
}

/// A single plottable and inspectable point on a health trend chart.
@immutable
class ChartDataPoint {
  const ChartDataPoint({
    required this.timestamp,
    required this.primaryValue,
    this.secondaryValue,
    required this.unit,
    required this.source,
    this.measurementId,
    this.isAggregated = false,
  });

  final DateTime timestamp;
  final double primaryValue;
  final double? secondaryValue;
  final String unit;
  final MeasurementSource source;
  final String? measurementId;
  final bool isAggregated;

  String formatDisplayValue({int decimals = 0}) {
    if (secondaryValue != null) {
      return '${primaryValue.round()}/${secondaryValue!.round()} $unit';
    }
    if (decimals == 0) {
      return '${primaryValue.round()} $unit';
    }
    return '${primaryValue.toStringAsFixed(decimals)} $unit';
  }
}

/// Longitudinal trend series ready for honest charting.
@immutable
class MetricTrendSeries {
  const MetricTrendSeries({
    required this.type,
    required this.period,
    required this.unit,
    required this.points,
    required this.minY,
    required this.maxY,
    this.average,
    this.median,
    this.secondaryAverage,
    this.secondaryMedian,
  });

  final MeasurementType type;
  final TrendPeriod period;
  final String unit;
  final List<ChartDataPoint> points;
  final double minY;
  final double maxY;
  final double? average;
  final double? median;
  final double? secondaryAverage;
  final double? secondaryMedian;

  bool get hasData => points.isNotEmpty;
  int get count => points.length;

  /// Creates an empty series when no data is recorded in the period.
  factory MetricTrendSeries.empty({
    required MeasurementType type,
    required TrendPeriod period,
    required String unit,
  }) {
    final (min, max) = switch (type) {
      MeasurementType.heartRate => (40.0, 120.0),
      MeasurementType.bloodPressure => (50.0, 160.0),
      MeasurementType.temperature => (35.0, 40.0),
      MeasurementType.weight => (40.0, 120.0),
      MeasurementType.bloodGlucose => (2.0, 15.0),
    };

    return MetricTrendSeries(
      type: type,
      period: period,
      unit: unit,
      points: const [],
      minY: min,
      maxY: max,
    );
  }
}
