import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../measurements/data/measurement_repository.dart';
import '../../measurements/domain/models/measurement.dart';
import '../domain/models/daily_check.dart';

final dailyCheckRepositoryProvider = Provider<DailyCheckRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  final measRepo = ref.watch(measurementRepositoryProvider);
  return DailyCheckRepository(
    db: db,
    syncEngine: syncEngine,
    measurementRepository: measRepo,
  );
});

final todayCheckStreamProvider =
    StreamProvider.family<DailyCheck?, String>((ref, profileId) {
  final repo = ref.watch(dailyCheckRepositoryProvider);
  return repo.watchTodayCheck(profileId);
});

class DailyCheckRepository {
  DailyCheckRepository({
    required this.db,
    required this.syncEngine,
    required this.measurementRepository,
  });

  final AppDatabase db;
  final SyncEngine syncEngine;
  final MeasurementRepository measurementRepository;
  final _uuid = const Uuid();

  /// Watch today's check reactive stream.
  Stream<DailyCheck?> watchTodayCheck(String profileId) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final query = db.select(db.localDailyChecksTable)
      ..where((tbl) =>
          tbl.profileId.equals(profileId) &
          tbl.isDeleted.equals(false) &
          tbl.checkDate.isBiggerOrEqualValue(todayStart) &
          tbl.checkDate.isSmallerOrEqualValue(todayEnd));

