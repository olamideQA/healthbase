import 'dart:math' show min;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../db/app_database.dart';
import '../security/security_service.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncEngine(db: db, supabase: sb.Supabase.instance.client);
});

/// Offline-first bidirectional sync engine between local Drift SQLite and remote Supabase.
class SyncEngine {
  SyncEngine({required this.db, required this.supabase});

  final AppDatabase db;
  final sb.SupabaseClient supabase;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// Per-profile push serialization: concurrent writers (e.g. the 5
  /// measurements of one daily check) queue behind each other so parents
  /// (daily checks) always land before children (measurements) and two
  /// pushes never interleave on the same profile.
  final Map<String, Future<void>> _profilePushLocks = {};

  Future<T> _serializedPush<T>(String profileId, Future<T> Function() work) {
    final previous = _profilePushLocks[profileId] ?? Future.value();
    final next = previous.then((_) => work());
    // The chain continues regardless of outcome; callers still observe
    // their own result or error via `next`.
    _profilePushLocks[profileId] = next.then((_) {}, onError: (_) {});
    return next;
  }

  /// Retry bookkeeping lives in the local metadata table (no schema change
  /// needed): `sync_retry_<table>_<rowId>` -> `attempts|nextRetryMs|fatal`.
  static const int _maxBackoffSeconds = 3600;

  String _retryKey(String table, String rowId) => 'sync_retry_${table}_$rowId';

