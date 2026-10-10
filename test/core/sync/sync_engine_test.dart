import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/db/app_database.dart';
import 'package:healthbase/core/sync/sync_engine.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class MockSupabaseClient extends Mock implements sb.SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements sb.SupabaseQueryBuilder {}

class FakePostgrestFilterBuilder<T> extends Fake implements sb.PostgrestFilterBuilder<T> {
  FakePostgrestFilterBuilder(this._future);
  final Future<T> _future;

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }
}

void main() {
  late AppDatabase db;
  late MockSupabaseClient mockSupabase;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late SyncEngine syncEngine;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockSupabase = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();

    when(() => mockSupabase.from('measurements')).thenAnswer((_) => mockQueryBuilder);

    syncEngine = SyncEngine(db: db, supabase: mockSupabase);
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncEngine Unit Tests', () {
    test('pushPendingMeasurements pushes pending rows to Supabase and marks them synced', () async {
      // Seed a local measurement with pending_insert status
      await db.into(db.localMeasurementsTable).insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'local-sync-1',
              profileId: 'p1',
              type: 'heart_rate',
              heartRateBpm: const drift.Value(75.0),
              recordedAt: DateTime.now(),
              syncStatus: const drift.Value('pending_insert'),
            ),
          );

      when(() => mockQueryBuilder.upsert(
            any(),
            onConflict: 'id',
          )).thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>(Future.value([])));

      final syncedCount = await syncEngine.pushPendingMeasurements('p1');
      expect(syncedCount, 1);

      // Verify row is now marked synced in local Drift SQLite
      final row = await (db.select(db.localMeasurementsTable)
            ..where((tbl) => tbl.id.equals('local-sync-1')))
          .getSingle();

      expect(row.syncStatus, 'synced');
      verify(() => mockQueryBuilder.upsert(any(), onConflict: 'id')).called(1);
    });

    test('pushPendingDailyChecks pushes checks + symptoms before measurements', () async {
      await db.into(db.localDailyChecksTable).insert(
            LocalDailyChecksTableCompanion.insert(
              id: 'local-check-1',
              profileId: 'p1',
              checkDate: DateTime.now(),
              feeling: 'good',
              medicationStatus: 'yes',
              syncStatus: const drift.Value('pending_insert'),
            ),
          );
      await db.into(db.localDailyCheckSymptomsTable).insert(
            LocalDailyCheckSymptomsTableCompanion.insert(
              id: 'local-sym-1',
              dailyCheckId: 'local-check-1',
              symptomCode: 'headache',
            ),
          );
      await db.into(db.localDailyCheckSymptomsTable).insert(
            LocalDailyCheckSymptomsTableCompanion.insert(
              id: 'local-sym-2',
              dailyCheckId: 'local-check-1',
              symptomCode: 'other',
              customDescription: const drift.Value('Mild ear pressure'),
            ),
          );

      final mockChecksBuilder = MockSupabaseQueryBuilder();
      final mockSymptomsBuilder = MockSupabaseQueryBuilder();
      when(() => mockSupabase.from('daily_checks'))
          .thenAnswer((_) => mockChecksBuilder);
      when(() => mockSupabase.from('daily_check_symptoms'))
          .thenAnswer((_) => mockSymptomsBuilder);
      when(() => mockChecksBuilder.upsert(any(), onConflict: 'id')).thenAnswer(
          (_) => FakePostgrestFilterBuilder<dynamic>(Future.value([])));
      when(() => mockSymptomsBuilder.upsert(any(), onConflict: 'id')).thenAnswer(
          (_) => FakePostgrestFilterBuilder<dynamic>(Future.value([])));

      final syncedCount = await syncEngine.pushPendingDailyChecks('p1');
      expect(syncedCount, 1);

      final row = await (db.select(db.localDailyChecksTable)
            ..where((tbl) => tbl.id.equals('local-check-1')))
          .getSingle();
      expect(row.syncStatus, 'synced');
      verify(() => mockChecksBuilder.upsert(any(), onConflict: 'id')).called(1);
      verify(() => mockSymptomsBuilder.upsert(any(), onConflict: 'id')).called(2);
    });

    test('pushPendingMeasurements retries sync_error rows after backoff expires',
        () async {
      await db.into(db.localMeasurementsTable).insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'm-retry-1',
              profileId: 'p1',
              type: 'heart_rate',
              heartRateBpm: const drift.Value(72.0),
              recordedAt: DateTime.now(),
              syncStatus: const drift.Value('pending_insert'),
            ),
          );

      // First attempt fails (offline).
      when(() => mockQueryBuilder.upsert(any(), onConflict: 'id')).thenAnswer(
          (_) => FakePostgrestFilterBuilder<dynamic>(
              Future.error(Exception('Network disconnect'))));

      expect(await syncEngine.pushPendingMeasurements('p1'), 0);
      var row = await (db.select(db.localMeasurementsTable)
            ..where((tbl) => tbl.id.equals('m-retry-1')))
          .getSingle();
      expect(row.syncStatus, 'sync_error');

      // Immediate retry is skipped while backoff is pending.
      expect(await syncEngine.pushPendingMeasurements('p1'), 0);
      verify(() => mockQueryBuilder.upsert(any(), onConflict: 'id')).called(1);

      // Simulate backoff expiry, then succeed.
      final past = DateTime.now()
          .subtract(const Duration(hours: 2))
          .millisecondsSinceEpoch;
      await (db.update(db.localAppMetadataTable)
            ..where((tbl) =>
                tbl.key.equals('sync_retry_measurements_m-retry-1')))
          .write(LocalAppMetadataTableCompanion(value: drift.Value('1|$past|0')));
      when(() => mockQueryBuilder.upsert(any(), onConflict: 'id')).thenAnswer(
          (_) => FakePostgrestFilterBuilder<dynamic>(Future.value([])));

      expect(await syncEngine.pushPendingMeasurements('p1'), 1);
      row = await (db.select(db.localMeasurementsTable)
            ..where((tbl) => tbl.id.equals('m-retry-1')))
          .getSingle();
      expect(row.syncStatus, 'synced');
    });

    test('pushPendingMeasurements does not retry permanent failures', () async {
      await db.into(db.localMeasurementsTable).insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'm-fatal-1',
              profileId: 'p1',
              type: 'heart_rate',
              heartRateBpm: const drift.Value(72.0),
              recordedAt: DateTime.now(),
              syncStatus: const drift.Value('pending_insert'),
            ),
          );

      when(() => mockQueryBuilder.upsert(any(), onConflict: 'id')).thenAnswer(
          (_) => FakePostgrestFilterBuilder<dynamic>(Future.error(
              const sb.PostgrestException(
                  message: 'duplicate key value', code: '23505'))));

      expect(await syncEngine.pushPendingMeasurements('p1'), 0);

      // Even after backoff would expire, fatal rows are never retried.
      final past = DateTime.now()
          .subtract(const Duration(hours: 2))
          .millisecondsSinceEpoch;
      await (db.update(db.localAppMetadataTable)
            ..where((tbl) => tbl.key.equals('sync_retry_measurements_m-fatal-1')))
          .write(LocalAppMetadataTableCompanion(value: drift.Value('1|$past|1')));
      expect(await syncEngine.pushPendingMeasurements('p1'), 0);
      verify(() => mockQueryBuilder.upsert(any(), onConflict: 'id')).called(1);
    });

    test('concurrent pushes for one profile are serialized', () async {
      await db.into(db.localMeasurementsTable).insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'm-conc-1',
              profileId: 'p1',
              type: 'heart_rate',
              heartRateBpm: const drift.Value(70.0),
              recordedAt: DateTime.now(),
              syncStatus: const drift.Value('pending_insert'),
            ),
          );
      await db.into(db.localMeasurementsTable).insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'm-conc-2',
              profileId: 'p1',
              type: 'heart_rate',
              heartRateBpm: const drift.Value(71.0),
              recordedAt: DateTime.now(),
              syncStatus: const drift.Value('pending_insert'),
            ),
          );

      when(() => mockQueryBuilder.upsert(any(), onConflict: 'id')).thenAnswer(
          (_) => FakePostgrestFilterBuilder<dynamic>(
              Future.delayed(const Duration(milliseconds: 20), () => [])));

      final results = await Future.wait([
        syncEngine.pushPendingMeasurements('p1'),
        syncEngine.pushPendingMeasurements('p1'),
      ]);
      expect(results.reduce((a, b) => a + b), 2);
      verify(() => mockQueryBuilder.upsert(any(), onConflict: 'id')).called(2);
    });

    test('pushPendingMeasurements sets sync_error on remote failure without crashing', () async {
      await db.into(db.localMeasurementsTable).insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'local-err-1',
              profileId: 'p1',
              type: 'heart_rate',
              heartRateBpm: const drift.Value(85.0),
              recordedAt: DateTime.now(),
              syncStatus: const drift.Value('pending_insert'),
            ),
          );

      when(() => mockQueryBuilder.upsert(
            any(),
            onConflict: 'id',
          )).thenAnswer((_) =>
        FakePostgrestFilterBuilder<dynamic>(
          Future.error(Exception('Network disconnect')),
        ),
      );

      final syncedCount = await syncEngine.pushPendingMeasurements('p1');
      expect(syncedCount, 0);

      final row = await (db.select(db.localMeasurementsTable)
            ..where((tbl) => tbl.id.equals('local-err-1')))
          .getSingle();

      expect(row.syncStatus, 'sync_error');
    });
  });
}