    return query.watchSingleOrNull().asyncMap((row) async {
      if (row == null) return null;
      final symptoms = await _getSymptomsForCheck(row.id);
      return _mapRowToEntity(row, symptoms);
    });
  }

  /// Get today's check directly.
  Future<DailyCheck?> getTodayCheck(String profileId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final row = await (db.select(db.localDailyChecksTable)
          ..where((tbl) =>
              tbl.profileId.equals(profileId) &
              tbl.isDeleted.equals(false) &
              tbl.checkDate.isBiggerOrEqualValue(todayStart) &
              tbl.checkDate.isSmallerOrEqualValue(todayEnd)))
        .getSingleOrNull();

    if (row == null) return null;
    final symptoms = await _getSymptomsForCheck(row.id);
    return _mapRowToEntity(row, symptoms);
  }

  /// Auto-save progress to local SQLite draft table.
  Future<void> saveDraft(DailyCheckDraft draft) async {
    final companion = LocalDailyCheckDraftsTableCompanion(
      profileId: Value(draft.profileId),
      currentStep: Value(draft.currentStep),
      feeling: Value(draft.feeling?.toDbValue()),
      heartRateBpm: Value(draft.heartRateBpm),
      systolicMmhg: Value(draft.systolicMmhg),
      diastolicMmhg: Value(draft.diastolicMmhg),
      temperatureCelsius: Value(draft.temperatureCelsius),
      weightKg: Value(draft.weightKg),
      glucoseMmolL: Value(draft.glucoseMmolL),
      symptomsJson: Value(jsonEncode(_encodeDraftSymptoms(draft))),
      medicationStatus: Value(draft.medicationStatus?.toDbValue()),
      notes: Value(draft.notes),
      updatedAt: Value(DateTime.now()),
    );

    await db.into(db.localDailyCheckDraftsTable).insertOnConflictUpdate(companion);
  }

  /// Fetch in-progress draft for profile.
  Future<DailyCheckDraft?> getDraft(String profileId) async {
    final row = await (db.select(db.localDailyCheckDraftsTable)
          ..where((tbl) => tbl.profileId.equals(profileId)))
        .getSingleOrNull();

    if (row == null) return null;

    // Discard drafts older than 24 hours
    if (DateTime.now().difference(row.updatedAt).inHours > 24) {
      await clearDraft(profileId);
      return null;
    }

    final decodedDraft = _decodeDraftSymptoms(row.symptomsJson);

    return DailyCheckDraft(
      profileId: row.profileId,
      currentStep: row.currentStep,
      feeling: row.feeling != null ? CheckFeeling.fromDbValue(row.feeling!) : null,
      heartRateBpm: row.heartRateBpm,
      systolicMmhg: row.systolicMmhg,
      diastolicMmhg: row.diastolicMmhg,
      temperatureCelsius: row.temperatureCelsius,
      weightKg: row.weightKg,
      glucoseMmolL: row.glucoseMmolL,
      symptomCodes: decodedDraft.codes,
      otherSymptomText: decodedDraft.otherText,
      medicationStatus: row.medicationStatus != null
          ? MedicationCheckStatus.fromDbValue(row.medicationStatus!)
          : null,
      notes: row.notes,
      updatedAt: row.updatedAt,
    );
  }

  /// Encode draft symptoms so the free-text "other" detail survives an
  /// app kill without a local-DB migration. Legacy drafts stored a plain
  /// `List<String>`; new drafts store `List<Map>` with optional `desc`.
  static List<Map<String, dynamic>> _encodeDraftSymptoms(DailyCheckDraft draft) {
    return draft.symptomCodes.map((code) {
      if (code == 'other') {
        return <String, dynamic>{
          'code': code,
          if ((draft.otherSymptomText ?? '').trim().isNotEmpty)
            'desc': draft.otherSymptomText!.trim(),
        };
      }
      return <String, dynamic>{'code': code};
    }).toList();
  }

  static ({List<String> codes, String? otherText}) _decodeDraftSymptoms(
    String? raw,
  ) {
    if (raw == null) return (codes: <String>[], otherText: null);
    try {
      final decoded = jsonDecode(raw) as List;
      final codes = <String>[];
      String? otherText;
      for (final entry in decoded) {
        if (entry is String) {
          codes.add(entry);
        } else if (entry is Map) {
          final code = entry['code']?.toString();
          if (code == null || code.isEmpty) continue;
          codes.add(code);
          if (code == 'other') {
            final desc = entry['desc']?.toString();
            if (desc != null && desc.trim().isNotEmpty) otherText = desc.trim();
          }
        }
      }
      return (codes: codes, otherText: otherText);
    } catch (_) {
      return (codes: <String>[], otherText: null);
    }
  }

  /// Clear draft upon completion or explicit reset.
  Future<void> clearDraft(String profileId) async {
    await (db.delete(db.localDailyCheckDraftsTable)
          ..where((tbl) => tbl.profileId.equals(profileId)))
        .go();
  }

  /// Complete and commit a daily health check and its associated vitals.
  Future<DailyCheck> completeCheck({
    required String profileId,
    required CheckFeeling feeling,
    required MedicationCheckStatus medicationStatus,
    required List<CheckSymptom> symptoms,
    String? notes,
    required double heartRateBpm,
    double? systolicMmhg,
    double? diastolicMmhg,
    double? temperatureCelsius,
    double? weightKg,
    double? glucoseMmolL,
  }) async {
    // One check per profile per day: the remote database enforces this with
    // a unique index, so reject locally with a clear message instead of
    // writing a row that can never upload.
    final existing = await getTodayCheck(profileId);
    if (existing != null) {
      throw ValidationFailure(
        message:
            'Today\u2019s health check is already recorded. Only one check per day is kept.',
        code: 'DUPLICATE_DAILY_CHECK',
      );
    }

    final checkId = _uuid.v4();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Insert daily_check row
    final checkCompanion = LocalDailyChecksTableCompanion(
      id: Value(checkId),
      profileId: Value(profileId),
      checkDate: Value(today),
      feeling: Value(feeling.toDbValue()),
      medicationStatus: Value(medicationStatus.toDbValue()),
      notes: Value(notes),
      isDeleted: const Value(false),
      syncStatus: const Value('pending_insert'),
      version: const Value(1),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    await db.into(db.localDailyChecksTable).insert(checkCompanion);

    // 2. Insert symptoms
    for (final sym in symptoms) {
      final symCompanion = LocalDailyCheckSymptomsTableCompanion(
        id: Value(_uuid.v4()),
        dailyCheckId: Value(checkId),
        symptomCode: Value(sym.symptomCode),
        isUrgent: Value(sym.isUrgent),
        customDescription: Value(sym.customDescription),
        createdAt: Value(now),
      );
      await db.into(db.localDailyCheckSymptomsTable).insert(symCompanion);
    }

    // 3. Insert required Heart Rate measurement linked to dailyCheckId
    await measurementRepository.createMeasurement(
      Measurement(
        id: _uuid.v4(),
        profileId: profileId,
        type: MeasurementType.heartRate,
        heartRateBpm: heartRateBpm,
        source: MeasurementSource.manual,
        provenance: MeasurementProvenance.manuallyEntered,
        recordedAt: now,
        dailyCheckId: checkId,
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Optional Blood Pressure
    if (systolicMmhg != null && diastolicMmhg != null) {
      await measurementRepository.createMeasurement(
        Measurement(
          id: _uuid.v4(),
          profileId: profileId,
          type: MeasurementType.bloodPressure,
          systolicMmhg: systolicMmhg,
          diastolicMmhg: diastolicMmhg,
          source: MeasurementSource.manual,
          provenance: MeasurementProvenance.manuallyEntered,
          recordedAt: now,
          dailyCheckId: checkId,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    // Optional Temperature
    if (temperatureCelsius != null) {
      await measurementRepository.createMeasurement(
        Measurement(
          id: _uuid.v4(),
          profileId: profileId,
          type: MeasurementType.temperature,
          temperatureCelsius: temperatureCelsius,
          source: MeasurementSource.manual,
          provenance: MeasurementProvenance.manuallyEntered,
          recordedAt: now,
          dailyCheckId: checkId,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    // Optional Weight
    if (weightKg != null) {
      await measurementRepository.createMeasurement(
        Measurement(
          id: _uuid.v4(),
          profileId: profileId,
          type: MeasurementType.weight,
          weightKg: weightKg,
          source: MeasurementSource.manual,
          provenance: MeasurementProvenance.manuallyEntered,
          recordedAt: now,
          dailyCheckId: checkId,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    // Optional Blood Glucose
    if (glucoseMmolL != null) {
      await measurementRepository.createMeasurement(
        Measurement(
          id: _uuid.v4(),
          profileId: profileId,
          type: MeasurementType.bloodGlucose,
          glucoseMmolL: glucoseMmolL,
          source: MeasurementSource.manual,
          provenance: MeasurementProvenance.manuallyEntered,
          recordedAt: now,
          dailyCheckId: checkId,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    // 4. Clear the draft
    await clearDraft(profileId);

    // 5. Trigger sync: daily checks first (parents), then measurements.
    syncEngine.pushPendingDailyChecks(profileId).then((_) {
      syncEngine.pushPendingMeasurements(profileId).ignore();
    }).ignore();

    return DailyCheck(
      id: checkId,
      profileId: profileId,
      checkDate: today,
      feeling: feeling,
      medicationStatus: medicationStatus,
      symptoms: symptoms,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<List<CheckSymptom>> _getSymptomsForCheck(String checkId) async {
    final rows = await (db.select(db.localDailyCheckSymptomsTable)
          ..where((tbl) => tbl.dailyCheckId.equals(checkId)))
        .get();

    return rows.map((r) {
      final match = CheckSymptom.findByCode(r.symptomCode);
      return CheckSymptom(
        symptomCode: r.symptomCode,
        displayName: match?.displayName ?? r.symptomCode,
        isUrgent: r.isUrgent,
        customDescription: r.customDescription,
      );
    }).toList();
  }

  DailyCheck _mapRowToEntity(LocalDailyChecksTableData row, List<CheckSymptom> symptoms) {
    return DailyCheck(
      id: row.id,
      profileId: row.profileId,
      checkDate: row.checkDate,
      feeling: CheckFeeling.fromDbValue(row.feeling),
      medicationStatus: MedicationCheckStatus.fromDbValue(row.medicationStatus),
      symptoms: symptoms,
      notes: row.notes,
      isDeleted: row.isDeleted,
      version: row.version,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
