import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/safety/safety_boundaries.dart';
import '../../../../core/sync/sync_engine.dart';
import '../domain/models/measurement.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  return MeasurementRepository(db: db, syncEngine: syncEngine);
});

final measurementsStreamProvider =
    StreamProvider.family<List<Measurement>, String>((ref, profileId) {
  final repo = ref.watch(measurementRepositoryProvider);
  return repo.watchMeasurements(profileId: profileId);
});

class MeasurementRepository {
  MeasurementRepository({
    required this.db,
    required this.syncEngine,
  });

  final AppDatabase db;
  final SyncEngine syncEngine;
  final _uuid = const Uuid();

  /// Reactive stream of measurements from the local encrypted SQLite database.
  Stream<List<Measurement>> watchMeasurements({
    required String profileId,
    MeasurementType? typeFilter,
    int limit = 50,
  }) {
    final query = db.select(db.localMeasurementsTable)
      ..where((tbl) {
        var expr = tbl.profileId.equals(profileId) & tbl.isDeleted.equals(false);
        if (typeFilter != null) {
          expr = expr & tbl.type.equals(typeFilter.toDbValue());
        }
        return expr;
      })
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.recordedAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);

    return query.watch().map((rows) => rows.map(_mapRowToEntity).toList());
  }

  /// Get static list of measurements.
  Future<List<Measurement>> getMeasurements({
    required String profileId,
    MeasurementType? typeFilter,
    int limit = 50,
  }) async {
    final query = db.select(db.localMeasurementsTable)
      ..where((tbl) {
        var expr = tbl.profileId.equals(profileId) & tbl.isDeleted.equals(false);
        if (typeFilter != null) {
          expr = expr & tbl.type.equals(typeFilter.toDbValue());
        }
        return expr;
      })
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.recordedAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);

    final rows = await query.get();
    return rows.map(_mapRowToEntity).toList();
  }

  /// Record a new measurement locally with pending sync status.
  Future<Measurement> createMeasurement(Measurement measurement) async {
    _validateMeasurement(measurement);

    final id = measurement.id.isEmpty ? _uuid.v4() : measurement.id;
    final now = DateTime.now();

    final companion = LocalMeasurementsTableCompanion(
      id: Value(id),
      profileId: Value(measurement.profileId),
      type: Value(measurement.type.toDbValue()),
      heartRateBpm: Value(measurement.heartRateBpm),
      systolicMmhg: Value(measurement.systolicMmhg),
      diastolicMmhg: Value(measurement.diastolicMmhg),
      pulseBpm: Value(measurement.pulseBpm),
      temperatureCelsius: Value(measurement.temperatureCelsius),
      weightKg: Value(measurement.weightKg),
      glucoseMmolL: Value(measurement.glucoseMmolL),
      source: Value(measurement.source.toDbValue()),
      provenance: Value(measurement.provenance.toDbValue()),
      recordedAt: Value(measurement.recordedAt),
      recordedUtcOffset: Value(measurement.recordedUtcOffset),
      notes: Value(measurement.notes),
      dailyCheckId: Value(measurement.dailyCheckId),
      isDeleted: const Value(false),
      syncStatus: const Value('pending_insert'),
      version: const Value(1),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    await db.into(db.localMeasurementsTable).insert(companion);

    // Trigger asynchronous background push (non-blocking)
    syncEngine.pushPendingMeasurements(measurement.profileId).ignore();

    return measurement.copyWith(
      id: id,
      syncStatus: SyncStatus.pendingInsert,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update an existing measurement locally and queue for sync.
  Future<Measurement> updateMeasurement(Measurement measurement) async {
    _validateMeasurement(measurement);
    final now = DateTime.now();

    await (db.update(db.localMeasurementsTable)
          ..where((tbl) => tbl.id.equals(measurement.id)))
        .write(
      LocalMeasurementsTableCompanion(
        heartRateBpm: Value(measurement.heartRateBpm),
        systolicMmhg: Value(measurement.systolicMmhg),
        diastolicMmhg: Value(measurement.diastolicMmhg),
        pulseBpm: Value(measurement.pulseBpm),
        temperatureCelsius: Value(measurement.temperatureCelsius),
        weightKg: Value(measurement.weightKg),
        glucoseMmolL: Value(measurement.glucoseMmolL),
        notes: Value(measurement.notes),
        syncStatus: const Value('pending_update'),
        updatedAt: Value(now),
      ),
    );

    syncEngine.pushPendingMeasurements(measurement.profileId).ignore();

    return measurement.copyWith(
      syncStatus: SyncStatus.pendingUpdate,
      updatedAt: now,
    );
  }

  /// Soft delete a measurement locally and queue for remote tombstone sync.
  Future<void> deleteMeasurement(String id, String profileId) async {
    await (db.update(db.localMeasurementsTable)..where((tbl) => tbl.id.equals(id)))
        .write(
      const LocalMeasurementsTableCompanion(
        isDeleted: Value(true),
        syncStatus: Value('pending_delete'),
      ),
    );

    syncEngine.pushPendingMeasurements(profileId).ignore();
  }

  /// Synchronize the profile measurements with remote Supabase.
  Future<void> syncProfile(String profileId) async {
    await syncEngine.syncProfile(profileId);
  }

  Measurement _mapRowToEntity(LocalMeasurementsTableData row) {
    return Measurement(
      id: row.id,
      profileId: row.profileId,
      type: MeasurementType.fromDbValue(row.type),
      heartRateBpm: row.heartRateBpm,
      systolicMmhg: row.systolicMmhg,
      diastolicMmhg: row.diastolicMmhg,
      pulseBpm: row.pulseBpm,
      temperatureCelsius: row.temperatureCelsius,
      weightKg: row.weightKg,
      glucoseMmolL: row.glucoseMmolL,
      source: MeasurementSource.fromDbValue(row.source),
      provenance: MeasurementProvenance.fromDbValue(row.provenance),
      recordedAt: row.recordedAt,
      recordedUtcOffset: row.recordedUtcOffset,
      notes: row.notes,
      dailyCheckId: row.dailyCheckId,
      isDeleted: row.isDeleted,
      syncStatus: SyncStatus.fromDbValue(row.syncStatus),
      version: row.version,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  void _validateMeasurement(Measurement m) {
    switch (m.type) {
      case MeasurementType.heartRate:
        if (m.heartRateBpm == null) {
          throw const ValidationFailure(message: 'Heart rate is required.');
        }
        if (m.heartRateBpm! < SafetyBoundaries.minHeartRateBpm ||
            m.heartRateBpm! > SafetyBoundaries.maxHeartRateBpm) {
          throw const ValidationFailure(
            message: 'Heart rate must be between 25 and 260 bpm.',
          );
        }
        break;

      case MeasurementType.bloodPressure:
        if (m.systolicMmhg == null || m.diastolicMmhg == null) {
          throw const ValidationFailure(
            message: 'Systolic and diastolic blood pressure are required.',
          );
        }
        if (m.systolicMmhg! < SafetyBoundaries.minSystolicMmHg ||
            m.systolicMmhg! > SafetyBoundaries.maxSystolicMmHg) {
          throw const ValidationFailure(
            message: 'Systolic blood pressure must be between 40 and 300 mmHg.',
          );
        }
        if (m.diastolicMmhg! < SafetyBoundaries.minDiastolicMmHg ||
            m.diastolicMmhg! > SafetyBoundaries.maxDiastolicMmHg) {
          throw const ValidationFailure(
            message: 'Diastolic blood pressure must be between 30 and 200 mmHg.',
          );
        }
        if (m.systolicMmhg! <= m.diastolicMmhg!) {
          throw const ValidationFailure(
            message: 'Systolic pressure must be higher than diastolic pressure.',
          );
        }
        if (m.pulseBpm != null) {
          if (m.pulseBpm! < SafetyBoundaries.minHeartRateBpm ||
              m.pulseBpm! > SafetyBoundaries.maxHeartRateBpm) {
            throw const ValidationFailure(
              message: 'Pulse must be between 25 and 250 bpm.',
            );
          }
        }
        break;

      case MeasurementType.temperature:
        if (m.temperatureCelsius == null) {
          throw const ValidationFailure(message: 'Temperature is required.');
        }
        if (m.temperatureCelsius! < SafetyBoundaries.minTemperatureCelsius ||
            m.temperatureCelsius! > SafetyBoundaries.maxTemperatureCelsius) {
          throw const ValidationFailure(
            message: 'Temperature must be between 30.0°C and 45.0°C.',
          );
        }
        break;

      case MeasurementType.weight:
        if (m.weightKg == null) {
          throw const ValidationFailure(message: 'Weight is required.');
        }
        if (m.weightKg! < SafetyBoundaries.minWeightKg ||
            m.weightKg! > SafetyBoundaries.maxWeightKg) {
          throw const ValidationFailure(
            message: 'Weight must be between 1.0 kg and 400.0 kg.',
          );
        }
        break;

      case MeasurementType.bloodGlucose:
        if (m.glucoseMmolL == null) {
          throw const ValidationFailure(message: 'Blood glucose is required.');
        }
        if (m.glucoseMmolL! < SafetyBoundaries.minGlucoseMmol ||
            m.glucoseMmolL! > SafetyBoundaries.maxGlucoseMmol) {
          throw const ValidationFailure(
            message: 'Blood glucose must be between 0.5 and 45.0 mmol/L.',
          );
        }
        break;
    }

    if (m.notes != null && m.notes!.length > 1000) {
      throw const ValidationFailure(
        message: 'Notes cannot exceed 1000 characters.',
      );
    }
  }
}
