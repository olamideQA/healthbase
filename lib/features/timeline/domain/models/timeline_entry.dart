import 'package:flutter/material.dart';
import '../../../measurements/domain/models/measurement.dart';
import '../../../daily_check/domain/models/daily_check.dart';

/// Available predefined date filters for the timeline.
enum TimelineDateFilter {
  last7Days('Last 7 Days'),
  last30Days('Last 30 Days'),
  last90Days('Last 90 Days'),
  allTime('All Time'),
  custom('Custom Range');

  const TimelineDateFilter(this.displayName);
  final String displayName;

  /// Calculate start and end date range for predefined filters.
  DateTimeRange? getDateRange([DateTimeRange? customRange]) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return switch (this) {
      TimelineDateFilter.last7Days => DateTimeRange(
          start: DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 6)),
          end: todayEnd,
        ),
      TimelineDateFilter.last30Days => DateTimeRange(
          start: DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 29)),
          end: todayEnd,
        ),
      TimelineDateFilter.last90Days => DateTimeRange(
          start: DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 89)),
          end: todayEnd,
        ),
      TimelineDateFilter.allTime => null,
      TimelineDateFilter.custom => customRange,
    };
  }
}

/// Available metric filters for the timeline.
enum TimelineMetricFilter {
  all('All'),
  heartRate('Heart Rate'),
  bloodPressure('Blood Pressure'),
  temperature('Temperature'),
  weight('Weight'),
  bloodGlucose('Blood Glucose'),
  symptoms('Symptoms'),
  dailyCheck('Daily Check');

  const TimelineMetricFilter(this.displayName);
  final String displayName;

  MeasurementType? toMeasurementType() {
    return switch (this) {
      TimelineMetricFilter.heartRate => MeasurementType.heartRate,
      TimelineMetricFilter.bloodPressure => MeasurementType.bloodPressure,
      TimelineMetricFilter.temperature => MeasurementType.temperature,
      TimelineMetricFilter.weight => MeasurementType.weight,
      TimelineMetricFilter.bloodGlucose => MeasurementType.bloodGlucose,
      _ => null,
    };
  }
}

/// Unified daily health record aggregated for a single calendar day.
class TimelineDayRecord {
  const TimelineDayRecord({
    required this.date,
    this.heartRate,
    this.bloodPressure,
    this.temperature,
    this.weight,
    this.glucose,
    this.dailyCheck,
    this.dailyCheckSyncStatus = SyncStatus.synced,
    this.allDayMeasurements = const [],
  });

  /// The calendar date (normalized to midnight).
  final DateTime date;

  /// Primary or latest Heart Rate reading for the day.
  final Measurement? heartRate;

  /// Primary or latest Blood Pressure reading for the day.
  final Measurement? bloodPressure;

  /// Primary or latest Temperature reading for the day.
  final Measurement? temperature;

  /// Primary or latest Weight reading for the day.
  final Measurement? weight;

  /// Primary or latest Blood Glucose reading for the day.
  final Measurement? glucose;

  /// Completed Daily Health Check for the day (if any).
  final DailyCheck? dailyCheck;

  /// Local SQLite sync status of the daily check row.
  final SyncStatus dailyCheckSyncStatus;

  /// All individual discrete measurements recorded on this day.
  final List<Measurement> allDayMeasurements;

  /// Check if this day has any recorded health data at all.
  bool get hasData =>
      heartRate != null ||
      bloodPressure != null ||
      temperature != null ||
      weight != null ||
      glucose != null ||
      dailyCheck != null ||
      allDayMeasurements.isNotEmpty;

  /// Active symptoms reported on this day.
  List<CheckSymptom> get symptoms => dailyCheck?.symptoms ?? const [];

  /// Check if any urgent symptom was reported on this day.
  bool get hasUrgentSymptom => symptoms.any((s) => s.isUrgent);

  /// Reported medication adherence status for this day.
  MedicationCheckStatus? get medicationStatus => dailyCheck?.medicationStatus;

  /// Overall feeling for this day.
  CheckFeeling? get feeling => dailyCheck?.feeling;

  /// Aggregated sync status for all items recorded on this day.
  SyncStatus get syncStatus {
    final allStatuses = <SyncStatus>[
      if (dailyCheck != null) dailyCheckSyncStatus,
      ...allDayMeasurements.map((m) => m.syncStatus),
    ];

    if (allStatuses.isEmpty) return SyncStatus.synced;
    if (allStatuses.any((s) => s == SyncStatus.syncError)) {
      return SyncStatus.syncError;
    }
    if (allStatuses.any((s) =>
        s == SyncStatus.pendingInsert ||
        s == SyncStatus.pendingUpdate ||
        s == SyncStatus.pendingDelete)) {
      return SyncStatus.pendingInsert;
    }
    return SyncStatus.synced;
  }

  /// Whether this day satisfies the active metric filter.
  bool matchesMetricFilter(TimelineMetricFilter filter) {
    return switch (filter) {
      TimelineMetricFilter.all => true,
      TimelineMetricFilter.heartRate => heartRate != null,
      TimelineMetricFilter.bloodPressure => bloodPressure != null,
      TimelineMetricFilter.temperature => temperature != null,
      TimelineMetricFilter.weight => weight != null,
      TimelineMetricFilter.bloodGlucose => glucose != null,
      TimelineMetricFilter.symptoms => symptoms.isNotEmpty,
      TimelineMetricFilter.dailyCheck => dailyCheck != null,
    };
  }
}

/// Paginated result of timeline day records.
class TimelinePageResult {
  const TimelinePageResult({
    required this.records,
    required this.hasMore,
    required this.pageIndex,
    this.nextCursor,
  });

  final List<TimelineDayRecord> records;
  final bool hasMore;
  final int pageIndex;
  final DateTime? nextCursor;
}
