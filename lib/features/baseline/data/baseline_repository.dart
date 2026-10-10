import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/app_database.dart';
import '../../measurements/domain/models/measurement.dart';
import '../domain/models/personal_baseline.dart';
import '../domain/services/baseline_calculator.dart';

final baselineRepositoryProvider = Provider<BaselineRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BaselineRepository(db: db);
});

final personalBaselineStreamProvider = StreamProvider.family<
    PersonalBaselineSummary,
    ({String profileId, BaselineWindow window})>((ref, arg) {
  final repo = ref.watch(baselineRepositoryProvider);
  return repo.watchPersonalBaseline(
    profileId: arg.profileId,
    window: arg.window,
  );
});

class BaselineRepository {
  BaselineRepository({required this.db});

  final AppDatabase db;

  /// Fetch calculated personal baseline summary for a user and time window.
  Future<PersonalBaselineSummary> getPersonalBaseline({
    required String profileId,
    BaselineWindow window = BaselineWindow.days30,
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final cutoff = effectiveNow.subtract(window.duration);

    final query = db.select(db.localMeasurementsTable)
      ..where((tbl) =>
          tbl.profileId.equals(profileId) &
          tbl.isDeleted.equals(false) &
          tbl.recordedAt.isBiggerOrEqualValue(cutoff))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.recordedAt, mode: OrderingMode.desc),
      ])
      ..limit(500); // Strictly bounded query to safeguard memory

    final rows = await query.get();
    final measurements = rows.map(_mapRowToMeasurement).toList();

    return BaselineCalculator.calculateSummary(
      profileId: profileId,
      window: window,
      measurements: measurements,
      now: effectiveNow,
    );
  }

  /// Watch live updates to personal baseline summary as measurements change.
  Stream<PersonalBaselineSummary> watchPersonalBaseline({
    required String profileId,
    BaselineWindow window = BaselineWindow.days30,
  }) {
    final effectiveNow = DateTime.now();
    final cutoff = effectiveNow.subtract(window.duration);

    final query = db.select(db.localMeasurementsTable)
      ..where((tbl) =>
          tbl.profileId.equals(profileId) &
          tbl.isDeleted.equals(false) &
          tbl.recordedAt.isBiggerOrEqualValue(cutoff))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.recordedAt, mode: OrderingMode.desc),
      ])
      ..limit(500);

    return query.watch().map((rows) {
      final measurements = rows.map(_mapRowToMeasurement).toList();
      return BaselineCalculator.calculateSummary(
        profileId: profileId,
        window: window,
        measurements: measurements,
        now: DateTime.now(),
      );
    });
  }

  Measurement _mapRowToMeasurement(LocalMeasurementsTableData r) {
    return Measurement(
      id: r.id,
      profileId: r.profileId,
      type: MeasurementType.fromDbValue(r.type),
      heartRateBpm: r.heartRateBpm,
      systolicMmhg: r.systolicMmhg,
      diastolicMmhg: r.diastolicMmhg,
      pulseBpm: r.pulseBpm,
      temperatureCelsius: r.temperatureCelsius,
      weightKg: r.weightKg,
      glucoseMmolL: r.glucoseMmolL,
      source: MeasurementSource.fromDbValue(r.source),
      provenance: MeasurementProvenance.fromDbValue(r.provenance),
      quality: null,
      recordedAt: r.recordedAt,
      recordedUtcOffset: r.recordedUtcOffset,
      notes: r.notes,
      dailyCheckId: r.dailyCheckId,
      isDeleted: r.isDeleted,
      syncStatus: SyncStatus.fromDbValue(r.syncStatus),
      version: r.version,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }
}
