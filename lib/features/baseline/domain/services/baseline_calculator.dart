import 'dart:math';
import '../../../measurements/domain/models/measurement.dart';
import '../models/personal_baseline.dart';

/// Pure mathematical calculation engine for deterministic personal health baselines.
/// 
/// Contains no state, network, or database dependencies to ensure 100% testability.
class BaselineCalculator {
  const BaselineCalculator._();

  /// Calculate summary across all 5 physiological metrics for a given time window.
  static PersonalBaselineSummary calculateSummary({
    required String profileId,
    required BaselineWindow window,
    required List<Measurement> measurements,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();

    final hr = calculateScalarBaseline(
      type: MeasurementType.heartRate,
      window: window,
      measurements: measurements,
      now: effectiveNow,
      thresholdDelta: 3.0, // bpm
      valueExtractor: (m) => m.heartRateBpm,
    );

    final bp = calculateBloodPressureBaseline(
      window: window,
      measurements: measurements,
      now: effectiveNow,
    );

    final temp = calculateScalarBaseline(
      type: MeasurementType.temperature,
      window: window,
      measurements: measurements,
      now: effectiveNow,
      thresholdDelta: 0.2, // °C
      valueExtractor: (m) => m.temperatureCelsius,
    );

    final weight = calculateScalarBaseline(
      type: MeasurementType.weight,
      window: window,
      measurements: measurements,
      now: effectiveNow,
      thresholdDelta: 0.3, // kg
      valueExtractor: (m) => m.weightKg,
    );

    final glucose = calculateScalarBaseline(
      type: MeasurementType.bloodGlucose,
      window: window,
      measurements: measurements,
      now: effectiveNow,
      thresholdDelta: 0.3, // mmol/L
      valueExtractor: (m) => m.glucoseMmolL,
    );

    return PersonalBaselineSummary(
      profileId: profileId,
      window: window,
      calculatedAt: effectiveNow,
      heartRate: hr,
      bloodPressure: bp,
      temperature: temp,
      weight: weight,
      bloodGlucose: glucose,
    );
  }

  /// Calculate personal baseline for a scalar metric (Heart Rate, Temperature, Weight, Glucose).
  static MetricBaseline calculateScalarBaseline({
    required MeasurementType type,
    required BaselineWindow window,
    required List<Measurement> measurements,
    required double? Function(Measurement) valueExtractor,
    DateTime? now,
    double thresholdDelta = 2.0,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final cutoff = effectiveNow.subtract(window.duration);

    // Filter by type, time window, and non-deleted
    final filtered = measurements
        .where((m) =>
            m.type == type &&
            !m.isDeleted &&
            (m.recordedAt.isAfter(cutoff) || m.recordedAt.isAtSameMomentAs(cutoff)))
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    final latest = filtered.firstOrNull;
    final latestVal = latest != null ? valueExtractor(latest) : null;
    final latestDate = latest?.recordedAt;

    final values = filtered
        .map(valueExtractor)
        .whereType<double>()
        .toList();

    // Check minimum entries required for statistical validity
    if (values.length < window.minEntries) {
      return MetricBaseline.insufficient(
        type: type,
        window: window,
        recordedCount: values.length,
        latestValue: latestVal,
        latestRecordedAt: latestDate,
      );
    }

    final stats = calculateStats(values);

    // Determine trend compared against personal median
    final trend = _determineTrend(
      latestValue: latestVal,
      baselineMedian: stats.median,
      thresholdDelta: thresholdDelta,
    );

    return MetricBaseline(
      type: type,
      window: window,
      status: BaselineStatus.sufficient,
      statusMessage: 'Recent personal range established',
      primaryStats: stats,
      recentTrend: trend,
      latestValue: latestVal,
      latestRecordedAt: latestDate,
    );
  }

  /// Calculate personal baseline for Blood Pressure (dual systolic/diastolic metrics).
  static MetricBaseline calculateBloodPressureBaseline({
    required BaselineWindow window,
    required List<Measurement> measurements,
    DateTime? now,
    double thresholdDelta = 4.0, // mmHg
  }) {
    final effectiveNow = now ?? DateTime.now();
    final cutoff = effectiveNow.subtract(window.duration);

    final filtered = measurements
        .where((m) =>
            m.type == MeasurementType.bloodPressure &&
            !m.isDeleted &&
            (m.recordedAt.isAfter(cutoff) || m.recordedAt.isAtSameMomentAs(cutoff)))
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    final latest = filtered.firstOrNull;
    final latestSys = latest?.systolicMmhg;
    final latestDia = latest?.diastolicMmhg;
    final latestDate = latest?.recordedAt;

    final systolicValues = filtered
        .map((m) => m.systolicMmhg)
        .whereType<double>()
        .toList();

    final diastolicValues = filtered
        .map((m) => m.diastolicMmhg)
        .whereType<double>()
        .toList();

    if (systolicValues.length < window.minEntries ||
        diastolicValues.length < window.minEntries) {
      return MetricBaseline.insufficient(
        type: MeasurementType.bloodPressure,
        window: window,
        recordedCount: min(systolicValues.length, diastolicValues.length),
        latestValue: latestSys,
        latestSecondaryValue: latestDia,
        latestRecordedAt: latestDate,
      );
    }

    final sysStats = calculateStats(systolicValues);
    final diaStats = calculateStats(diastolicValues);

    // Trend based primarily on systolic delta
    final trend = _determineTrend(
      latestValue: latestSys,
      baselineMedian: sysStats.median,
      thresholdDelta: thresholdDelta,
    );

    return MetricBaseline(
      type: MeasurementType.bloodPressure,
      window: window,
      status: BaselineStatus.sufficient,
      statusMessage: 'Recent personal range established',
      primaryStats: sysStats,
      secondaryStats: diaStats,
      recentTrend: trend,
      latestValue: latestSys,
      latestSecondaryValue: latestDia,
      latestRecordedAt: latestDate,
    );
  }

  /// Pure statistical analysis of a list of floating-point numbers.
  /// 
  /// Guarantees deterministic computation for average, median, min, max,
  /// standard deviation, and quartiles.
  static StatisticalRange calculateStats(List<double> values) {
    if (values.isEmpty) {
      throw ArgumentError('Cannot calculate statistical range on empty list');
    }

    final n = values.length;
    final sorted = List<double>.from(values)..sort();

    final minVal = sorted.first;
    final maxVal = sorted.last;

    // Arithmetic mean
    final sum = sorted.reduce((a, b) => a + b);
    final mean = sum / n;

    // Median (50th percentile)
    final double medianVal;
    if (n % 2 == 1) {
      medianVal = sorted[n ~/ 2];
    } else {
      medianVal = (sorted[(n ~/ 2) - 1] + sorted[n ~/ 2]) / 2.0;
    }

    // Population standard deviation
    double varianceSum = 0.0;
    for (final v in sorted) {
      final diff = v - mean;
      varianceSum += diff * diff;
    }
    final stdDev = sqrt(varianceSum / n);

    // Quartiles (Q1, Q3) for outlier boundaries
    double? q1Val;
    double? q3Val;
    if (n >= 4) {
      final half = n ~/ 2;
      final lowerHalf = sorted.sublist(0, half);
      final upperHalf = (n % 2 == 1)
          ? sorted.sublist(half + 1)
          : sorted.sublist(half);

      q1Val = _medianOf(lowerHalf);
      q3Val = _medianOf(upperHalf);
    }

    return StatisticalRange(
      average: mean,
      median: medianVal,
      min: minVal,
      max: maxVal,
      standardDeviation: stdDev,
      measurementCount: n,
      q1: q1Val,
      q3: q3Val,
    );
  }

  static double _medianOf(List<double> list) {
    final len = list.length;
    if (len % 2 == 1) {
      return list[len ~/ 2];
    } else {
      return (list[(len ~/ 2) - 1] + list[len ~/ 2]) / 2.0;
    }
  }

  static RecentTrend _determineTrend({
    required double? latestValue,
    required double baselineMedian,
    required double thresholdDelta,
  }) {
    if (latestValue == null) {
      return RecentTrend.insufficientData;
    }

    final delta = latestValue - baselineMedian;
    if (delta.abs() <= thresholdDelta) {
      return RecentTrend.stable;
    } else if (delta > thresholdDelta) {
      return RecentTrend.higherThanBaseline;
    } else {
      return RecentTrend.lowerThanBaseline;
    }
  }
}
