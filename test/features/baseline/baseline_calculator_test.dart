import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/features/baseline/domain/models/personal_baseline.dart';
import 'package:healthbase/features/baseline/domain/services/baseline_calculator.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';

void main() {
  final now = DateTime(2026, 10, 10, 12, 0);

  Measurement createMeasurement({
    required String id,
    required MeasurementType type,
    double? heartRateBpm,
    double? systolicMmhg,
    double? diastolicMmhg,
    double? temperatureCelsius,
    double? weightKg,
    double? glucoseMmolL,
    required DateTime recordedAt,
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
      recordedAt: recordedAt,
      createdAt: recordedAt,
      updatedAt: recordedAt,
      syncStatus: SyncStatus.synced,
    );
  }

  group('BaselineCalculator Pure Math & Stats Tests', () {
    test('calculateStats computes deterministic mean, median, min, max, and stdDev', () {
      final oddValues = [70.0, 72.0, 74.0, 76.0, 78.0];
      final oddStats = BaselineCalculator.calculateStats(oddValues);

      expect(oddStats.average, 74.0);
      expect(oddStats.median, 74.0);
      expect(oddStats.min, 70.0);
      expect(oddStats.max, 78.0);
      expect(oddStats.measurementCount, 5);

      final evenValues = [70.0, 72.0, 74.0, 76.0];
      final evenStats = BaselineCalculator.calculateStats(evenValues);

      expect(evenStats.average, 73.0);
      expect(evenStats.median, 73.0); // (72 + 74) / 2
      expect(evenStats.min, 70.0);
      expect(evenStats.max, 76.0);
      expect(evenStats.measurementCount, 4);
    });

    test('outliers: median remains robust against extreme measurement spikes', () {
      // Normal resting heart rates around 72 bpm
      final standardValues = [70.0, 71.0, 72.0, 72.0, 73.0];
      final standardStats = BaselineCalculator.calculateStats(standardValues);
      expect(standardStats.median, 72.0);
      expect(standardStats.average, 71.6);

      // Extreme outlier spike added (e.g. sensor artifact or intense sprint)
      final outlierValues = [70.0, 71.0, 72.0, 72.0, 73.0, 160.0];
      final outlierStats = BaselineCalculator.calculateStats(outlierValues);

      // Median shifts only slightly to 72.0 (robust 50th percentile)
      expect(outlierStats.median, 72.0);
      // While arithmetic mean is dragged upward to ~86.3
      expect(outlierStats.average, closeTo(86.33, 0.05));
      expect(outlierStats.max, 160.0);
    });
  });

  group('Playbook Required Baseline Scenarios', () {
    test('empty history: returns insufficientData with "Not enough history yet"', () {
      final baseline = BaselineCalculator.calculateScalarBaseline(
        type: MeasurementType.heartRate,
        window: BaselineWindow.days30,
        measurements: [],
        now: now,
        valueExtractor: (m) => m.heartRateBpm,
      );

      expect(baseline.status, BaselineStatus.insufficientData);
      expect(baseline.hasSufficientData, isFalse);
      expect(baseline.statusMessage, 'Not enough history yet');
      expect(baseline.recentTrend, RecentTrend.insufficientData);
      expect(baseline.primaryStats, isNull);
    });

    test('one reading: returns insufficientData indicating entries needed', () {
      final single = [
        createMeasurement(
          id: '1',
          type: MeasurementType.heartRate,
          heartRateBpm: 72.0,
          recordedAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final baseline = BaselineCalculator.calculateScalarBaseline(
        type: MeasurementType.heartRate,
        window: BaselineWindow.days30, // requires min 5 entries
        measurements: single,
        now: now,
        valueExtractor: (m) => m.heartRateBpm,
      );

      expect(baseline.status, BaselineStatus.insufficientData);
      expect(baseline.hasSufficientData, isFalse);
      expect(baseline.statusMessage, 'Not enough history yet (1 of 5 needed)');
      expect(baseline.latestValue, 72.0);
    });

    test('multiple readings: computes valid recent personal range when threshold met', () {
      final readings = [
        for (int i = 0; i < 6; i++)
          createMeasurement(
            id: 'm_$i',
            type: MeasurementType.heartRate,
            heartRateBpm: 70.0 + (i * 2), // 70, 72, 74, 76, 78, 80
            recordedAt: now.subtract(Duration(days: i * 2)),
          ),
      ];

      final baseline = BaselineCalculator.calculateScalarBaseline(
        type: MeasurementType.heartRate,
        window: BaselineWindow.days30,
        measurements: readings,
        now: now,
        valueExtractor: (m) => m.heartRateBpm,
      );

      expect(baseline.status, BaselineStatus.sufficient);
      expect(baseline.hasSufficientData, isTrue);
      expect(baseline.statusMessage, 'Recent personal range established');
      expect(baseline.primaryStats, isNotNull);
      expect(baseline.primaryStats!.measurementCount, 6);
      expect(baseline.primaryStats!.min, 70.0);
      expect(baseline.primaryStats!.max, 80.0);
      expect(baseline.primaryStats!.median, 75.0);
    });

    test('missing dates: irregular timestamps calculate deterministically', () {
      // Days 1, 4, 11, 20, 28 (irregular gaps)
      final irregularDays = [1, 4, 11, 20, 28];
      final readings = [
        for (final day in irregularDays)
          createMeasurement(
            id: 'm_$day',
            type: MeasurementType.weight,
            weightKg: 70.0 + (day * 0.05),
            recordedAt: now.subtract(Duration(days: day)),
          ),
      ];

      final baseline = BaselineCalculator.calculateScalarBaseline(
        type: MeasurementType.weight,
        window: BaselineWindow.days30,
        measurements: readings,
        now: now,
        valueExtractor: (m) => m.weightKg,
      );

      expect(baseline.status, BaselineStatus.sufficient);
      expect(baseline.primaryStats!.measurementCount, 5);
      expect(baseline.primaryStats!.min, 70.0 + (1 * 0.05));
      expect(baseline.primaryStats!.max, 70.0 + (28 * 0.05));
    });

    test('different measurement types: verifies heart rate, blood pressure, temp, weight, glucose', () {
      // 5 measurements for each type
      final allMeasurements = <Measurement>[];
      for (int i = 0; i < 5; i++) {
        final d = now.subtract(Duration(days: i + 1));
        allMeasurements.addAll([
          createMeasurement(
            id: 'hr_$i',
            type: MeasurementType.heartRate,
            heartRateBpm: 68.0 + i,
            recordedAt: d,
          ),
          createMeasurement(
            id: 'bp_$i',
            type: MeasurementType.bloodPressure,
            systolicMmhg: 118.0 + (i * 2),
            diastolicMmhg: 76.0 + i,
            recordedAt: d,
          ),
          createMeasurement(
            id: 'temp_$i',
            type: MeasurementType.temperature,
            temperatureCelsius: 36.5 + (i * 0.1),
            recordedAt: d,
          ),
          createMeasurement(
            id: 'wt_$i',
            type: MeasurementType.weight,
            weightKg: 75.0 + (i * 0.2),
            recordedAt: d,
          ),
          createMeasurement(
            id: 'glu_$i',
            type: MeasurementType.bloodGlucose,
            glucoseMmolL: 5.2 + (i * 0.1),
            recordedAt: d,
          ),
        ]);
      }

      final summary = BaselineCalculator.calculateSummary(
        profileId: 'user_1',
        window: BaselineWindow.days30,
        measurements: allMeasurements,
        now: now,
      );

      expect(summary.heartRate.status, BaselineStatus.sufficient);
      expect(summary.bloodPressure.status, BaselineStatus.sufficient);
      expect(summary.bloodPressure.secondaryStats, isNotNull); // diastolic
      expect(summary.temperature.status, BaselineStatus.sufficient);
      expect(summary.weight.status, BaselineStatus.sufficient);
      expect(summary.bloodGlucose.status, BaselineStatus.sufficient);

      // Verify BP formatting shows systolic/diastolic ranges
      expect(summary.bloodPressure.primaryStats!.min, 118.0);
      expect(summary.bloodPressure.secondaryStats!.min, 76.0);
    });

    test('window cutoff: strictly excludes readings outside the window boundary', () {
      final inside7d = [
        for (int i = 1; i <= 3; i++)
          createMeasurement(
            id: 'in_$i',
            type: MeasurementType.heartRate,
            heartRateBpm: 72.0,
            recordedAt: now.subtract(Duration(days: i)),
          ),
      ];

      final outside7d = [
        createMeasurement(
          id: 'out_1',
          type: MeasurementType.heartRate,
          heartRateBpm: 120.0,
          recordedAt: now.subtract(const Duration(days: 10)), // 10 days ago (outside 7d)
        ),
      ];

      final baseline7d = BaselineCalculator.calculateScalarBaseline(
        type: MeasurementType.heartRate,
        window: BaselineWindow.days7,
        measurements: [...inside7d, ...outside7d],
        now: now,
        valueExtractor: (m) => m.heartRateBpm,
      );

      // Should only include the 3 inside readings, not the 10-day-old 120 bpm reading
      expect(baseline7d.primaryStats!.measurementCount, 3);
      expect(baseline7d.primaryStats!.max, 72.0);
    });
  });
}
