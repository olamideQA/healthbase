import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../measurements/domain/models/measurement.dart';
import '../domain/models/medication.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  return MedicationRepository(db: db, syncEngine: syncEngine);
});

final activeMedicationsStreamProvider =
    StreamProvider.family<List<Medication>, String>((ref, profileId) {
  final repo = ref.watch(medicationRepositoryProvider);
  return repo.watchMedications(profileId: profileId, activeOnly: true);
});

final allMedicationsStreamProvider =
    StreamProvider.family<List<Medication>, String>((ref, profileId) {
  final repo = ref.watch(medicationRepositoryProvider);
  return repo.watchMedications(profileId: profileId, activeOnly: false);
});

final medicationAdherenceProvider =
    FutureProvider.family<MedicationAdherenceStats, ({String profileId, String medicationId})>(
        (ref, arg) {
  final repo = ref.watch(medicationRepositoryProvider);
  return repo.getAdherenceStats(
    profileId: arg.profileId,
    medicationId: arg.medicationId,
  );
});

class MedicationRepository {
  MedicationRepository({required this.db, this._syncEngine});

  final AppDatabase db;
  final SyncEngine? _syncEngine;
  static const _uuid = Uuid();

  /// Best-effort upload trigger after local writes. Failures are durable
  /// (sync_error + backoff) and retried on the next cycle, so callers
  /// never block on the network.
  void _triggerSync(String profileId) {
    final engine = _syncEngine;
    if (engine == null) return;
    engine.syncProfile(profileId).ignore();
  }

