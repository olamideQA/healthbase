import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/db/app_database.dart';
import 'package:healthbase/core/sync/sync_engine.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class MockSupabaseClient extends Mock implements sb.SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock
    implements sb.SupabaseQueryBuilder {}

/// Hand-rolled fake for the `select().eq().order().limit()` read chain:
/// every step returns itself, awaiting resolves to [rows].
class FakeSelectChain extends Fake
    implements sb.PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  FakeSelectChain(this.rows);
  final List<Map<String, dynamic>> rows;

  @override
  sb.PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) => this;

  @override
  sb.PostgrestFilterBuilder<List<Map<String, dynamic>>> gt(
    String column,
    Object value,
  ) => this;

  @override
  sb.PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) => this;

  @override
  sb.PostgrestTransformBuilder<List<Map<String, dynamic>>> limit(
    int count, {
    String? referencedTable,
  }) => this;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) {
    return Future.value(rows).then(onValue, onError: onError);
  }
}

class FakePostgrestFilterBuilder<T> extends Fake
    implements sb.PostgrestFilterBuilder<T> {
  FakePostgrestFilterBuilder(this._future);
  final Future<T> _future;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
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

    when(
      () => mockSupabase.from('measurements'),
    ).thenAnswer((_) => mockQueryBuilder);

    syncEngine = SyncEngine(db: db, supabase: mockSupabase);
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncEngine Unit Tests', () {
    test(
      'pushPendingMeasurements pushes pending rows to Supabase and marks them synced',
      () async {
        // Seed a local measurement with pending_insert status
        await db
            .into(db.localMeasurementsTable)
            .insert(
              LocalMeasurementsTableCompanion.insert(
                id: 'local-sync-1',
                profileId: 'p1',
                type: 'heart_rate',
                heartRateBpm: const drift.Value(75.0),
                recordedAt: DateTime.now(),
                syncStatus: const drift.Value('pending_insert'),
              ),
            );

        when(() => mockQueryBuilder.upsert(any(), onConflict: 'id')).thenAnswer(
          (_) => FakePostgrestFilterBuilder<dynamic>(Future.value([])),
        );

        final syncedCount = await syncEngine.pushPendingMeasurements('p1');
        expect(syncedCount, 1);

        // Verify row is now marked synced in local Drift SQLite
        final row = await (db.select(
          db.localMeasurementsTable,
        )..where((tbl) => tbl.id.equals('local-sync-1'))).getSingle();

        expect(row.syncStatus, 'synced');
        verify(
          () => mockQueryBuilder.upsert(any(), onConflict: 'id'),
        ).called(1);
      },
    );

    test(
      'pushPendingDailyChecks pushes checks + symptoms before measurements',
      () async {
        await db
            .into(db.localDailyChecksTable)
            .insert(
              LocalDailyChecksTableCompanion.insert(
                id: 'local-check-1',
                profileId: 'p1',
                checkDate: DateTime.now(),
                feeling: 'good',
                medicationStatus: 'yes',
                syncStatus: const drift.Value('pending_insert'),
              ),
            );
        await db
            .into(db.localDailyCheckSymptomsTable)
            .insert(
              LocalDailyCheckSymptomsTableCompanion.insert(
                id: 'local-sym-1',
                dailyCheckId: 'local-check-1',
                symptomCode: 'headache',
              ),
            );
        await db
            .into(db.localDailyCheckSymptomsTable)
            .insert(
              LocalDailyCheckSymptomsTableCompanion.insert(
                id: 'local-sym-2',
                dailyCheckId: 'local-check-1',
                symptomCode: 'other',
                customDescription: const drift.Value('Mild ear pressure'),
              ),
            );

        final mockChecksBuilder = MockSupabaseQueryBuilder();
        final mockSymptomsBuilder = MockSupabaseQueryBuilder();
        when(
          () => mockSupabase.from('daily_checks'),
        ).thenAnswer((_) => mockChecksBuilder);
        when(
          () => mockSupabase.from('daily_check_symptoms'),
        ).thenAnswer((_) => mockSymptomsBuilder);
        when(
          () => mockChecksBuilder.upsert(any(), onConflict: 'id'),
        ).thenAnswer(
          (_) => FakePostgrestFilterBuilder<dynamic>(Future.value([])),
        );
        when(
          () => mockSymptomsBuilder.upsert(any(), onConflict: 'id'),
        ).thenAnswer(
          (_) => FakePostgrestFilterBuilder<dynamic>(Future.value([])),
        );

        final syncedCount = await syncEngine.pushPendingDailyChecks('p1');
        expect(syncedCount, 1);

        final row = await (db.select(
          db.localDailyChecksTable,
        )..where((tbl) => tbl.id.equals('local-check-1'))).getSingle();
        expect(row.syncStatus, 'synced');
        verify(
          () => mockChecksBuilder.upsert(any(), onConflict: 'id'),
        ).called(1);
        verify(
          () => mockSymptomsBuilder.upsert(any(), onConflict: 'id'),
        ).called(2);
      },
    );

    test(
      'pushPendingMeasurements retries sync_error rows after backoff expires',
      () async {
        await db
            .into(db.localMeasurementsTable)
            .insert(
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
            Future.error(Exception('Network disconnect')),
          ),
        );

        expect(await syncEngine.pushPendingMeasurements('p1'), 0);
        var row = await (db.select(
          db.localMeasurementsTable,
        )..where((tbl) => tbl.id.equals('m-retry-1'))).getSingle();
        expect(row.syncStatus, 'sync_error');

        // Immediate retry is skipped while backoff is pending.
        expect(await syncEngine.pushPendingMeasurements('p1'), 0);
        verify(
          () => mockQueryBuilder.upsert(any(), onConflict: 'id'),
        ).called(1);

        // Simulate backoff expiry, then succeed.
        final past = DateTime.now()
            .subtract(const Duration(hours: 2))
            .millisecondsSinceEpoch;
        await (db.update(db.localAppMetadataTable)..where(
              (tbl) => tbl.key.equals('sync_retry_measurements_m-retry-1'),
            ))
            .write(
              LocalAppMetadataTableCompanion(value: drift.Value('1|$past|0')),
            );
        when(() => mockQueryBuilder.upsert(any(), onConflict: 'id')).thenAnswer(
          (_) => FakePostgrestFilterBuilder<dynamic>(Future.value([])),
        );

        expect(await syncEngine.pushPendingMeasurements('p1'), 1);
        row = await (db.select(
          db.localMeasurementsTable,
        )..where((tbl) => tbl.id.equals('m-retry-1'))).getSingle();
        expect(row.syncStatus, 'synced');
      },
    );

    test('pushPendingMeasurements does not retry permanent failures', () async {
      await db
          .into(db.localMeasurementsTable)
          .insert(
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
        (_) => FakePostgrestFilterBuilder<dynamic>(
          Future.error(
            const sb.PostgrestException(
              message: 'duplicate key value',
              code: '23505',
            ),
          ),
        ),
      );

      expect(await syncEngine.pushPendingMeasurements('p1'), 0);

      // Even after backoff would expire, fatal rows are never retried.
      final past = DateTime.now()
          .subtract(const Duration(hours: 2))
          .millisecondsSinceEpoch;
      await (db.update(db.localAppMetadataTable)..where(
            (tbl) => tbl.key.equals('sync_retry_measurements_m-fatal-1'),
          ))
          .write(
            LocalAppMetadataTableCompanion(value: drift.Value('1|$past|1')),
          );
      expect(await syncEngine.pushPendingMeasurements('p1'), 0);
      verify(() => mockQueryBuilder.upsert(any(), onConflict: 'id')).called(1);
    });

    test('concurrent pushes for one profile are serialized', () async {
      await db
          .into(db.localMeasurementsTable)
          .insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'm-conc-1',
              profileId: 'p1',
              type: 'heart_rate',
              heartRateBpm: const drift.Value(70.0),
              recordedAt: DateTime.now(),
              syncStatus: const drift.Value('pending_insert'),
            ),
          );
      await db
          .into(db.localMeasurementsTable)
          .insert(
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
          Future.delayed(const Duration(milliseconds: 20), () => []),
        ),
      );

      final results = await Future.wait([
        syncEngine.pushPendingMeasurements('p1'),
        syncEngine.pushPendingMeasurements('p1'),
      ]);
      expect(results.reduce((a, b) => a + b), 2);
      verify(() => mockQueryBuilder.upsert(any(), onConflict: 'id')).called(2);
    });

    test(
      'pushPendingMeasurements sets sync_error on remote failure without crashing',
      () async {
        await db
            .into(db.localMeasurementsTable)
            .insert(
              LocalMeasurementsTableCompanion.insert(
                id: 'local-err-1',
                profileId: 'p1',
                type: 'heart_rate',
                heartRateBpm: const drift.Value(85.0),
                recordedAt: DateTime.now(),
                syncStatus: const drift.Value('pending_insert'),
              ),
            );

        when(() => mockQueryBuilder.upsert(any(), onConflict: 'id')).thenAnswer(
          (_) => FakePostgrestFilterBuilder<dynamic>(
            Future.error(Exception('Network disconnect')),
          ),
        );

        final syncedCount = await syncEngine.pushPendingMeasurements('p1');
        expect(syncedCount, 0);

        final row = await (db.select(
          db.localMeasurementsTable,
        )..where((tbl) => tbl.id.equals('local-err-1'))).getSingle();

        expect(row.syncStatus, 'sync_error');
      },
    );
  });

  group('SyncEngine medication sync', () {
    late MockSupabaseQueryBuilder mockMedsBuilder;
    late MockSupabaseQueryBuilder mockEventsBuilder;

    setUp(() {
      mockMedsBuilder = MockSupabaseQueryBuilder();
      mockEventsBuilder = MockSupabaseQueryBuilder();
      when(
        () => mockSupabase.from('medications'),
      ).thenAnswer((_) => mockMedsBuilder);
      when(
        () => mockSupabase.from('medication_events'),
      ).thenAnswer((_) => mockEventsBuilder);
      when(() => mockMedsBuilder.upsert(any(), onConflict: 'id')).thenAnswer(
        (_) => FakePostgrestFilterBuilder<dynamic>(Future.value([])),
      );
      when(() => mockEventsBuilder.upsert(any(), onConflict: 'id')).thenAnswer(
        (_) => FakePostgrestFilterBuilder<dynamic>(Future.value([])),
      );
    });

    Future<void> seedMedication({
      String id = 'med-1',
      String status = 'pending_insert',
      bool deleted = false,
    }) {
      return db
          .into(db.localMedicationsTable)
          .insert(
            LocalMedicationsTableCompanion.insert(
              id: id,
              profileId: 'p1',
              name: 'Lisinopril',
              dosage: '10 mg',
              frequency: 'daily',
              startDate: DateTime(2026, 1, 1),
              isDeleted: drift.Value(deleted),
              syncStatus: drift.Value(status),
            ),
          );
    }

    test('pushes medication + event, marks synced, drains outbox', () async {
      await seedMedication();
      await db
          .into(db.localMedicationEventsTable)
          .insert(
            LocalMedicationEventsTableCompanion.insert(
              id: 'evt-1',
              profileId: 'p1',
              medicationId: 'med-1',
              scheduledTime: DateTime.now(),
              status: 'taken',
              syncStatus: const drift.Value('pending_insert'),
            ),
          );
      await db
          .into(db.syncOutboxTable)
          .insert(
            SyncOutboxTableCompanion.insert(
              id: 'ob-1',
              entityType: 'medication',
              entityId: 'med-1',
              action: 'create',
              payloadJson: '{}',
            ),
          );

      expect(await syncEngine.pushPendingMedications('p1'), 2);

      final med = await (db.select(
        db.localMedicationsTable,
      )..where((tbl) => tbl.id.equals('med-1'))).getSingle();
      expect(med.syncStatus, 'synced');
      final evt = await (db.select(
        db.localMedicationEventsTable,
      )..where((tbl) => tbl.id.equals('evt-1'))).getSingle();
      expect(evt.syncStatus, 'synced');
      final outbox = await db.select(db.syncOutboxTable).get();
      expect(outbox.where((o) => o.entityId == 'med-1'), isEmpty);
      verify(() => mockMedsBuilder.upsert(any(), onConflict: 'id')).called(1);
      verify(() => mockEventsBuilder.upsert(any(), onConflict: 'id')).called(1);
    });

    test('failed medication push is retried, not lost', () async {
      await seedMedication(id: 'med-retry');
      when(() => mockMedsBuilder.upsert(any(), onConflict: 'id')).thenAnswer(
        (_) => FakePostgrestFilterBuilder<dynamic>(
          Future.error(Exception('offline')),
        ),
      );

      expect(await syncEngine.pushPendingMedications('p1'), 0);
      final row = await (db.select(
        db.localMedicationsTable,
      )..where((tbl) => tbl.id.equals('med-retry'))).getSingle();
      expect(row.syncStatus, 'sync_error');
      // Backoff pending: immediate retry skips the row.
      expect(await syncEngine.pushPendingMedications('p1'), 0);
      verify(() => mockMedsBuilder.upsert(any(), onConflict: 'id')).called(1);
    });

    test('pulls remote medications into the local mirror', () async {
      final now = DateTime.now().toUtc();
      when(() => mockEventsBuilder.select()).thenAnswer(
        (_) => FakeSelectChain([]),
      );
      // thenAnswer (not thenReturn): the chain is Future-like, which
      // mocktail refuses to return from thenReturn.
      when(() => mockMedsBuilder.select()).thenAnswer(
        (_) => FakeSelectChain([
          {
            'id': 'med-remote-1',
            'profile_id': 'p1',
            'name': 'Metformin',
            'dosage': '500 mg',
            'frequency': 'twice_daily',
            'start_date': now.toIso8601String(),
            'end_date': null,
            'reminder_time': '08:00',
            'notes': null,
            'is_active': true,
            'is_deleted': false,
            'version': 3,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          },
        ]),
      );

      expect(await syncEngine.pullRemoteMedications('p1'), 1);

      final row = await (db.select(
        db.localMedicationsTable,
      )..where((tbl) => tbl.id.equals('med-remote-1'))).getSingle();
      expect(row.name, 'Metformin');
      expect(row.version, 3);
      expect(row.syncStatus, 'synced');
    });
  });

  group('SyncEngine family sharing sync', () {
    late MockSupabaseQueryBuilder mockProfilesBuilder;
    late MockSupabaseQueryBuilder mockAccessBuilder;

    setUp(() {
      mockProfilesBuilder = MockSupabaseQueryBuilder();
      mockAccessBuilder = MockSupabaseQueryBuilder();
      when(() => mockSupabase.from('health_profiles'))
          .thenAnswer((_) => mockProfilesBuilder);
      when(() => mockSupabase.from('profile_access'))
          .thenAnswer((_) => mockAccessBuilder);
      when(() => mockProfilesBuilder.upsert(any(), onConflict: 'id'))
          .thenAnswer((_) =>
              FakePostgrestFilterBuilder<dynamic>(Future.value([])));
    });

    test('pushes owned family profiles and drains the outbox', () async {
      await db.into(db.localFamilyProfilesTable).insert(
            LocalFamilyProfilesTableCompanion.insert(
              id: 'fam-1',
              ownerAccountId: 'user_1',
              isSelf: const drift.Value(false),
              displayName: 'Mum',
              relationshipLabel: const drift.Value('Mother'),
              syncStatus: const drift.Value('pending_insert'),
            ),
          );
      await db.into(db.syncOutboxTable).insert(
            SyncOutboxTableCompanion.insert(
              id: 'ob-fam-1',
              entityType: 'health_profile',
              entityId: 'fam-1',
              action: 'create',
              payloadJson: '{}',
            ),
          );

      expect(await syncEngine.pushPendingFamilyProfiles('user_1'), 1);

      final row = await (db.select(db.localFamilyProfilesTable)
            ..where((tbl) => tbl.id.equals('fam-1')))
          .getSingle();
      expect(row.syncStatus, 'synced');
      final outbox = await db.select(db.syncOutboxTable).get();
      expect(outbox.where((o) => o.entityId == 'fam-1'), isEmpty);
      verify(() => mockProfilesBuilder.upsert(any(), onConflict: 'id'))
          .called(1);
    });

    test('never pushes self profiles (server owns those)', () async {
      await db.into(db.localFamilyProfilesTable).insert(
            LocalFamilyProfilesTableCompanion.insert(
              id: 'self-1',
              ownerAccountId: 'user_1',
              isSelf: const drift.Value(true),
              displayName: 'Me',
              syncStatus: const drift.Value('pending_insert'),
            ),
          );

      expect(await syncEngine.pushPendingFamilyProfiles('user_1'), 0);
      verifyNever(
          () => mockProfilesBuilder.upsert(any(), onConflict: 'id'));
    });

    test('pulls shared profiles and access grants', () async {
      final now = DateTime.now().toUtc();
      when(() => mockProfilesBuilder.select()).thenAnswer(
        (_) => FakeSelectChain([
          {
            'id': 'fam-shared-1',
            'owner_account_id': 'user_2',
            'is_self': false,
            'display_name': 'Dad',
            'relationship_label': 'Father',
            'is_managed': true,
            'date_of_birth': null,
            'sex': null,
            'height_cm': null,
            'weight_kg': null,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          },
        ]),
      );
      when(() => mockAccessBuilder.select()).thenAnswer(
        (_) => FakeSelectChain([
          {
            'id': 'grant-1',
            'profile_id': 'fam-shared-1',
            'grantee_account_id': 'user_1',
            'role': 'view',
            'status': 'active',
            'granted_by': 'user_2',
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          },
        ]),
      );

      expect(await syncEngine.pullFamilySharing(), 2);

      final profile = await (db.select(db.localFamilyProfilesTable)
            ..where((tbl) => tbl.id.equals('fam-shared-1')))
          .getSingle();
      expect(profile.displayName, 'Dad');
      expect(profile.syncStatus, 'synced');
      final grant = await (db.select(db.localProfileAccessTable)
            ..where((tbl) => tbl.id.equals('grant-1')))
          .getSingle();
      expect(grant.role, 'view');
      expect(grant.status, 'active');
    });
  });
}
