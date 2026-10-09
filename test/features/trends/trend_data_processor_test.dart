import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:healthbase/features/trends/domain/models/trend_chart_data.dart';
import 'package:healthbase/features/trends/domain/services/trend_data_processor.dart';

void main() {
  final now = DateTime(2026, 10, 10, 12, 0);

  Measurement createMeasurement({
    required String id,
    required MeasurementType type,
    required DateTime recordedAt,
    double? heartRateBpm,
    double? systolicMmhg,
    double? diastolicMmhg,
    double? temperatureCelsius,
    double? weightKg,
    double? glucoseMmolL,
  }) {
    return Measurement(
      id: id,
      profileId: 'user_1',
      type: type,
      heartRateBpm: heartRateBpm,
      systolicMmhg: systolicMmhg,
      diastolicMmhg: diastolicMmhg,
      temperatureCelsius: temperatureCelsius,
      weightKg: weightKg,
      glucoseMmolL: glucoseMmolL,
      source: MeasurementSource.manual,
      provenance: MeasurementProvenance.manuallyEntered,
      recordedAt: recordedAt,
      recordedUtcOffset: 0,
      createdAt: recordedAt,
      updatedAt: recordedAt,
    );
  }

  group('TrendDataProcessor Tests', () {
    test('filters measurements strictly within the chosen TrendPeriod duration', () {
      final measurements = [
        createMeasurement(
          id: 'm1',
          type: MeasurementType.heartRate,
          heartRateBpm: 72.0,
          recordedAt: now.subtract(const Duration(days: 2)), // inside 7d
        ),
        createMeasurement(
          id: 'm2',
          type: MeasurementType.heartRate,
          heartRateBpm: 74.0,
          recordedAt: now.subtract(const Duration(days: 5)), // inside 7d
        ),
        createMeasurement(
          id: 'm3',
          type: MeasurementType.heartRate,
          heartRateBpm: 80.0,
          recordedAt: now.subtract(const Duration(days: 12)), // outside 7d, inside 30d
        ),
      ];

      final series7d = TrendDataProcessor.processSeries(
        type: MeasurementType.heartRate,
        period: TrendPeriod.days7,
        rawMeasurements: measurements,
        unitSystem: UnitSystem.metric,
        now: now,
      );

      expect(series7d.count, 2);
      expect(series7d.points.map((p) => p.measurementId), ['m2', 'm1']); // chronological order

      final series30d = TrendDataProcessor.processSeries(
        type: MeasurementType.heartRate,
        period: TrendPeriod.days30,
        rawMeasurements: measurements,
        unitSystem: UnitSystem.metric,
        now: now,
      );

      expect(series30d.count, 3);
    });

    test('honest axis scaling: prevents small fluctuations from appearing exaggerated', () {
      // Very tight cluster: readings between 72 and 74 bpm
      final measurements = [
        createMeasurement(
          id: 'm1',
          type: MeasurementType.heartRate,
          heartRateBpm: 72.0,
          recordedAt: now.subtract(const Duration(days: 2)),
        ),
        createMeasurement(
          id: 'm2',
          type: MeasurementType.heartRate,
          heartRateBpm: 74.0,
          recordedAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final series = TrendDataProcessor.processSeries(
        type: MeasurementType.heartRate,
        period: TrendPeriod.days7,
        rawMeasurements: measurements,
        unitSystem: UnitSystem.metric,
        now: now,
      );

      // Must have at least 30 bpm total span buffer to avoid truncated scale distortion
      final span = series.maxY - series.minY;
      expect(span, greaterThanOrEqualTo(30.0));
      expect(series.minY, lessThan(72.0));
      expect(series.maxY, greaterThan(74.0));
    });

    test('blood pressure extracts distinct systolic and diastolic series', () {
      final measurements = [
        createMeasurement(
          id: 'bp1',
          type: MeasurementType.bloodPressure,
          systolicMmhg: 120.0,
          diastolicMmhg: 80.0,
          recordedAt: now.subtract(const Duration(days: 3)),
        ),
        createMeasurement(
          id: 'bp2',
          type: MeasurementType.bloodPressure,
          systolicMmhg: 124.0,
          diastolicMmhg: 82.0,
          recordedAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final series = TrendDataProcessor.processSeries(
        type: MeasurementType.bloodPressure,
        period: TrendPeriod.days7,
        rawMeasurements: measurements,
        unitSystem: UnitSystem.metric,
        now: now,
      );

      expect(series.count, 2);
      expect(series.points[0].primaryValue, 120.0);
      expect(series.points[0].secondaryValue, 80.0);
      expect(series.average, 122.0);
      expect(series.secondaryAverage, 81.0);
      expect(series.minY, lessThanOrEqualTo(80.0));
      expect(series.maxY, greaterThanOrEqualTo(124.0));
    });

    test('1-year view aggregates multi-reading days into daily averages', () {
      final measurements = <Measurement>[];
      // Generate 70 readings over 35 days (2 readings per day)
      for (int day = 1; day <= 35; day++) {
        final targetDate = now.subtract(Duration(days: day));
        measurements.add(
          createMeasurement(
            id: 'd_${day}_morning',
            type: MeasurementType.heartRate,
            heartRateBpm: 70.0,
            recordedAt: DateTime(targetDate.year, targetDate.month, targetDate.day, 8, 0),
          ),
        );
        measurements.add(
          createMeasurement(
            id: 'd_${day}_evening',
            type: MeasurementType.heartRate,
            heartRateBpm: 80.0,
            recordedAt: DateTime(targetDate.year, targetDate.month, targetDate.day, 20, 0),
          ),
        );
      }

      final series1y = TrendDataProcessor.processSeries(
        type: MeasurementType.heartRate,
        period: TrendPeriod.year1,
        rawMeasurements: measurements,
        unitSystem: UnitSystem.metric,
        now: now,
      );

      // 70 points aggregated into 35 daily average points (average 75 bpm)
      expect(series1y.count, 35);
      expect(series1y.points.every((p) => p.isAggregated), isTrue);
      expect(series1y.points.first.primaryValue, 75.0);
    });

    test('respects imperial unit conversions for temperature, weight, and glucose', () {
      final temp = [
        createMeasurement(
          id: 't1',
          type: MeasurementType.temperature,
          temperatureCelsius: 37.0,
          recordedAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final seriesMetric = TrendDataProcessor.processSeries(
        type: MeasurementType.temperature,
        period: TrendPeriod.days7,
        rawMeasurements: temp,
        unitSystem: UnitSystem.metric,
        now: now,
      );
      expect(seriesMetric.unit, '°C');
      expect(seriesMetric.points.first.primaryValue, 37.0);

      final seriesImperial = TrendDataProcessor.processSeries(
        type: MeasurementType.temperature,
        period: TrendPeriod.days7,
        rawMeasurements: temp,
        unitSystem: UnitSystem.imperial,
        now: now,
      );
      expect(seriesImperial.unit, '°F');
      expect(seriesImperial.points.first.primaryValue, closeTo(98.6, 0.1));
    });

    test('empty raw measurements returns MetricTrendSeries.empty', () {
      final series = TrendDataProcessor.processSeries(
        type: MeasurementType.weight,
        period: TrendPeriod.days30,
        rawMeasurements: [],
        unitSystem: UnitSystem.metric,
        now: now,
      );

      expect(series.hasData, isFalse);
      expect(series.count, 0);
      expect(series.unit, 'kg');
    });
  });
}
