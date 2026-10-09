import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/features/insights/domain/models/health_insight.dart';
import 'package:healthbase/features/insights/domain/services/insight_generator.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';

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
      profileId: 'test_user',
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

  group('InsightGenerator Playbook Requirements', () {
    test('increasing trend: generates 3-part sentence with higher direction', () {
      // Recent (last 7 days): average 86 bpm (e.g. 85, 86, 87)
      final recent = [
        createMeasurement(
          id: 'r1',
          type: MeasurementType.heartRate,
          heartRateBpm: 85.0,
          recordedAt: now.subtract(const Duration(days: 1)),
        ),
        createMeasurement(
          id: 'r2',
          type: MeasurementType.heartRate,
          heartRateBpm: 86.0,
          recordedAt: now.subtract(const Duration(days: 3)),
        ),
        createMeasurement(
          id: 'r3',
          type: MeasurementType.heartRate,
          heartRateBpm: 87.0,
          recordedAt: now.subtract(const Duration(days: 5)),
        ),
      ];

      // Baseline (previous 30 days): average 78 bpm (e.g. 77, 78, 78, 79, 78)
      final baseline = [
        createMeasurement(
          id: 'b1',
          type: MeasurementType.heartRate,
          heartRateBpm: 77.0,
          recordedAt: now.subtract(const Duration(days: 10)),
        ),
        createMeasurement(
          id: 'b2',
          type: MeasurementType.heartRate,
          heartRateBpm: 78.0,
          recordedAt: now.subtract(const Duration(days: 14)),
        ),
        createMeasurement(
          id: 'b3',
          type: MeasurementType.heartRate,
          heartRateBpm: 78.0,
          recordedAt: now.subtract(const Duration(days: 18)),
        ),
        createMeasurement(
          id: 'b4',
          type: MeasurementType.heartRate,
          heartRateBpm: 79.0,
          recordedAt: now.subtract(const Duration(days: 22)),
        ),
        createMeasurement(
          id: 'b5',
          type: MeasurementType.heartRate,
          heartRateBpm: 78.0,
          recordedAt: now.subtract(const Duration(days: 26)),
        ),
      ];

      final insight = InsightGenerator.generateHeartRateInsight(
        recent: recent,
        baseline: baseline,
        recentPeriodName: 'the last 7 days',
        baselinePeriodName: 'the previous 30 days',
      );

      expect(insight.direction, InsightDirection.higher);
      expect(insight.hasSufficientData, isTrue);
      // Playbook exact example:
      // "Your average heart rate over the last 7 days is 86 bpm, compared with 78 bpm during the previous 30 days."
      expect(
        insight.explanation,
        'Your average heart rate over the last 7 days is 86 bpm, compared with 78 bpm during the previous 30 days.',
      );
      expect(insight.evidence.recentCount, 3);
      expect(insight.evidence.baselineCount, 5);
      expect(insight.evidence.readings.length, 8);
    });

    test('decreasing trend: generates 3-part sentence with lower direction', () {
      final recent = [
        createMeasurement(
          id: 'r1',
          type: MeasurementType.heartRate,
          heartRateBpm: 68.0,
          recordedAt: now.subtract(const Duration(days: 1)),
        ),
        createMeasurement(
          id: 'r2',
          type: MeasurementType.heartRate,
          heartRateBpm: 70.0,
          recordedAt: now.subtract(const Duration(days: 3)),
        ),
        createMeasurement(
          id: 'r3',
          type: MeasurementType.heartRate,
          heartRateBpm: 69.0,
          recordedAt: now.subtract(const Duration(days: 5)),
        ),
      ];

      final baseline = [
        createMeasurement(
          id: 'b1',
          type: MeasurementType.heartRate,
          heartRateBpm: 80.0,
          recordedAt: now.subtract(const Duration(days: 10)),
        ),
        createMeasurement(
          id: 'b2',
          type: MeasurementType.heartRate,
          heartRateBpm: 82.0,
          recordedAt: now.subtract(const Duration(days: 14)),
        ),
        createMeasurement(
          id: 'b3',
          type: MeasurementType.heartRate,
          heartRateBpm: 81.0,
          recordedAt: now.subtract(const Duration(days: 18)),
        ),
        createMeasurement(
          id: 'b4',
          type: MeasurementType.heartRate,
          heartRateBpm: 83.0,
          recordedAt: now.subtract(const Duration(days: 22)),
        ),
        createMeasurement(
          id: 'b5',
          type: MeasurementType.heartRate,
          heartRateBpm: 82.0,
          recordedAt: now.subtract(const Duration(days: 26)),
        ),
      ];

      final insight = InsightGenerator.generateHeartRateInsight(
        recent: recent,
        baseline: baseline,
        recentPeriodName: 'the last 7 days',
        baselinePeriodName: 'the previous 30 days',
      );

      expect(insight.direction, InsightDirection.lower);
      expect(
        insight.explanation,
        'Your average heart rate over the last 7 days is 69 bpm, compared with 82 bpm during the previous 30 days.',
      );
    });

    test('stable trend: indicates readings are within personal range', () {
      final recent = [
        createMeasurement(
          id: 'r1',
          type: MeasurementType.heartRate,
          heartRateBpm: 72.0,
          recordedAt: now.subtract(const Duration(days: 1)),
        ),
        createMeasurement(
          id: 'r2',
          type: MeasurementType.heartRate,
          heartRateBpm: 73.0,
          recordedAt: now.subtract(const Duration(days: 3)),
        ),
        createMeasurement(
          id: 'r3',
          type: MeasurementType.heartRate,
          heartRateBpm: 72.0,
          recordedAt: now.subtract(const Duration(days: 5)),
        ),
      ];

      final baseline = [
        createMeasurement(
          id: 'b1',
          type: MeasurementType.heartRate,
          heartRateBpm: 71.0,
          recordedAt: now.subtract(const Duration(days: 10)),
        ),
        createMeasurement(
          id: 'b2',
          type: MeasurementType.heartRate,
          heartRateBpm: 72.0,
          recordedAt: now.subtract(const Duration(days: 14)),
        ),
        createMeasurement(
          id: 'b3',
          type: MeasurementType.heartRate,
          heartRateBpm: 74.0,
          recordedAt: now.subtract(const Duration(days: 18)),
        ),
        createMeasurement(
          id: 'b4',
          type: MeasurementType.heartRate,
          heartRateBpm: 73.0,
          recordedAt: now.subtract(const Duration(days: 22)),
        ),
        createMeasurement(
          id: 'b5',
          type: MeasurementType.heartRate,
          heartRateBpm: 72.0,
          recordedAt: now.subtract(const Duration(days: 26)),
        ),
      ];

      final insight = InsightGenerator.generateHeartRateInsight(
        recent: recent,
        baseline: baseline,
      );

      expect(insight.direction, InsightDirection.withinRange);
      expect(
        insight.explanation,
        'Your recent heart rate readings are within your recent personal range (71 – 74 bpm).',
      );
    });

    test('insufficient data: cold-start guard triggers when counts below thresholds', () {
      final recent = [
        createMeasurement(
          id: 'r1',
          type: MeasurementType.heartRate,
          heartRateBpm: 72.0,
          recordedAt: now.subtract(const Duration(days: 1)),
        ),
      ]; // only 1 reading, requires min 3

      final baseline = <Measurement>[]; // 0 readings, requires min 5

      final insight = InsightGenerator.generateHeartRateInsight(
        recent: recent,
        baseline: baseline,
        recentPeriodName: 'the last 7 days',
        baselinePeriodName: 'the previous 30 days',
      );

      expect(insight.direction, InsightDirection.insufficientData);
      expect(insight.hasSufficientData, isFalse);
      expect(
        insight.explanation,
        'Not enough history yet to compare heart rate. Record at least 3 readings in the last 7 days and 5 in the previous 30 days.',
      );
      expect(insight.evidence.recentCount, 1);
      expect(insight.evidence.baselineCount, 0);
    });

    test('missing measurements: irregular timestamps compute deterministically', () {
      final recent = [
        createMeasurement(
          id: 'r1',
          type: MeasurementType.weight,
          weightKg: 78.5,
          recordedAt: now.subtract(const Duration(days: 1, hours: 4)),
        ),
        createMeasurement(
          id: 'r2',
          type: MeasurementType.weight,
          weightKg: 78.8,
          recordedAt: now.subtract(const Duration(days: 4, hours: 2)),
        ),
        createMeasurement(
          id: 'r3',
          type: MeasurementType.weight,
          weightKg: 78.6,
          recordedAt: now.subtract(const Duration(days: 6, hours: 19)),
        ),
      ];

      final baseline = [
        createMeasurement(
          id: 'b1',
          type: MeasurementType.weight,
          weightKg: 76.0,
          recordedAt: now.subtract(const Duration(days: 9)),
        ),
        createMeasurement(
          id: 'b2',
          type: MeasurementType.weight,
          weightKg: 76.2,
          recordedAt: now.subtract(const Duration(days: 15)),
        ),
        createMeasurement(
          id: 'b3',
          type: MeasurementType.weight,
          weightKg: 76.1,
          recordedAt: now.subtract(const Duration(days: 20)),
        ),
        createMeasurement(
          id: 'b4',
          type: MeasurementType.weight,
          weightKg: 76.3,
          recordedAt: now.subtract(const Duration(days: 25)),
        ),
        createMeasurement(
          id: 'b5',
          type: MeasurementType.weight,
          weightKg: 76.2,
          recordedAt: now.subtract(const Duration(days: 29)),
        ),
      ];

      final insight = InsightGenerator.generateWeightInsight(
        recent: recent,
        baseline: baseline,
        unitSystem: UnitSystem.metric,
        recentPeriodName: 'the last 7 days',
        baselinePeriodName: 'the previous 30 days',
      );

      expect(insight.direction, InsightDirection.higher);
      expect(
        insight.explanation,
        'Your average weight over the last 7 days is 78.6 kg, compared with 76.2 kg during the previous 30 days.',
      );
    });

    test('outliers: median dampening prevents single extreme spike from distorting insight', () {
      // Recent has normal 72 bpm readings, but one faulty spike 160 bpm
      final recent = [
        createMeasurement(
          id: 'r1',
          type: MeasurementType.heartRate,
          heartRateBpm: 72.0,
          recordedAt: now.subtract(const Duration(days: 1)),
        ),
        createMeasurement(
          id: 'r2',
          type: MeasurementType.heartRate,
          heartRateBpm: 73.0,
          recordedAt: now.subtract(const Duration(days: 2)),
        ),
        createMeasurement(
          id: 'r3',
          type: MeasurementType.heartRate,
          heartRateBpm: 72.0,
          recordedAt: now.subtract(const Duration(days: 3)),
        ),
        createMeasurement(
          id: 'r4',
          type: MeasurementType.heartRate,
          heartRateBpm: 160.0, // artifact outlier!
          recordedAt: now.subtract(const Duration(days: 4)),
        ),
      ];

      final baseline = [
        for (int i = 0; i < 6; i++)
          createMeasurement(
            id: 'b_$i',
            type: MeasurementType.heartRate,
            heartRateBpm: 72.0,
            recordedAt: now.subtract(Duration(days: 10 + (i * 3))),
          ),
      ];

      final insight = InsightGenerator.generateHeartRateInsight(
        recent: recent,
        baseline: baseline,
      );

      // Even with 160 bpm present, median-dampened diff remains within range threshold
      expect(insight.direction, InsightDirection.withinRange);
    });

    test('blood pressure: evaluates systolic and diastolic distinctly', () {
      final recent = [
        for (int i = 0; i < 3; i++)
          createMeasurement(
            id: 'bp_r_$i',
            type: MeasurementType.bloodPressure,
            systolicMmhg: 135.0,
            diastolicMmhg: 88.0,
            recordedAt: now.subtract(Duration(days: i + 1)),
          ),
      ];

      final baseline = [
        for (int i = 0; i < 5; i++)
          createMeasurement(
            id: 'bp_b_$i',
            type: MeasurementType.bloodPressure,
            systolicMmhg: 120.0,
            diastolicMmhg: 80.0,
            recordedAt: now.subtract(Duration(days: 10 + (i * 2))),
          ),
      ];

      final insight = InsightGenerator.generateBloodPressureInsight(
        recent: recent,
        baseline: baseline,
        recentPeriodName: 'the last 7 days',
        baselinePeriodName: 'the previous 30 days',
      );

      expect(insight.direction, InsightDirection.higher);
      expect(
        insight.explanation,
        'Your average blood pressure over the last 7 days is 135/88 mmHg, compared with 120/80 mmHg during the previous 30 days.',
      );
    });

    test('traceability: all evidence measurement items match input IDs and timestamps', () {
      final recent = [
        createMeasurement(
          id: 'm_recent_1',
          type: MeasurementType.temperature,
          temperatureCelsius: 37.1,
          recordedAt: now.subtract(const Duration(days: 1)),
        ),
        createMeasurement(
          id: 'm_recent_2',
          type: MeasurementType.temperature,
          temperatureCelsius: 37.0,
          recordedAt: now.subtract(const Duration(days: 2)),
        ),
        createMeasurement(
          id: 'm_recent_3',
          type: MeasurementType.temperature,
          temperatureCelsius: 37.2,
          recordedAt: now.subtract(const Duration(days: 3)),
        ),
      ];

      final baseline = [
        for (int i = 0; i < 5; i++)
          createMeasurement(
            id: 'm_base_$i',
            type: MeasurementType.temperature,
            temperatureCelsius: 36.6,
            recordedAt: now.subtract(Duration(days: 10 + i)),
          ),
      ];

      final insight = InsightGenerator.generateTemperatureInsight(
        recent: recent,
        baseline: baseline,
        unitSystem: UnitSystem.metric,
      );

      expect(insight.evidence.readings.length, 8);
      expect(insight.evidence.readings.first.measurementId, 'm_recent_1');
      expect(insight.evidence.readings.first.isRecentWindow, isTrue);
      expect(insight.evidence.readings.last.measurementId, 'm_base_4');
      expect(insight.evidence.readings.last.isRecentWindow, isFalse);
    });
  });

  group('Clinical Safety: Banned Diagnostic Phrases Test', () {
    const bannedPhrases = [
      'diagnos',
      'hypertension',
      'hypotension',
      'infection',
      'fever',
      'disease',
      'unhealthy',
      'healthy',
      'abnormal',
      'normal',
      'safe range',
      'sick',
      'danger',
      'patholog',
      'cure',
      'treat',
      'prescri',
    ];

    test('no generated insight ever contains diagnostic or clinical judgment words', () {
      final testCases = <List<Measurement>>[
        // Very high / low values
        [
          for (int i = 0; i < 5; i++)
            createMeasurement(
              id: 'th_$i',
              type: MeasurementType.heartRate,
              heartRateBpm: 195.0,
              recordedAt: now.subtract(Duration(days: i)),
            ),
        ],
        [
          for (int i = 0; i < 5; i++)
            createMeasurement(
              id: 'tbp_$i',
              type: MeasurementType.bloodPressure,
              systolicMmhg: 190.0,
              diastolicMmhg: 120.0,
              recordedAt: now.subtract(Duration(days: i)),
            ),
        ],
        [
          for (int i = 0; i < 5; i++)
            createMeasurement(
              id: 'tt_$i',
              type: MeasurementType.temperature,
              temperatureCelsius: 40.5,
              recordedAt: now.subtract(Duration(days: i)),
            ),
        ],
      ];

      for (final measurements in testCases) {
        final insights = InsightGenerator.generateAllInsights(
          recentMeasurements: measurements,
          baselineMeasurements: measurements,
        );

        for (final insight in insights) {
          final lowerExpl = insight.explanation.toLowerCase();
          final lowerTitle = insight.title.toLowerCase();

          for (final banned in bannedPhrases) {
            expect(
              lowerExpl.contains(banned),
              isFalse,
              reason: 'Found banned word "$banned" in explanation: "${insight.explanation}"',
            );
            expect(
              lowerTitle.contains(banned),
              isFalse,
              reason: 'Found banned word "$banned" in title: "${insight.title}"',
            );
          }
        }
      }
    });
  });
}
