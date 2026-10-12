import 'package:flutter/foundation.dart';
import '../../../../core/theme/components/app_status_chip.dart';
import '../../../daily_check/domain/models/daily_check.dart';
import '../../../measurements/domain/models/measurement.dart';

/// Readings needed before a vital shows a meaningful personal baseline trend.
const int kBaselineUnlockReadings = 3;

@immutable
class MetricLatestState {
  const MetricLatestState({
    required this.type,
    this.latest,
    this.trend = HealthTrendStatus.insufficientData,
    this.readingCount = 0,
  });

  final MeasurementType type;
  final Measurement? latest;
  final HealthTrendStatus trend;

  /// Number of recent readings recorded for this vital (capped by query limit).
  final int readingCount;

  bool get hasReading => latest != null;

  /// Reading count that is never lower than what [latest] implies.
  int get effectiveReadingCount =>
      readingCount > 0 ? readingCount : (hasReading ? 1 : 0);

  bool get isBaselineUnlocked =>
      effectiveReadingCount >= kBaselineUnlockReadings ||
      trend != HealthTrendStatus.insufficientData;
}

@immutable
class DashboardSummary {
  const DashboardSummary({
    required this.profileId,
    required this.metrics,
    this.todayDailyCheck,
    required this.lastUpdated,
  });

  final String profileId;
  final Map<MeasurementType, MetricLatestState> metrics;
  final DailyCheck? todayDailyCheck;
  final DateTime lastUpdated;

  bool get hasTodayCheck => todayDailyCheck != null;

  bool get hasAnyMeasurements => metrics.values.any((m) => m.hasReading);

  MetricLatestState get heartRate =>
      metrics[MeasurementType.heartRate] ??
      const MetricLatestState(type: MeasurementType.heartRate);

  MetricLatestState get bloodPressure =>
      metrics[MeasurementType.bloodPressure] ??
      const MetricLatestState(type: MeasurementType.bloodPressure);

  MetricLatestState get weight =>
      metrics[MeasurementType.weight] ??
      const MetricLatestState(type: MeasurementType.weight);

  MetricLatestState get temperature =>
      metrics[MeasurementType.temperature] ??
      const MetricLatestState(type: MeasurementType.temperature);

  MetricLatestState get bloodGlucose =>
      metrics[MeasurementType.bloodGlucose] ??
      const MetricLatestState(type: MeasurementType.bloodGlucose);

  static String getTimeOfDayGreeting([DateTime? time]) {
    final hour = (time ?? DateTime.now()).hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }
}
