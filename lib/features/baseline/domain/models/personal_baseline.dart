import 'package:flutter/foundation.dart';
import '../../../measurements/domain/models/measurement.dart';
import '../../../profile/domain/models/health_profile.dart';

/// Supported rolling time windows for calculating personal baseline statistics.
enum BaselineWindow {
  days7('Last 7 Days', Duration(days: 7), minEntries: 3),
  days30('Last 30 Days', Duration(days: 30), minEntries: 5),
  days90('Last 90 Days', Duration(days: 90), minEntries: 7);

  const BaselineWindow(
    this.displayName,
    this.duration, {
    required this.minEntries,
  });

  final String displayName;
  final Duration duration;
  final int minEntries;
}

/// Baseline confidence and data sufficiency status.
enum BaselineStatus {
  sufficient,
  insufficientData;

  bool get isSufficient => this == BaselineStatus.sufficient;
}

/// Statistical trend of the latest reading compared against the personal baseline.
enum RecentTrend {
  stable('Stable'),
  increased('Increased'),
  decreased('Decreased'),
  higherThanBaseline('Higher than personal range'),
  lowerThanBaseline('Lower than personal range'),
  insufficientData('Not enough history yet');

  const RecentTrend(this.displayName);
  final String displayName;
}

/// Robust mathematical statistics for a continuous health metric over a time window.
@immutable
class StatisticalRange {
  const StatisticalRange({
    required this.average,
    required this.median,
    required this.min,
    required this.max,
    required this.standardDeviation,
    required this.measurementCount,
    this.q1,
    this.q3,
  });

  /// Arithmetic mean of all valid readings in the window.
  final double average;

  /// 50th percentile (middle value) of sorted readings.
  final double median;

  /// Minimum observed value in the window.
  final double min;

  /// Maximum observed value in the window.
  final double max;

  /// Standard deviation reflecting physiological variability.
  final double standardDeviation;

  /// Number of valid data points analyzed.
  final int measurementCount;

  /// 25th percentile (Q1).
  final double? q1;

  /// 75th percentile (Q3).
  final double? q3;

  /// Formatted min–max personal range string.
  String formatRange({int decimals = 0}) {
    if (decimals == 0) {
      return '${min.round()} – ${max.round()}';
    }
    return '${min.toStringAsFixed(decimals)} – ${max.toStringAsFixed(decimals)}';
  }

  /// Formatted median string.
  String formatMedian({int decimals = 0}) {
    if (decimals == 0) {
      return '${median.round()}';
    }
    return median.toStringAsFixed(decimals);
  }

  /// Formatted average string.
  String formatAverage({int decimals = 1}) {
    return average.toStringAsFixed(decimals);
  }
}

/// Personal baseline statistics and recent trend for a specific measurement type.
@immutable
class MetricBaseline {
  const MetricBaseline({
    required this.type,
    required this.window,
    required this.status,
    required this.statusMessage,
    this.primaryStats,
    this.secondaryStats,
    this.recentTrend = RecentTrend.insufficientData,
    this.latestValue,
    this.latestSecondaryValue,
    this.latestRecordedAt,
  });

  final MeasurementType type;
  final BaselineWindow window;
  final BaselineStatus status;
  final String statusMessage;

  /// Primary metric statistics (e.g. Heart Rate, Temperature, Weight, Glucose, Systolic BP).
  final StatisticalRange? primaryStats;

  /// Secondary metric statistics (e.g. Diastolic BP).
  final StatisticalRange? secondaryStats;

  /// Statistical trend comparing latest measurement to personal range.
  final RecentTrend recentTrend;

  /// Most recently recorded primary value.
  final double? latestValue;

  /// Most recently recorded secondary value (e.g. Diastolic).
  final double? latestSecondaryValue;

  /// Timestamp of the latest measurement.
  final DateTime? latestRecordedAt;

  bool get hasSufficientData => status == BaselineStatus.sufficient;

  int get totalMeasurements => primaryStats?.measurementCount ?? 0;

  /// Format range display string respecting unit system.
  String formatPersonalRange(UnitSystem units) {
    if (!hasSufficientData || primaryStats == null) {
      return statusMessage;
    }

    if (type == MeasurementType.bloodPressure && secondaryStats != null) {
      final sysMin = primaryStats!.min.round();
      final sysMax = primaryStats!.max.round();
      final diaMin = secondaryStats!.min.round();
      final diaMax = secondaryStats!.max.round();
      return '$sysMin/$diaMin – $sysMax/$diaMax mmHg';
    }

    final decimals = switch (type) {
      MeasurementType.heartRate => 0,
      MeasurementType.bloodPressure => 0,
      MeasurementType.temperature => 1,
      MeasurementType.weight => 1,
      MeasurementType.bloodGlucose => 1,
    };

    final unitLabel = switch (type) {
      MeasurementType.heartRate => 'bpm',
      MeasurementType.bloodPressure => 'mmHg',
      MeasurementType.temperature => units == UnitSystem.metric ? '°C' : '°F',
      MeasurementType.weight => units == UnitSystem.metric ? 'kg' : 'lbs',
      MeasurementType.bloodGlucose => 'mmol/L',
    };

    return '${primaryStats!.formatRange(decimals: decimals)} $unitLabel';
  }

  /// Create an insufficient data placeholder with accurate remaining count.
  factory MetricBaseline.insufficient({
    required MeasurementType type,
    required BaselineWindow window,
    int recordedCount = 0,
    double? latestValue,
    double? latestSecondaryValue,
    DateTime? latestRecordedAt,
  }) {
    final message = recordedCount == 0
        ? 'Not enough history yet'
        : 'Not enough history yet ($recordedCount of ${window.minEntries} needed)';

    return MetricBaseline(
      type: type,
      window: window,
      status: BaselineStatus.insufficientData,
      statusMessage: message,
      recentTrend: RecentTrend.insufficientData,
      latestValue: latestValue,
      latestSecondaryValue: latestSecondaryValue,
      latestRecordedAt: latestRecordedAt,
    );
  }
}

/// Comprehensive personal baseline summary for a user across all five physiological metrics.
@immutable
class PersonalBaselineSummary {
  const PersonalBaselineSummary({
    required this.profileId,
    required this.window,
    required this.calculatedAt,
    required this.heartRate,
    required this.bloodPressure,
    required this.temperature,
    required this.weight,
    required this.bloodGlucose,
  });

  final String profileId;
  final BaselineWindow window;
  final DateTime calculatedAt;

  final MetricBaseline heartRate;
  final MetricBaseline bloodPressure;
  final MetricBaseline temperature;
  final MetricBaseline weight;
  final MetricBaseline bloodGlucose;

  List<MetricBaseline> get allBaselines => [
        heartRate,
        bloodPressure,
        temperature,
        weight,
        bloodGlucose,
      ];

  MetricBaseline forType(MeasurementType type) {
    return switch (type) {
      MeasurementType.heartRate => heartRate,
      MeasurementType.bloodPressure => bloodPressure,
      MeasurementType.temperature => temperature,
      MeasurementType.weight => weight,
      MeasurementType.bloodGlucose => bloodGlucose,
    };
  }
}
