import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';

void main() {
  group('Measurement Model & Formatting Tests', () {
    final recordedAt = DateTime(2026, 10, 8, 14, 30);
    final createdAt = DateTime(2026, 10, 8, 14, 30);
    final updatedAt = DateTime(2026, 10, 8, 14, 30);

    test('Heart Rate formats correctly', () {
      final m = Measurement(
        id: 'm1',
        profileId: 'p1',
        type: MeasurementType.heartRate,
        heartRateBpm: 72.0,
        recordedAt: recordedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(m.formattedPrimaryValue(UnitSystem.metric), '72');
      expect(m.formattedPrimaryValue(UnitSystem.imperial), '72');
      expect(m.unitLabel(UnitSystem.metric), 'bpm');
    });

    test('Blood Pressure formats systolic and diastolic', () {
      final m = Measurement(
        id: 'm2',
        profileId: 'p1',
        type: MeasurementType.bloodPressure,
        systolicMmhg: 120.0,
        diastolicMmhg: 80.0,
        pulseBpm: 68.0,
        recordedAt: recordedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(m.formattedPrimaryValue(UnitSystem.metric), '120/80');
      expect(m.unitLabel(UnitSystem.metric), 'mmHg');
    });

    test('Weight formats in kg and lbs', () {
      final m = Measurement(
        id: 'm3',
        profileId: 'p1',
        type: MeasurementType.weight,
        weightKg: 70.0,
        recordedAt: recordedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(m.formattedPrimaryValue(UnitSystem.metric), '70.0 kg');
      expect(m.formattedPrimaryValue(UnitSystem.imperial), '154.3 lbs');
      expect(m.unitLabel(UnitSystem.metric), 'kg');
      expect(m.unitLabel(UnitSystem.imperial), 'lbs');
    });

    test('Temperature formats in Celsius and Fahrenheit', () {
      final m = Measurement(
        id: 'm4',
        profileId: 'p1',
        type: MeasurementType.temperature,
        temperatureCelsius: 37.0,
        recordedAt: recordedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(m.formattedPrimaryValue(UnitSystem.metric), '37.0 °C');
      expect(m.formattedPrimaryValue(UnitSystem.imperial), '98.6 °F');
      expect(m.unitLabel(UnitSystem.metric), '°C');
      expect(m.unitLabel(UnitSystem.imperial), '°F');
    });

    test('Blood Glucose formats in mmol/L and mg/dL', () {
      final m = Measurement(
        id: 'm5',
        profileId: 'p1',
        type: MeasurementType.bloodGlucose,
        glucoseMmolL: 5.5,
        recordedAt: recordedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(m.formattedPrimaryValue(UnitSystem.metric), '5.5 mmol/L');
      expect(m.formattedPrimaryValue(UnitSystem.imperial), '99 mg/dL');
      expect(m.unitLabel(UnitSystem.metric), 'mmol/L');
      expect(m.unitLabel(UnitSystem.imperial), 'mg/dL');
    });

    test('JSON serialization roundtrips correctly', () {
      final m = Measurement(
        id: 'm-json',
        profileId: 'p-json',
        type: MeasurementType.bloodPressure,
        systolicMmhg: 118.0,
        diastolicMmhg: 78.0,
        pulseBpm: 65.0,
        source: MeasurementSource.manual,
        provenance: MeasurementProvenance.manuallyEntered,
        notes: 'Calm morning reading',
        recordedAt: recordedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final json = m.toRemoteJson();
      expect(json['id'], 'm-json');
      expect(json['type'], 'blood_pressure');
      expect(json['systolic_mmhg'], 118.0);
      expect(json['diastolic_mmhg'], 78.0);
      expect(json['notes'], 'Calm morning reading');

      final deserialized = Measurement.fromJson({
        ...json,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      });

      expect(deserialized.id, m.id);
      expect(deserialized.type, m.type);
      expect(deserialized.systolicMmhg, m.systolicMmhg);
      expect(deserialized.diastolicMmhg, m.diastolicMmhg);
    });
  });
}
