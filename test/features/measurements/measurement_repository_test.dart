import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/db/app_database.dart';
import 'package:healthbase/core/errors/failures.dart';
import 'package:healthbase/core/sync/sync_engine.dart';
import 'package:healthbase/features/measurements/data/measurement_repository.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  late AppDatabase db;
  late MockSyncEngine mockSyncEngine;
  late MeasurementRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockSyncEngine = MockSyncEngine();
    when(() => mockSyncEngine.pushPendingMeasurements(any()))
        .thenAnswer((_) async => 1);
    when(() => mockSyncEngine.syncProfile(any())).thenAnswer((_) async {});

    repository = MeasurementRepository(db: db, syncEngine: mockSyncEngine);
  });

  tearDown(() async {
    await db.close();
  });

  group('MeasurementRepository Unit Tests', () {
    test('createMeasurement validates heart rate plausibility bounds', () async {
      final invalidLow = Measurement(
        id: '1',
        profileId: 'p1',
        type: MeasurementType.heartRate,
        heartRateBpm: 20.0, // below 25
        recordedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => repository.createMeasurement(invalidLow),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          contains('between 25 and 260 bpm'),
        )),
      );

      final invalidHigh = Measurement(
        id: '2',
        profileId: 'p1',
        type: MeasurementType.heartRate,
        heartRateBpm: 280.0, // above 250
        recordedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => repository.createMeasurement(invalidHigh),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          contains('between 25 and 260 bpm'),
        )),
      );
    });

    test('createMeasurement validates blood pressure systolic higher than diastolic', () async {
      final invalidBp = Measurement(
        id: 'bp1',
        profileId: 'p1',
        type: MeasurementType.bloodPressure,
        systolicMmhg: 80.0,
        diastolicMmhg: 90.0, // systolic <= diastolic
        recordedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => repository.createMeasurement(invalidBp),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          contains('Systolic pressure must be higher than diastolic pressure'),
        )),
      );
    });

    test('createMeasurement persists locally with pending_insert syncStatus', () async {
      final valid = Measurement(
        id: 'valid-hr',
        profileId: 'p1',
        type: MeasurementType.heartRate,
        heartRateBpm: 74.0,
        recordedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await repository.createMeasurement(valid);
      expect(result.id, 'valid-hr');
      expect(result.syncStatus, SyncStatus.pendingInsert);

      // Verify row in local Drift DB
      final localRows = await repository.getMeasurements(profileId: 'p1');
      expect(localRows.length, 1);
      expect(localRows.first.heartRateBpm, 74.0);
      expect(localRows.first.syncStatus, SyncStatus.pendingInsert);

      verify(() => mockSyncEngine.pushPendingMeasurements('p1')).called(1);
    });

    test('updateMeasurement updates local row and marks pending_update', () async {
      final initial = Measurement(
        id: 'upd-1',
        profileId: 'p1',
        type: MeasurementType.weight,
        weightKg: 70.0,
        recordedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createMeasurement(initial);

      final updated = initial.copyWith(weightKg: 71.5);
      final result = await repository.updateMeasurement(updated);

      expect(result.weightKg, 71.5);
      expect(result.syncStatus, SyncStatus.pendingUpdate);

      final rows = await repository.getMeasurements(profileId: 'p1');
      expect(rows.first.weightKg, 71.5);
      expect(rows.first.syncStatus, SyncStatus.pendingUpdate);
    });

    test('deleteMeasurement soft deletes and excludes from active list', () async {
      final item = Measurement(
        id: 'del-1',
        profileId: 'p1',
        type: MeasurementType.temperature,
        temperatureCelsius: 36.8,
        recordedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createMeasurement(item);
      expect((await repository.getMeasurements(profileId: 'p1')).length, 1);

      await repository.deleteMeasurement('del-1', 'p1');
      expect((await repository.getMeasurements(profileId: 'p1')).length, 0);
    });

    test('watchMeasurements emits reactive updates as rows are added', () async {
      final stream = repository.watchMeasurements(profileId: 'p1');

      final expectation = expectLater(
        stream,
        emitsThrough(hasLength(1)),
      );

      await repository.createMeasurement(Measurement(
        id: 'stream-1',
        profileId: 'p1',
        type: MeasurementType.heartRate,
        heartRateBpm: 80.0,
        recordedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await expectation;
    });
  });
}