  Future<_RetryState> _readRetry(String table, String rowId) async {
    final row =
        await (db.select(db.localAppMetadataTable)
              ..where((tbl) => tbl.key.equals(_retryKey(table, rowId))))
            .getSingleOrNull();
    if (row == null) return const _RetryState(0, null, false);
    final parts = row.value.split('|');
    if (parts.length != 3) return const _RetryState(0, null, false);
    return _RetryState(
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) != null
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1]))
          : null,
      parts[2] == '1',
    );
  }

  Future<void> _writeRetry(
    String table,
    String rowId, {
    required int attempts,
    required bool fatal,
  }) async {
    final shift = attempts.clamp(0, 5);
    final delaySeconds = min(30 * (1 << shift), _maxBackoffSeconds);
    final nextRetry = DateTime.now().add(
      Duration(seconds: delaySeconds),
    );
    await db
        .into(db.localAppMetadataTable)
        .insertOnConflictUpdate(
          LocalAppMetadataTableCompanion(
            key: Value(_retryKey(table, rowId)),
            value: Value(
              '$attempts|${nextRetry.millisecondsSinceEpoch}|'
              '${fatal ? '1' : '0'}',
            ),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> _clearRetry(String table, String rowId) async {
    await (db.delete(
      db.localAppMetadataTable,
    )..where((tbl) => tbl.key.equals(_retryKey(table, rowId)))).go();
  }

  /// Permanent failures (unique conflict, permission denied) must NOT be
  /// retried forever — they need user/developer attention instead.
  bool _isFatalSyncError(Object e) {
    if (e is sb.PostgrestException) {
      // 23505 unique_violation (e.g. second daily check for the same day),
      // 42501 insufficient_privilege (RLS deny).
      return e.code == '23505' || e.code == '42501';
    }
    return false;
  }

  /// Perform a full push and incremental pull sync for a profile.
  /// Daily checks are pushed before measurements so the remote
  /// `measurements.daily_check_id` foreign key never dangles.
  Future<void> syncProfile(String profileId) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await pushPendingDailyChecks(profileId);
      await pushPendingMeasurements(profileId);
      await pullRemoteDailyChecks(profileId);
      await pullRemoteMeasurements(profileId);
    } catch (e) {
      AppLogger.warning('Sync cycle encountered error for profile: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Push all local daily checks (and their symptoms) marked pending.
  /// `sync_error` rows are retried once their backoff expires; permanent
  /// failures (unique conflict, RLS deny) are left for attention, not looped.
  /// Returns the number of checks marked synced.
  Future<int> pushPendingDailyChecks(String profileId) {
    return _serializedPush(profileId, () async {
      final candidates =
          await (db.select(db.localDailyChecksTable)..where(
                (tbl) =>
                    tbl.profileId.equals(profileId) &
                    (tbl.syncStatus.equals('pending_insert') |
                        tbl.syncStatus.equals('pending_update') |
                        tbl.syncStatus.equals('pending_delete') |
                        tbl.syncStatus.equals('sync_error')),
              ))
              .get();

      final now = DateTime.now();
      final pending = <LocalDailyChecksTableData>[];
      for (final row in candidates) {
        if (row.syncStatus != 'sync_error') {
          pending.add(row);
          continue;
        }
        final retry = await _readRetry('daily_checks', row.id);
        if (!retry.fatal &&
            (retry.nextRetry == null || !retry.nextRetry!.isAfter(now))) {
          pending.add(row);
        }
      }

      if (pending.isEmpty) return 0;

      return _pushDailyCheckRows(profileId, pending);
    });
  }

  Future<int> _pushDailyCheckRows(
    String profileId,
    List<LocalDailyChecksTableData> pending,
  ) async {
    int syncedCount = 0;
    for (final row in pending) {
      try {
        if (row.isDeleted) {
          await supabase.from('daily_checks').delete().eq('id', row.id);
          final symptoms = await (db.select(
            db.localDailyCheckSymptomsTable,
          )..where((tbl) => tbl.dailyCheckId.equals(row.id))).get();
          for (final s in symptoms) {
            await (db.delete(
              db.localDailyCheckSymptomsTable,
            )..where((tbl) => tbl.id.equals(s.id))).go();
          }
        } else {
          final payload = <String, dynamic>{
            'id': row.id,
            'profile_id': row.profileId,
            'check_date': row.checkDate.toIso8601String().split('T').first,
            'feeling': row.feeling,
            'medication_status': row.medicationStatus,
            if (row.notes != null) 'notes': row.notes,
            'is_deleted': false,
          };
          await supabase.from('daily_checks').upsert(payload, onConflict: 'id');

          final symptoms = await (db.select(
            db.localDailyCheckSymptomsTable,
          )..where((tbl) => tbl.dailyCheckId.equals(row.id))).get();
          for (final s in symptoms) {
            await supabase
                .from('daily_check_symptoms')
                .upsert(<String, dynamic>{
                  'id': s.id,
                  'daily_check_id': s.dailyCheckId,
                  'symptom_code': s.symptomCode,
                  'is_urgent': s.isUrgent,
                  if (s.customDescription != null)
                    'custom_description': s.customDescription,
                }, onConflict: 'id');
          }
        }

        await (db.update(
          db.localDailyChecksTable,
        )..where((tbl) => tbl.id.equals(row.id))).write(
          const LocalDailyChecksTableCompanion(syncStatus: Value('synced')),
        );
        await _clearRetry('daily_checks', row.id);
        syncedCount++;
      } catch (e) {
        final fatal = _isFatalSyncError(e);
        final previous = await _readRetry('daily_checks', row.id);
        await _writeRetry(
          'daily_checks',
          row.id,
          attempts: previous.attempts + 1,
          fatal: fatal,
        );
        AppLogger.warning(
          'Failed to push daily check ${row.id} '
          '(attempt ${previous.attempts + 1}${fatal ? ', permanent' : ', will retry'}): $e',
        );
        await (db.update(
          db.localDailyChecksTable,
        )..where((tbl) => tbl.id.equals(row.id))).write(
          const LocalDailyChecksTableCompanion(syncStatus: Value('sync_error')),
        );
      }
    }
    return syncedCount;
  }

  /// Pull remote daily checks (and symptoms) updated since last cursor.
  Future<int> pullRemoteDailyChecks(String profileId) async {
    const pageSize = 200;
    final metaKey = 'last_sync_dailycheck_$profileId';
    final lastSyncRow = await (db.select(
      db.localAppMetadataTable,
    )..where((tbl) => tbl.key.equals(metaKey))).getSingleOrNull();

    final lastSyncTime = lastSyncRow != null
        ? DateTime.tryParse(lastSyncRow.value)?.toUtc().toIso8601String()
        : null;

    var query = supabase
        .from('daily_checks')
        .select()
        .eq('profile_id', profileId);

    if (lastSyncTime != null) {
      query = query.gt('updated_at', lastSyncTime);
    }

    final remoteRows = await query
        .order('updated_at', ascending: true)
        .limit(pageSize);

    DateTime? latestUpdated;
    int pulledCount = 0;

    for (final json in remoteRows as List) {
      final map = json as Map<String, dynamic>;
      final updatedAt = DateTime.parse(map['updated_at'] as String);
      if (latestUpdated == null || updatedAt.isAfter(latestUpdated)) {
        latestUpdated = updatedAt;
      }
      final checkId = map['id'] as String;

      await db
          .into(db.localDailyChecksTable)
          .insertOnConflictUpdate(
            LocalDailyChecksTableCompanion(
              id: Value(checkId),
              profileId: Value(map['profile_id'] as String),
              checkDate: Value(DateTime.parse(map['check_date'] as String)),
              feeling: Value(map['feeling'] as String),
              medicationStatus: Value(map['medication_status'] as String),
              notes: Value(map['notes'] as String?),
              isDeleted: Value(map['is_deleted'] as bool? ?? false),
              syncStatus: const Value('synced'),
              version: Value(map['version'] as int? ?? 1),
              createdAt: Value(DateTime.parse(map['created_at'] as String)),
              updatedAt: Value(updatedAt),
            ),
          );

      final symptomRows = await supabase
          .from('daily_check_symptoms')
          .select()
          .eq('daily_check_id', checkId);
      for (final sJson in symptomRows as List) {
        final s = sJson as Map<String, dynamic>;
        await db
            .into(db.localDailyCheckSymptomsTable)
            .insertOnConflictUpdate(
              LocalDailyCheckSymptomsTableCompanion(
                id: Value(s['id'] as String),
                dailyCheckId: Value(s['daily_check_id'] as String),
                symptomCode: Value(s['symptom_code'] as String),
                isUrgent: Value(s['is_urgent'] as bool? ?? false),
                customDescription: Value(s['custom_description'] as String?),
                createdAt: Value(
                  s['created_at'] != null
                      ? DateTime.parse(s['created_at'] as String)
                      : updatedAt,
                ),
              ),
            );
      }
      pulledCount++;
    }

    if (latestUpdated != null) {
      await db
          .into(db.localAppMetadataTable)
          .insertOnConflictUpdate(
            LocalAppMetadataTableCompanion(
              key: Value(metaKey),
              value: Value(latestUpdated.toIso8601String()),
              updatedAt: Value(DateTime.now()),
            ),
          );
    }

    return pulledCount;
  }

  /// Push all local measurements marked pending to Supabase via idempotent
  /// upsert. Retries `sync_error` rows with backoff; permanent failures are
  /// recorded, not looped. Serialized per profile so a daily check's parent
  /// row is pushed before its measurement children.
  Future<int> pushPendingMeasurements(String profileId) {
    return _serializedPush(profileId, () async {
      final candidates =
          await (db.select(db.localMeasurementsTable)..where(
                (tbl) =>
                    tbl.profileId.equals(profileId) &
                    (tbl.syncStatus.equals('pending_insert') |
                        tbl.syncStatus.equals('pending_update') |
                        tbl.syncStatus.equals('pending_delete') |
                        tbl.syncStatus.equals('sync_error')),
              ))
              .get();

      final now = DateTime.now();
      final pending = <LocalMeasurementsTableData>[];
      for (final row in candidates) {
        if (row.syncStatus != 'sync_error') {
          pending.add(row);
          continue;
        }
        final retry = await _readRetry('measurements', row.id);
        if (!retry.fatal &&
            (retry.nextRetry == null || !retry.nextRetry!.isAfter(now))) {
          pending.add(row);
        }
      }

      if (pending.isEmpty) return 0;

      int syncedCount = 0;
      for (final row in pending) {
        try {
          final payload = <String, dynamic>{
            'id': row.id,
            'profile_id': row.profileId,
            'type': row.type,
            if (row.heartRateBpm != null) 'heart_rate_bpm': row.heartRateBpm,
            if (row.systolicMmhg != null) 'systolic_mmhg': row.systolicMmhg,
            if (row.diastolicMmhg != null) 'diastolic_mmhg': row.diastolicMmhg,
            if (row.pulseBpm != null) 'pulse_bpm': row.pulseBpm,
            if (row.temperatureCelsius != null)
              'temperature_celsius': row.temperatureCelsius,
            if (row.weightKg != null) 'weight_kg': row.weightKg,
            if (row.glucoseMmolL != null) 'glucose_mmol_l': row.glucoseMmolL,
            'source': row.source,
            'provenance': row.provenance,
            'recorded_at': row.recordedAt.toUtc().toIso8601String(),
            'recorded_utc_offset': row.recordedUtcOffset,
            if (row.notes != null) 'notes': row.notes,
            if (row.dailyCheckId != null) 'daily_check_id': row.dailyCheckId,
            'is_deleted': row.isDeleted,
          };

          await supabase.from('measurements').upsert(payload, onConflict: 'id');

          // Mark as synced locally
          await (db.update(
            db.localMeasurementsTable,
          )..where((tbl) => tbl.id.equals(row.id))).write(
            const LocalMeasurementsTableCompanion(syncStatus: Value('synced')),
          );
          await _clearRetry('measurements', row.id);
          syncedCount++;
        } catch (e) {
          final fatal = _isFatalSyncError(e);
          final previous = await _readRetry('measurements', row.id);
          await _writeRetry(
            'measurements',
            row.id,
            attempts: previous.attempts + 1,
            fatal: fatal,
          );
          AppLogger.warning(
            'Failed to push measurement ${row.id} '
            '(attempt ${previous.attempts + 1}${fatal ? ', permanent' : ', will retry'}): $e',
          );
          await (db.update(
            db.localMeasurementsTable,
          )..where((tbl) => tbl.id.equals(row.id))).write(
            const LocalMeasurementsTableCompanion(
              syncStatus: Value('sync_error'),
            ),
          );
        }
      }
      return syncedCount;
    });
  }

  /// Pull remote measurements updated since last sync cursor.
  Future<int> pullRemoteMeasurements(String profileId) async {
    final metaKey = 'last_sync_meas_$profileId';
    final lastSyncRow = await (db.select(
      db.localAppMetadataTable,
    )..where((tbl) => tbl.key.equals(metaKey))).getSingleOrNull();

    final lastSyncTime = lastSyncRow != null
        ? DateTime.tryParse(lastSyncRow.value)?.toUtc().toIso8601String()
        : null;

    var query = supabase
        .from('measurements')
        .select()
        .eq('profile_id', profileId);

    if (lastSyncTime != null) {
      query = query.gt('updated_at', lastSyncTime);
    }

    final remoteRows = await query
        .order('updated_at', ascending: true)
        .limit(200);

    DateTime? latestUpdated;
    int pulledCount = 0;

    for (final json in remoteRows as List) {
      final map = json as Map<String, dynamic>;
      final updatedAt = DateTime.parse(map['updated_at'] as String);
      if (latestUpdated == null || updatedAt.isAfter(latestUpdated)) {
        latestUpdated = updatedAt;
      }

      await db
          .into(db.localMeasurementsTable)
          .insertOnConflictUpdate(
            LocalMeasurementsTableCompanion(
              id: Value(map['id'] as String),
              profileId: Value(map['profile_id'] as String),
              type: Value(map['type'] as String),
              heartRateBpm: Value((map['heart_rate_bpm'] as num?)?.toDouble()),
              systolicMmhg: Value((map['systolic_mmhg'] as num?)?.toDouble()),
              diastolicMmhg: Value((map['diastolic_mmhg'] as num?)?.toDouble()),
              pulseBpm: Value((map['pulse_bpm'] as num?)?.toDouble()),
              temperatureCelsius: Value(
                (map['temperature_celsius'] as num?)?.toDouble(),
              ),
              weightKg: Value((map['weight_kg'] as num?)?.toDouble()),
              glucoseMmolL: Value((map['glucose_mmol_l'] as num?)?.toDouble()),
              source: Value(map['source'] as String? ?? 'manual'),
              provenance: Value(
                map['provenance'] as String? ?? 'manually_entered',
              ),
              recordedAt: Value(DateTime.parse(map['recorded_at'] as String)),
              recordedUtcOffset: Value(map['recorded_utc_offset'] as int? ?? 0),
              notes: Value(map['notes'] as String?),
              dailyCheckId: Value(map['daily_check_id'] as String?),
              isDeleted: Value(map['is_deleted'] as bool? ?? false),
              syncStatus: const Value('synced'),
              version: Value(map['version'] as int? ?? 1),
              createdAt: Value(DateTime.parse(map['created_at'] as String)),
              updatedAt: Value(updatedAt),
            ),
          );
      pulledCount++;
    }

    if (latestUpdated != null) {
      await db
          .into(db.localAppMetadataTable)
          .insertOnConflictUpdate(
            LocalAppMetadataTableCompanion(
              key: Value(metaKey),
              value: Value(latestUpdated.toIso8601String()),
              updatedAt: Value(DateTime.now()),
            ),
          );
    }

    return pulledCount;
  }
}

/// Retry bookkeeping for one failed row: how many attempts so far, when
/// the next retry is due (`null` = immediately), and whether the failure
/// is permanent (never retry, needs attention instead).
class _RetryState {
  const _RetryState(this.attempts, this.nextRetry, this.fatal);

  final int attempts;
  final DateTime? nextRetry;
  final bool fatal;
}
