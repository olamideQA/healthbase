import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/safety/clinical_thresholds.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';

void main() {
  group('ClinicalThresholds - Blood Pressure (AHA/ACC 2017)', () {
    test('115/75 mmHg classifies as Normal Range', () {
      final eval = ClinicalThresholds.evaluateBloodPressure(
        systolic: 115.0,
        diastolic: 75.0,
      );
      expect(eval.severity, ClinicalSeverity.normal);
      expect(eval.categoryName, contains('Normal'));
      expect(eval.guideline, GuidelineAuthority.ahaAcc2017);
      expect(eval.requiresEmergencyPrompt, isFalse);
    });

    test('125/75 mmHg classifies as Elevated Range', () {
      final eval = ClinicalThresholds.evaluateBloodPressure(
        systolic: 125.0,
        diastolic: 75.0,
      );
      expect(eval.severity, ClinicalSeverity.borderline);
      expect(eval.categoryName, contains('Elevated'));
      expect(eval.requiresEmergencyPrompt, isFalse);
    });

    test('135/85 mmHg classifies as Stage 1 Range', () {
      final eval = ClinicalThresholds.evaluateBloodPressure(
        systolic: 135.0,
        diastolic: 85.0,
      );
      expect(eval.severity, ClinicalSeverity.borderline);
      expect(eval.categoryName, contains('Stage 1'));
      expect(eval.requiresEmergencyPrompt, isFalse);
    });

    test('145/95 mmHg classifies as Stage 2 Range', () {
      final eval = ClinicalThresholds.evaluateBloodPressure(
        systolic: 145.0,
        diastolic: 95.0,
      );
      expect(eval.severity, ClinicalSeverity.elevated);
      expect(eval.categoryName, contains('Stage 2'));
      expect(eval.requiresPhysicianConsultation, isTrue);
      expect(eval.requiresEmergencyPrompt, isFalse);
    });

    test('190/115 mmHg classifies as Hypertensive Crisis Range', () {
      final eval = ClinicalThresholds.evaluateBloodPressure(
        systolic: 190.0,
        diastolic: 115.0,
      );
      expect(eval.severity, ClinicalSeverity.criticalUrgent);
      expect(eval.categoryName, contains('Hypertensive Crisis'));
      expect(eval.requiresEmergencyPrompt, isTrue);
      expect(eval.requiresPhysicianConsultation, isTrue);
    });

    test('150/125 mmHg (diastolic > 120) classifies as Hypertensive Crisis Range', () {
      final eval = ClinicalThresholds.evaluateBloodPressure(
        systolic: 150.0,
        diastolic: 125.0,
      );
      expect(eval.severity, ClinicalSeverity.criticalUrgent);
      expect(eval.requiresEmergencyPrompt, isTrue);
    });

    test('85/55 mmHg classifies as Hypotension Range', () {
      final eval = ClinicalThresholds.evaluateBloodPressure(
        systolic: 85.0,
        diastolic: 55.0,
      );
      expect(eval.severity, ClinicalSeverity.borderline);
      expect(eval.categoryName, contains('Hypotension'));
      expect(eval.requiresPhysicianConsultation, isTrue);
    });
  });

  group('ClinicalThresholds - Heart Rate / Pulse (AHA / CDC)', () {
    test('72 bpm classifies as Normal Resting Pulse', () {
      final eval = ClinicalThresholds.evaluateHeartRate(72.0);
      expect(eval.severity, ClinicalSeverity.normal);
      expect(eval.categoryName, contains('Normal'));
      expect(eval.requiresEmergencyPrompt, isFalse);
    });

    test('52 bpm classifies as Bradycardia', () {
      final eval = ClinicalThresholds.evaluateHeartRate(52.0);
      expect(eval.severity, ClinicalSeverity.borderline);
      expect(eval.categoryName, contains('Bradycardia'));
      expect(eval.requiresEmergencyPrompt, isFalse);
    });

    test('35 bpm classifies as Severe Bradycardia and prompts emergency advisory', () {
      final eval = ClinicalThresholds.evaluateHeartRate(35.0);
      expect(eval.severity, ClinicalSeverity.criticalUrgent);
      expect(eval.categoryName, contains('Severe Bradycardia'));
      expect(eval.requiresEmergencyPrompt, isTrue);
    });

    test('110 bpm classifies as Elevated Pulse (Tachycardia)', () {
      final eval = ClinicalThresholds.evaluateHeartRate(110.0);
      expect(eval.severity, ClinicalSeverity.elevated);
      expect(eval.categoryName, contains('Tachycardia'));
      expect(eval.requiresEmergencyPrompt, isFalse);
    });

    test('155 bpm classifies as Severe Tachycardia and prompts emergency advisory', () {
      final eval = ClinicalThresholds.evaluateHeartRate(155.0);
      expect(eval.severity, ClinicalSeverity.criticalUrgent);
      expect(eval.categoryName, contains('Severe Tachycardia'));
      expect(eval.requiresEmergencyPrompt, isTrue);
    });
  });

  group('ClinicalThresholds - Blood Glucose (ADA 2024)', () {
    test('5.0 mmol/L classifies as Normal Target Range', () {
      final eval = ClinicalThresholds.evaluateBloodGlucose(5.0);
      expect(eval.severity, ClinicalSeverity.normal);
      expect(eval.requiresEmergencyPrompt, isFalse);
    });

    test('2.4 mmol/L (< 54 mg/dL) triggers Level 2 Severe Hypoglycemia Emergency Alert', () {
      final eval = ClinicalThresholds.evaluateBloodGlucose(2.4);
      expect(eval.severity, ClinicalSeverity.criticalUrgent);
      expect(eval.categoryName, contains('Severe Hypoglycemia'));
      expect(eval.requiresEmergencyPrompt, isTrue);
    });

    test('3.4 mmol/L (< 70 mg/dL) classifies as Level 1 Hypoglycemia Alert', () {
      final eval = ClinicalThresholds.evaluateBloodGlucose(3.4);
      expect(eval.severity, ClinicalSeverity.elevated);
      expect(eval.categoryName, contains('Hypoglycemia Alert'));
      expect(eval.requiresEmergencyPrompt, isFalse);
    });

    test('18.5 mmol/L (> 300 mg/dL) triggers Severe Hyperglycemia Alert', () {
      final eval = ClinicalThresholds.evaluateBloodGlucose(18.5);
      expect(eval.severity, ClinicalSeverity.criticalUrgent);
      expect(eval.categoryName, contains('Severe Hyperglycemia'));
      expect(eval.requiresEmergencyPrompt, isTrue);
    });
  });

  group('ClinicalThresholds - Temperature (CDC / NICE)', () {
    test('36.6 °C classifies as Normal Body Temperature', () {
      final eval = ClinicalThresholds.evaluateTemperature(36.6);
      expect(eval.severity, ClinicalSeverity.normal);
      expect(eval.requiresEmergencyPrompt, isFalse);
    });

    test('34.2 °C triggers Hypothermia Warning', () {
      final eval = ClinicalThresholds.evaluateTemperature(34.2);
      expect(eval.severity, ClinicalSeverity.criticalUrgent);
      expect(eval.categoryName, contains('Hypothermia'));
      expect(eval.requiresEmergencyPrompt, isTrue);
    });

    test('38.4 °C classifies as Fever (Pyrexia)', () {
      final eval = ClinicalThresholds.evaluateTemperature(38.4);
      expect(eval.severity, ClinicalSeverity.elevated);
      expect(eval.categoryName, contains('Fever'));
      expect(eval.requiresEmergencyPrompt, isFalse);
    });

    test('40.1 °C triggers High Fever Warning', () {
      final eval = ClinicalThresholds.evaluateTemperature(40.1);
      expect(eval.severity, ClinicalSeverity.criticalUrgent);
      expect(eval.categoryName, contains('High Fever'));
      expect(eval.requiresEmergencyPrompt, isTrue);
    });
  });

  group('ClinicalThresholds - BMI (WHO Adult)', () {
    test('22.0 classifies as Normal Weight Range', () {
      final eval = ClinicalThresholds.evaluateBmi(22.0);
      expect(eval.severity, ClinicalSeverity.normal);
      expect(eval.categoryName, contains('Normal Weight'));
    });

    test('17.5 classifies as Underweight Range', () {
      final eval = ClinicalThresholds.evaluateBmi(17.5);
      expect(eval.severity, ClinicalSeverity.borderline);
      expect(eval.categoryName, contains('Underweight'));
    });

    test('28.0 classifies as Overweight Range', () {
      final eval = ClinicalThresholds.evaluateBmi(28.0);
      expect(eval.severity, ClinicalSeverity.borderline);
      expect(eval.categoryName, contains('Overweight'));
    });

    test('34.0 classifies as Obesity Class Range', () {
      final eval = ClinicalThresholds.evaluateBmi(34.0);
      expect(eval.severity, ClinicalSeverity.elevated);
      expect(eval.categoryName, contains('Obesity'));
      expect(eval.requiresPhysicianConsultation, isTrue);
    });
  });

  group('ClinicalThresholds - Physical Plausibility', () {
    test('valid blood pressure measurement is plausible', () {
      final now = DateTime.now();
      final m = Measurement(
        id: '1',
        profileId: 'p1',
        type: MeasurementType.bloodPressure,
        systolicMmhg: 120.0,
        diastolicMmhg: 80.0,
        recordedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      expect(ClinicalThresholds.isPhysicallyPlausible(m), isTrue);
    });

    test('systolic <= diastolic is physically impossible and rejected', () {
      final now = DateTime.now();
      final m = Measurement(
        id: '2',
        profileId: 'p1',
        type: MeasurementType.bloodPressure,
        systolicMmhg: 80.0,
        diastolicMmhg: 120.0,
        recordedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      expect(ClinicalThresholds.isPhysicallyPlausible(m), isFalse);
    });

    test('heart rate of 400 bpm is rejected as physically implausible', () {
      final now = DateTime.now();
      final m = Measurement(
        id: '3',
        profileId: 'p1',
        type: MeasurementType.heartRate,
        heartRateBpm: 400.0,
        recordedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      expect(ClinicalThresholds.isPhysicallyPlausible(m), isFalse);
    });

    test('temperature of 55 °C is rejected as physically implausible', () {
      final now = DateTime.now();
      final m = Measurement(
        id: '4',
        profileId: 'p1',
        type: MeasurementType.temperature,
        temperatureCelsius: 55.0,
        recordedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      expect(ClinicalThresholds.isPhysicallyPlausible(m), isFalse);
    });
  });
}