  /// Create and persist a new medication.
  Future<String> addMedication({
    required String profileId,
    required String name,
    required String dosage,
    required MedicationFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
    String? reminderTime,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await db.into(db.localMedicationsTable).insert(
          LocalMedicationsTableCompanion.insert(
            id: id,
            profileId: profileId,
            name: name.trim(),
            dosage: dosage.trim(),
            frequency: frequency.dbValue,
            startDate: startDate,
            endDate: Value(endDate),
            reminderTime: Value(reminderTime),
            notes: Value(notes?.trim()),
            isActive: const Value(true),
            isDeleted: const Value(false),
            syncStatus: const Value('pending_insert'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    // Queue sync action (drained by SyncEngine once uploaded; the
    // syncStatus flag is the source of truth for what needs pushing).
    await db.into(db.syncOutboxTable).insert(
          SyncOutboxTableCompanion.insert(
            id: _uuid.v4(),
            entityType: 'medication',
            entityId: id,
            action: 'create',
            payloadJson: jsonEncode({
              'id': id,
              'profile_id': profileId,
              'name': name.trim(),
              'dosage': dosage.trim(),
              'frequency': frequency.dbValue,
              'start_date': startDate.toIso8601String(),
              'end_date': endDate?.toIso8601String(),
              'reminder_time': reminderTime,
              'notes': notes?.trim(),
              'is_active': true,
              'created_at': now.toIso8601String(),
            }),
          ),
        );

    _triggerSync(profileId);
    return id;
  }

  /// Update an existing medication.
  Future<void> updateMedication(Medication medication) async {
    final now = DateTime.now();

    await (db.update(db.localMedicationsTable)..where((tbl) => tbl.id.equals(medication.id))).write(
      LocalMedicationsTableCompanion(
        name: Value(medication.name.trim()),
        dosage: Value(medication.dosage.trim()),
        frequency: Value(medication.frequency.dbValue),
        startDate: Value(medication.startDate),
        endDate: Value(medication.endDate),
        reminderTime: Value(medication.reminderTime),
        notes: Value(medication.notes?.trim()),
        isActive: Value(medication.isActive),
        syncStatus: const Value('pending_update'),
        updatedAt: Value(now),
      ),
    );

    await db.into(db.syncOutboxTable).insert(
          SyncOutboxTableCompanion.insert(
            id: _uuid.v4(),
            entityType: 'medication',
            entityId: medication.id,
            action: 'update',
            payloadJson: jsonEncode({
              'id': medication.id,
              'name': medication.name.trim(),
              'dosage': medication.dosage.trim(),
              'frequency': medication.frequency.dbValue,
              'is_active': medication.isActive,
              'updated_at': now.toIso8601String(),
            }),
          ),
        );

    _triggerSync(medication.profileId);
  }

  /// Soft-delete a medication (tombstone uploads on next sync).
  Future<void> deleteMedication(String id, {String? profileId}) async {
    String? ownerProfileId = profileId;
    if (ownerProfileId == null) {
      final row = await (db.select(db.localMedicationsTable)
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();
      ownerProfileId = row?.profileId;
    }
    await (db.update(db.localMedicationsTable)..where((tbl) => tbl.id.equals(id))).write(
      LocalMedicationsTableCompanion(
        isDeleted: const Value(true),
        isActive: const Value(false),
        syncStatus: const Value('pending_delete'),
        updatedAt: Value(DateTime.now()),
      ),
    );
    if (ownerProfileId != null) _triggerSync(ownerProfileId);
  }

  /// Fetch medications for a profile.
  Future<List<Medication>> getMedications({
    required String profileId,
    bool activeOnly = false,
  }) async {
    final query = db.select(db.localMedicationsTable)
      ..where((tbl) =>
          tbl.profileId.equals(profileId) &
          tbl.isDeleted.equals(false) &
          (activeOnly ? tbl.isActive.equals(true) : const Constant(true)))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
      ]);

    final rows = await query.get();
    return rows.map(_mapRowToMedication).toList();
  }

  /// Watch live updates to medications.
  Stream<List<Medication>> watchMedications({
    required String profileId,
    bool activeOnly = false,
  }) {
    final query = db.select(db.localMedicationsTable)
      ..where((tbl) =>
          tbl.profileId.equals(profileId) &
          tbl.isDeleted.equals(false) &
          (activeOnly ? tbl.isActive.equals(true) : const Constant(true)))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map((rows) => rows.map(_mapRowToMedication).toList());
  }

  /// Record an adherence event (e.g. taken, missed, not_recorded).
  Future<String> recordEvent({
    required String profileId,
    required String medicationId,
    required DateTime scheduledTime,
    required MedicationEventStatus status,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await db.into(db.localMedicationEventsTable).insert(
          LocalMedicationEventsTableCompanion.insert(
            id: id,
            profileId: profileId,
            medicationId: medicationId,
            scheduledTime: scheduledTime,
            recordedAt: Value(status == MedicationEventStatus.notRecorded ? null : now),
            status: status.dbValue,
            notes: Value(notes),
            isDeleted: const Value(false),
            syncStatus: const Value('pending_insert'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    _triggerSync(profileId);
    return id;
  }

  /// Fetch events logged for a specific medication.
  Future<List<MedicationEvent>> getEventsForMedication({
    required String medicationId,
  }) async {
    final query = db.select(db.localMedicationEventsTable)
      ..where((tbl) => tbl.medicationId.equals(medicationId) & tbl.isDeleted.equals(false))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.scheduledTime, mode: OrderingMode.desc),
      ]);

    final rows = await query.get();
    return rows.map(_mapRowToEvent).toList();
  }

  /// Stream events for a specific medication.
  Stream<List<MedicationEvent>> watchEventsForMedication({
    required String medicationId,
  }) {
    final query = db.select(db.localMedicationEventsTable)
      ..where((tbl) => tbl.medicationId.equals(medicationId) & tbl.isDeleted.equals(false))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.scheduledTime, mode: OrderingMode.desc),
      ]);

    return query.watch().map((rows) => rows.map(_mapRowToEvent).toList());
  }

  /// Compute adherence statistics strictly distinguishing taken, missed, and not recorded.
  Future<MedicationAdherenceStats> getAdherenceStats({
    required String profileId,
    required String medicationId,
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();

    // 1. Get medication details to calculate scheduled days
    final medQuery = db.select(db.localMedicationsTable)
      ..where((tbl) => tbl.id.equals(medicationId));
    final medRow = await medQuery.getSingleOrNull();
    if (medRow == null) {
      return const MedicationAdherenceStats(
        scheduledCount: 0,
        takenCount: 0,
        missedCount: 0,
        notRecordedCount: 0,
      );
    }

    final med = _mapRowToMedication(medRow);
    final events = await getEventsForMedication(medicationId: medicationId);

    // Calculate days elapsed between start date and now (or end date if ended)
    final effectiveEnd = med.endDate != null && med.endDate!.isBefore(effectiveNow)
        ? med.endDate!
        : effectiveNow;

    final days = effectiveEnd.difference(med.startDate).inDays.clamp(0, 365) + 1;

    final multiplier = switch (med.frequency) {
      MedicationFrequency.daily => 1,
      MedicationFrequency.twiceDaily => 2,
      MedicationFrequency.threeTimesDaily => 3,
      MedicationFrequency.weekly => (days / 7).ceil().clamp(1, 52),
      MedicationFrequency.asNeeded => 0, // PRN medications have no scheduled count
    };

    final scheduledCount = med.frequency == MedicationFrequency.asNeeded
        ? events.length
        : (days * multiplier).clamp(events.length, 1000);

    return MedicationAdherenceStats.fromEvents(
      scheduledCount: scheduledCount,
      events: events,
    );
  }

  Medication _mapRowToMedication(LocalMedicationsTableData r) {
    return Medication(
      id: r.id,
      profileId: r.profileId,
      name: r.name,
      dosage: r.dosage,
      frequency: MedicationFrequency.fromDbValue(r.frequency),
      startDate: r.startDate,
      endDate: r.endDate,
      reminderTime: r.reminderTime,
      notes: r.notes,
      isActive: r.isActive,
      isDeleted: r.isDeleted,
      syncStatus: SyncStatus.fromDbValue(r.syncStatus),
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }

  MedicationEvent _mapRowToEvent(LocalMedicationEventsTableData r) {
    return MedicationEvent(
      id: r.id,
      profileId: r.profileId,
      medicationId: r.medicationId,
      scheduledTime: r.scheduledTime,
      recordedAt: r.recordedAt,
      status: MedicationEventStatus.fromDbValue(r.status),
      notes: r.notes,
      syncStatus: SyncStatus.fromDbValue(r.syncStatus),
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }
}
