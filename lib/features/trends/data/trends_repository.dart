import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/app_database.dart';
import '../../measurements/data/measurement_repository.dart';
import '../../measurements/domain/models/measurement.dart';
import '../../profile/domain/models/health_profile.dart';
import '../domain/models/trend_chart_data.dart';
import '../domain/services/trend_data_processor.dart';

final trendsRepositoryProvider = Provider<TrendsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TrendsRepository(db: db);
});

final trendSeriesStreamProvider = StreamProvider.family<
    MetricTrendSeries,
    ({String profileId, MeasurementType type, TrendPeriod period, UnitSystem unitSystem})>((ref, arg) {
  final repo = ref.watch(trendsRepositoryProvider);
  return repo.watchTrendSeries(
    profileId: arg.profileId,
    type: arg.type,
    period: arg.period,
    unitSystem: arg.unitSystem,
  );
});

class TrendsRepository {
  TrendsRepository({required this.db});

  final AppDatabase db;

  /// Fetch processed trend series for a specific metric and period.
  Future<MetricTrendSeries> getTrendSeries({
    required String profileId,
    required MeasurementType type,
    required TrendPeriod period,
    required UnitSystem unitSystem,
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final cutoff = effectiveNow.subtract(period.duration);

    final query = db.select(db.localMeasurementsTable)
      ..where((tbl) =>
          tbl.profileId.equals(profileId) &
          tbl.type.equals(type.toDbValue()) &
          tbl.isDeleted.equals(false) &
          tbl.recordedAt.isBiggerOrEqualValue(cutoff))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.recordedAt, mode: OrderingMode.asc),
      ])
      ..limit(1500); // Bounded query for performance and memory safety

    final rows = await query.get();
    final measurements = rows.map(_mapRowToMeasurement).toList();

    return TrendDataProcessor.processSeries(
      type: type,
      period: period,
      rawMeasurements: measurements,
      unitSystem: unitSystem,
      now: effectiveNow,
    );
  }

  /// Watch live updates to trend series as new measurements arrive.
  Stream<MetricTrendSeries> watchTrendSeries({
    required String profileId,
    required MeasurementType type,
    required TrendPeriod period,
    required UnitSystem unitSystem,
  }) {
    final effectiveNow = DateTime.now();
    final cutoff = effectiveNow.subtract(period.duration);

    final query = db.select(db.localMeasurementsTable)
      ..where((tbl) =>
          tbl.profileId.equals(profileId) &
          tbl.type.equals(type.toDbValue()) &
          tbl.isDeleted.equals(false) &
          tbl.recordedAt.isBiggerOrEqualValue(cutoff))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.recordedAt, mode: OrderingMode.asc),
      ])
      ..limit(1500);

    return query.watch().map((rows) {
      final measurements = rows.map(_mapRowToMeasurement).toList();
      return TrendDataProcessor.processSeries(
        type: type,
        period: period,
        rawMeasurements: measurements,
        unitSystem: unitSystem,
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
