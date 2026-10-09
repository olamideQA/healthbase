import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/app_database.dart';
import '../../measurements/data/measurement_repository.dart';
import '../../measurements/domain/models/measurement.dart';
import '../../profile/domain/models/health_profile.dart';
import '../domain/models/health_insight.dart';
import '../domain/services/insight_generator.dart';

final insightRepositoryProvider = Provider<InsightRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return InsightRepository(db: db);
});

final healthInsightsStreamProvider = StreamProvider.family<
    List<HealthInsight>,
    ({String profileId, UnitSystem unitSystem})>((ref, arg) {
  final repo = ref.watch(insightRepositoryProvider);
  return repo.watchInsights(
    profileId: arg.profileId,
    unitSystem: arg.unitSystem,
  );
});

class InsightRepository {
  InsightRepository({required this.db});

  final AppDatabase db;

  static const Duration defaultRecentDuration = Duration(days: 7);
  static const Duration defaultBaselineDuration = Duration(days: 30);

  /// Fetch calculated health insights for a given profile.
  Future<List<HealthInsight>> getInsights({
    required String profileId,
    UnitSystem unitSystem = UnitSystem.metric,
    DateTime? now,
    Duration recentDuration = defaultRecentDuration,
    Duration baselineDuration = defaultBaselineDuration,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final recentCutoff = effectiveNow.subtract(recentDuration);
    final baselineCutoff = recentCutoff.subtract(baselineDuration);

    final query = db.select(db.localMeasurementsTable)
      ..where((tbl) =>
          tbl.profileId.equals(profileId) &
          tbl.isDeleted.equals(false) &
          tbl.recordedAt.isBiggerOrEqualValue(baselineCutoff))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.recordedAt, mode: OrderingMode.desc),
      ])
      ..limit(1000);

    final rows = await query.get();
    final allMeasurements = rows.map(_mapRowToMeasurement).toList();

    final recentMeasurements = allMeasurements
        .where((m) => m.recordedAt.isAfter(recentCutoff) || m.recordedAt.isAtSameMomentAs(recentCutoff))
        .toList();

    final baselineMeasurements = allMeasurements
        .where((m) =>
            m.recordedAt.isBefore(recentCutoff) &&
            (m.recordedAt.isAfter(baselineCutoff) || m.recordedAt.isAtSameMomentAs(baselineCutoff)))
        .toList();

    return InsightGenerator.generateAllInsights(
      recentMeasurements: recentMeasurements,
      baselineMeasurements: baselineMeasurements,
      unitSystem: unitSystem,
      recentPeriodName: 'the last ${recentDuration.inDays} days',
      baselinePeriodName: 'the previous ${baselineDuration.inDays} days',
    );
  }

  /// Watch live stream of health insights as measurements change.
  Stream<List<HealthInsight>> watchInsights({
    required String profileId,
    UnitSystem unitSystem = UnitSystem.metric,
    Duration recentDuration = defaultRecentDuration,
    Duration baselineDuration = defaultBaselineDuration,
  }) {
    final effectiveNow = DateTime.now();
    final recentCutoff = effectiveNow.subtract(recentDuration);
    final baselineCutoff = recentCutoff.subtract(baselineDuration);

    final query = db.select(db.localMeasurementsTable)
      ..where((tbl) =>
          tbl.profileId.equals(profileId) &
          tbl.isDeleted.equals(false) &
          tbl.recordedAt.isBiggerOrEqualValue(baselineCutoff))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.recordedAt, mode: OrderingMode.desc),
      ])
      ..limit(1000);

    return query.watch().map((rows) {
      final nowInstant = DateTime.now();
      final rCut = nowInstant.subtract(recentDuration);
      final bCut = rCut.subtract(baselineDuration);

      final allMeasurements = rows.map(_mapRowToMeasurement).toList();

      final recent = allMeasurements
          .where((m) => m.recordedAt.isAfter(rCut) || m.recordedAt.isAtSameMomentAs(rCut))
          .toList();

      final baseline = allMeasurements
          .where((m) =>
              m.recordedAt.isBefore(rCut) &&
              (m.recordedAt.isAfter(bCut) || m.recordedAt.isAtSameMomentAs(bCut)))
          .toList();

      return InsightGenerator.generateAllInsights(
        recentMeasurements: recent,
        baselineMeasurements: baseline,
        unitSystem: unitSystem,
        recentPeriodName: 'the last ${recentDuration.inDays} days',
        baselinePeriodName: 'the previous ${baselineDuration.inDays} days',
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
