import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/safety/safety_boundaries.dart';

void main() {
  group('SafetyBoundaries', () {
    test('non-diagnostic disclaimers are explicit and non-empty', () {
      expect(SafetyBoundaries.generalDisclaimer, isNotEmpty);
      expect(SafetyBoundaries.baselineExplanation, isNotEmpty);
      expect(SafetyBoundaries.cameraPulseDisclaimer, isNotEmpty);
      expect(SafetyBoundaries.emergencyWarningMessage, isNotEmpty);

      // Verify that disclaimers explicitly state that the app does not diagnose
      expect(SafetyBoundaries.generalDisclaimer, contains('does not diagnose'));
      expect(SafetyBoundaries.baselineExplanation, contains('statistical baseline'));
      expect(SafetyBoundaries.cameraPulseDisclaimer, contains('not a clinical medical measurement'));
    });

    test('urgent symptoms list contains critical emergency red flags', () {
      expect(SafetyBoundaries.urgentSymptoms, isNotEmpty);
      expect(
        SafetyBoundaries.urgentSymptoms.any((s) => s.toLowerCase().contains('chest')),
        isTrue,
      );
      expect(
        SafetyBoundaries.urgentSymptoms.any((s) => s.toLowerCase().contains('breath')),
        isTrue,
      );
    });

    test('physical plausibility ranges are valid and sound', () {
      // Heart rate
      expect(SafetyBoundaries.minHeartRateBpm, greaterThan(0));
      expect(SafetyBoundaries.maxHeartRateBpm, greaterThan(SafetyBoundaries.minHeartRateBpm));

      // Blood pressure
      expect(SafetyBoundaries.minSystolicMmHg, greaterThan(SafetyBoundaries.minDiastolicMmHg));
      expect(SafetyBoundaries.maxSystolicMmHg, greaterThan(SafetyBoundaries.minSystolicMmHg));

      // Temperature
      expect(SafetyBoundaries.minTemperatureCelsius, greaterThan(25.0));
      expect(SafetyBoundaries.maxTemperatureCelsius, lessThan(50.0));

      // Weight
      expect(SafetyBoundaries.minWeightKg, greaterThan(0));
      expect(SafetyBoundaries.maxWeightKg, greaterThan(100));

      // Glucose
      expect(SafetyBoundaries.minGlucoseMmol, greaterThan(0));
      expect(SafetyBoundaries.maxGlucoseMmol, greaterThan(20));
    });
  });
}
