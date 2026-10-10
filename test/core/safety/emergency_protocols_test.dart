import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/safety/emergency_protocols.dart';
import 'package:healthbase/features/daily_check/domain/models/daily_check.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';

void main() {
  final now = DateTime.now();

  group('EmergencyProtocols - Measurements Evaluation', () {
    test('normal reading returns null alert', () {
      final normalBp = Measurement(
        id: '1',
        profileId: 'p1',
        type: MeasurementType.bloodPressure,
        systolicMmhg: 118.0,
        diastolicMmhg: 78.0,
        recordedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final alert = EmergencyProtocols.evaluateMeasurement(normalBp);
      expect(alert, isNull);
    });

    test('hypertensive crisis reading returns immediate emergency alert', () {
      final crisisBp = Measurement(
        id: '2',
        profileId: 'p1',
        type: MeasurementType.bloodPressure,
        systolicMmhg: 195.0,
        diastolicMmhg: 110.0,
        recordedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final alert = EmergencyProtocols.evaluateMeasurement(crisisBp);
      expect(alert, isNotNull);
      expect(alert!.isImmediateEmergency, isTrue);
      expect(alert.headline, contains('Hypertensive Crisis'));
      expect(alert.guidance, contains('emergency services'));
    });

    test('severe tachycardia returns immediate emergency alert', () {
      final highHr = Measurement(
        id: '3',
        profileId: 'p1',
        type: MeasurementType.heartRate,
        heartRateBpm: 155.0,
        recordedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final alert = EmergencyProtocols.evaluateMeasurement(highHr);
      expect(alert, isNotNull);
      expect(alert!.isImmediateEmergency, isTrue);
      expect(alert.headline, contains('Severe Tachycardia'));
    });

    test('critical hypoglycemia returns immediate emergency alert', () {
      final lowSugar = Measurement(
        id: '4',
        profileId: 'p1',
        type: MeasurementType.bloodGlucose,
        glucoseMmolL: 2.5,
        recordedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final alert = EmergencyProtocols.evaluateMeasurement(lowSugar);
      expect(alert, isNotNull);
      expect(alert!.isImmediateEmergency, isTrue);
      expect(alert.headline, contains('Severe Hypoglycemia'));
    });
  });

  group('EmergencyProtocols - Daily Check Evaluation', () {
    test('daily check without urgent symptoms returns null alert', () {
      final check = DailyCheck(
        id: 'c1',
        profileId: 'p1',
        checkDate: now,
        feeling: CheckFeeling.good,
        medicationStatus: MedicationCheckStatus.yes,
        symptoms: const [
          CheckSymptom(symptomCode: 'headache', displayName: 'Mild Headache', isUrgent: false),
        ],
        createdAt: now,
        updatedAt: now,
      );
      final alert = EmergencyProtocols.evaluateDailyCheck(check);
      expect(alert, isNull);
    });

    test('daily check with urgent symptoms returns immediate emergency alert', () {
      final check = DailyCheck(
        id: 'c2',
        profileId: 'p1',
        checkDate: now,
        feeling: CheckFeeling.unwell,
        medicationStatus: MedicationCheckStatus.no,
        symptoms: const [
          CheckSymptom(symptomCode: 'chest_pain', displayName: 'Chest discomfort or pain', isUrgent: true),
        ],
        createdAt: now,
        updatedAt: now,
      );
      final alert = EmergencyProtocols.evaluateDailyCheck(check);
      expect(alert, isNotNull);
      expect(alert!.isImmediateEmergency, isTrue);
      expect(alert.headline, contains('Emergency Red-Flag'));
      expect(alert.symptoms, contains('Chest discomfort or pain'));
    });
  });

  group('EmergencyProtocols - Regional Directories', () {
    test('regional numbers directory provides 911, 999, 112, 000', () {
      final numbers = EmergencyRegion.values.map((r) => r.emergencyNumber).toList();
      expect(numbers, containsAll(['911', '999', '112', '000']));
    });

    test('red flag symptoms include life-threatening cardiac and stroke indicators', () {
      expect(EmergencyProtocols.redFlagSymptoms.any((s) => s.contains('Chest')), isTrue);
      expect(EmergencyProtocols.redFlagSymptoms.any((s) => s.contains('breath')), isTrue);
      expect(EmergencyProtocols.redFlagSymptoms.any((s) => s.contains('speech')), isTrue);
    });
  });
}
