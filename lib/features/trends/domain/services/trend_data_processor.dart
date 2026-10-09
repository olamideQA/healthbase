import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../../../measurements/domain/models/measurement.dart';
import '../../../profile/domain/models/health_profile.dart';
import '../models/trend_chart_data.dart';

/// Pure functional, deterministic processor that prepares measurement data
/// for honest, clinically sound longitudinal charting.
class TrendDataProcessor {
  const TrendDataProcessor._();

  /// Process measurements into a [MetricTrendSeries] for the given type and period.
  static MetricTrendSeries processSeries({
    required MeasurementType type,
    required TrendPeriod period,
    required List<Measurement> rawMeasurements,
    required UnitSystem unitSystem,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final cutoff = effectiveNow.subtract(period.duration);

    // 1. Filter by type and period cutoff, and exclude soft-deleted records
    final inWindow = rawMeasurements.where((m) {
      if (m.type != type || m.isDeleted) return false;
      return m.recordedAt.isAfter(cutoff) || m.recordedAt.isAtSameMomentAs(cutoff);
    }).toList();

    // 2. Sort chronologically (oldest first for charting left to right)
    inWindow.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final isMetric = unitSystem == UnitSystem.metric;
    final unit = _getUnit(type, isMetric);

    if (inWindow.isEmpty) {
      return MetricTrendSeries.empty(type: type, period: period, unit: unit);
    }

    // 3. Extract points with unit conversion
    List<ChartDataPoint> points = [];
    for (final m in inWindow) {
      final point = _extractPoint(m, type, isMetric, unit);
      if (point != null) {
        points.add(point);
      }
    }

    if (points.isEmpty) {
      return MetricTrendSeries.empty(type: type, period: period, unit: unit);
    }

    // 4. For 1-year view, aggregate into daily averages to prevent visual clutter and bounded points
    if (period == TrendPeriod.year1 && points.length > 60) {
      points = _aggregateByDay(points, unit);
    }

    // 5. Compute honest, non-exaggerating axis limits
    final (minY, maxY) = _calculateHonestYBounds(type, points, isMetric);

    // 6. Compute primary & secondary summary statistics
    final primaryVals = points.map((p) => p.primaryValue).toList();
    final avg = _mean(primaryVals);
    final med = _median(primaryVals);

    double? secAvg;
    double? secMed;
    if (type == MeasurementType.bloodPressure) {
      final secVals = points.where((p) => p.secondaryValue != null).map((p) => p.secondaryValue!).toList();
      if (secVals.isNotEmpty) {
        secAvg = _mean(secVals);
        secMed = _median(secVals);
      }
    }

    return MetricTrendSeries(
      type: type,
      period: period,
      unit: unit,
      points: points,
      minY: minY,
      maxY: maxY,
      average: avg,
      median: med,
      secondaryAverage: secAvg,
      secondaryMedian: secMed,
    );
  }

  static ChartDataPoint? _extractPoint(
    Measurement m,
    MeasurementType type,
    bool isMetric,
    String unit,
  ) {
    switch (type) {
      case MeasurementType.heartRate:
        if (m.heartRateBpm == null) return null;
        return ChartDataPoint(
          timestamp: m.recordedAt,
          primaryValue: m.heartRateBpm!,
          unit: unit,
          source: m.source,
          measurementId: m.id,
        );

      case MeasurementType.bloodPressure:
        if (m.systolicMmhg == null || m.diastolicMmhg == null) return null;
        return ChartDataPoint(
          timestamp: m.recordedAt,
          primaryValue: m.systolicMmhg!,
          secondaryValue: m.diastolicMmhg!,
          unit: unit,
          source: m.source,
          measurementId: m.id,
        );

      case MeasurementType.temperature:
        if (m.temperatureCelsius == null) return null;
        final c = m.temperatureCelsius!;
        final val = isMetric ? c : (c * 9.0 / 5.0) + 32.0;
        return ChartDataPoint(
          timestamp: m.recordedAt,
          primaryValue: val,
          unit: unit,
          source: m.source,
          measurementId: m.id,
        );

      case MeasurementType.weight:
        if (m.weightKg == null) return null;
        final kg = m.weightKg!;
        final val = isMetric ? kg : kg * 2.20462;
        return ChartDataPoint(
          timestamp: m.recordedAt,
          primaryValue: val,
          unit: unit,
          source: m.source,
          measurementId: m.id,
        );

      case MeasurementType.bloodGlucose:
        if (m.glucoseMmolL == null) return null;
        final mmol = m.glucoseMmolL!;
        final val = isMetric ? mmol : mmol * 18.0182;
        return ChartDataPoint(
          timestamp: m.recordedAt,
          primaryValue: val,
          unit: unit,
          source: m.source,
          measurementId: m.id,
        );
    }
  }

  /// Aggregates points occurring on the same calendar day into single average daily points.
  static List<ChartDataPoint> _aggregateByDay(
    List<ChartDataPoint> points,
    String unit,
  ) {
    final dayFormat = DateFormat('yyyy-MM-dd');
    final Map<String, List<ChartDataPoint>> grouped = {};

    for (final p in points) {
      final key = dayFormat.format(p.timestamp);
      grouped.putIfAbsent(key, () => []).add(p);
    }

    final aggregated = <ChartDataPoint>[];
    for (final entry in grouped.entries) {
      final group = entry.value;
      final avgPrimary = _mean(group.map((p) => p.primaryValue));
      final hasSec = group.any((p) => p.secondaryValue != null);
      final avgSec = hasSec
          ? _mean(group.where((p) => p.secondaryValue != null).map((p) => p.secondaryValue!))
          : null;

      aggregated.add(ChartDataPoint(
        timestamp: group.first.timestamp,
        primaryValue: avgPrimary,
        secondaryValue: avgSec,
        unit: unit,
        source: group.first.source,
        isAggregated: true,
      ));
    }

    aggregated.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return aggregated;
  }

  /// Computes honest, clinically proportional Y bounds so subtle shifts are not distorted.
  static (double min, double max) _calculateHonestYBounds(
    MeasurementType type,
    List<ChartDataPoint> points,
    bool isMetric,
  ) {
    var rawMin = points.map((p) => p.primaryValue).reduce(math.min);
    var rawMax = points.map((p) => p.primaryValue).reduce(math.max);

    if (type == MeasurementType.bloodPressure) {
      final secMins = points.where((p) => p.secondaryValue != null).map((p) => p.secondaryValue!);
      if (secMins.isNotEmpty) {
        rawMin = math.min(rawMin, secMins.reduce(math.min));
      }
      final secMaxs = points.where((p) => p.secondaryValue != null).map((p) => p.secondaryValue!);
      if (secMaxs.isNotEmpty) {
        rawMax = math.max(rawMax, secMaxs.reduce(math.max));
      }
    }

    switch (type) {
      case MeasurementType.heartRate:
        // Ensure at least 30 bpm total range spread to prevent micro-fluctuations from looking huge
        const minSpan = 30.0;
        final mid = (rawMin + rawMax) / 2.0;
        final halfSpan = math.max((rawMax - rawMin) / 2.0 + 8.0, minSpan / 2.0);
        return (
          math.max(30.0, (mid - halfSpan).floorToDouble()),
          math.min(220.0, (mid + halfSpan).ceilToDouble()),
        );

      case MeasurementType.bloodPressure:
        // Ensure at least 40 mmHg total range spread covering both systolic and diastolic
        const minSpan = 45.0;
        final mid = (rawMin + rawMax) / 2.0;
        final halfSpan = math.max((rawMax - rawMin) / 2.0 + 10.0, minSpan / 2.0);
        return (
          math.max(40.0, (mid - halfSpan).floorToDouble()),
          math.min(240.0, (mid + halfSpan).ceilToDouble()),
        );

      case MeasurementType.temperature:
        // Minimum span: 2.0 °C (or 4.0 °F)
        final minSpan = isMetric ? 2.0 : 4.0;
        final mid = (rawMin + rawMax) / 2.0;
        final halfSpan = math.max((rawMax - rawMin) / 2.0 + 0.5, minSpan / 2.0);
        return (
          (mid - halfSpan).floorToDouble(),
          (mid + halfSpan).ceilToDouble(),
        );

      case MeasurementType.weight:
        // Minimum span: 6.0 kg (or 14.0 lbs)
        final minSpan = isMetric ? 6.0 : 14.0;
        final mid = (rawMin + rawMax) / 2.0;
        final halfSpan = math.max((rawMax - rawMin) / 2.0 + 2.0, minSpan / 2.0);
        return (
          math.max(0.0, (mid - halfSpan).floorToDouble()),
          (mid + halfSpan).ceilToDouble(),
        );

      case MeasurementType.bloodGlucose:
        // Minimum span: 4.0 mmol/L (or 70 mg/dL)
        final minSpan = isMetric ? 4.0 : 70.0;
        final mid = (rawMin + rawMax) / 2.0;
        final halfSpan = math.max((rawMax - rawMin) / 2.0 + 1.0, minSpan / 2.0);
        return (
          math.max(0.0, (mid - halfSpan).floorToDouble()),
          (mid + halfSpan).ceilToDouble(),
        );
    }
  }

  static String _getUnit(MeasurementType type, bool isMetric) {
    return switch (type) {
      MeasurementType.heartRate => 'bpm',
      MeasurementType.bloodPressure => 'mmHg',
      MeasurementType.temperature => isMetric ? '°C' : '°F',
      MeasurementType.weight => isMetric ? 'kg' : 'lbs',
      MeasurementType.bloodGlucose => isMetric ? 'mmol/L' : 'mg/dL',
    };
  }

  static double _mean(Iterable<double> values) {
    if (values.isEmpty) return 0.0;
    final sum = values.fold<double>(0.0, (acc, v) => acc + v);
    return sum / values.length;
  }

  static double _median(Iterable<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = values.toList()..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[mid];
    }
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }
}
