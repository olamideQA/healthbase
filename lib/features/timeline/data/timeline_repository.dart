import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../daily_check/domain/models/daily_check.dart';
import '../../measurements/domain/models/measurement.dart';
import '../domain/models/timeline_entry.dart';

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  return TimelineRepository(db: db, syncEngine: syncEngine);
});

class TimelineRepository {
  TimelineRepository({
    required this.db,
    required this.syncEngine,
  });

  final AppDatabase db;
  final SyncEngine syncEngine;

  /// Fetch a paginated chunk of daily timeline records with memory bounds.
  Future<TimelinePageResult> getTimelinePage({
    required String profileId,
    int pageIndex = 0,
    int pageSize = 15,
    DateTime? beforeCursor,
    TimelineDateFilter dateFilter = TimelineDateFilter.last30Days,
    TimelineMetricFilter metricFilter = TimelineMetricFilter.all,
    DateTimeRange? customRange,
  }) async {
    final range = dateFilter.getDateRange(customRange);

    // 1. Query measurements within the bounded window
    final measQuery = db.select(db.localMeasurementsTable)
      ..where((tbl) {
        var expr = tbl.profileId.equals(profileId) & tbl.isDeleted.equals(false);
        if (metricFilter.toMeasurementType() != null) {
          expr = expr & tbl.type.equals(metricFilter.toMeasurementType()!.toDbValue());
        }
        if (range != null) {
          expr = expr &
              tbl.recordedAt.isBiggerOrEqualValue(range.start) &
              tbl.recordedAt.isSmallerOrEqualValue(range.end);
        }
        if (beforeCursor != null) {
          expr = expr & tbl.recordedAt.isSmallerOrEqualValue(beforeCursor);
        }
        return expr;
      })
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.recordedAt, mode: OrderingMode.desc),
      ])
      ..limit(pageSize * 10); // Strictly bounded query to prevent unbounded memory loading

    final measRows = await measQuery.get();
    final allMeasurements = measRows.map(_mapMeasurementRow).toList();

    // 2. Query daily checks within the bounded window
    final checkRows = <LocalDailyChecksTableData>[];
    if (metricFilter == TimelineMetricFilter.all ||
        metricFilter == TimelineMetricFilter.dailyCheck ||
        metricFilter == TimelineMetricFilter.symptoms) {
      final checkQuery = db.select(db.localDailyChecksTable)
        ..where((tbl) {
          var expr = tbl.profileId.equals(profileId) & tbl.isDeleted.equals(false);
          if (range != null) {
            expr = expr &
                tbl.checkDate.isBiggerOrEqualValue(range.start) &
                tbl.checkDate.isSmallerOrEqualValue(range.end);
          }
          if (beforeCursor != null) {
            expr = expr & tbl.checkDate.isSmallerOrEqualValue(beforeCursor);
          }
          return expr;
        })
        ..orderBy([
          (tbl) => OrderingTerm(expression: tbl.checkDate, mode: OrderingMode.desc),
        ])
        ..limit(pageSize * 3);

      checkRows.addAll(await checkQuery.get());
    }

    // 3. Resolve symptoms for checks
    final checksWithDetails = <(DailyCheck, SyncStatus)>[];
    for (final row in checkRows) {
      final symptoms = await _getSymptomsForCheck(row.id);
      final check = _mapDailyCheckRow(row, symptoms);
      // If filtering by symptoms, only keep checks that have symptoms
      if (metricFilter == TimelineMetricFilter.symptoms && check.symptoms.isEmpty) {
        continue;
      }
      checksWithDetails.add((check, SyncStatus.fromDbValue(row.syncStatus)));
    }

    // 4. Collect all distinct calendar dates (normalized to midnight)
    final dateSet = <DateTime>{};
    for (final m in allMeasurements) {
      dateSet.add(DateTime(m.recordedAt.year, m.recordedAt.month, m.recordedAt.day));
    }
    for (final (c, _) in checksWithDetails) {
      dateSet.add(DateTime(c.checkDate.year, c.checkDate.month, c.checkDate.day));
    }

    final sortedDates = dateSet.toList()..sort((a, b) => b.compareTo(a));

    final hasMore = sortedDates.length > pageSize;
    final pagedDates = sortedDates.take(pageSize).toList();

    // 5. Build daily health records for each paged date
    final records = <TimelineDayRecord>[];
    for (final date in pagedDates) {
      final nextDay = date.add(const Duration(days: 1));

      final dayMeasurements = allMeasurements
          .where((m) =>
              m.recordedAt.isAtSameMomentAs(date) ||
              (m.recordedAt.isAfter(date) && m.recordedAt.isBefore(nextDay)))
          .toList()
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

      final checkPair = checksWithDetails
          .where((pair) =>
              pair.$1.checkDate.year == date.year &&
              pair.$1.checkDate.month == date.month &&
              pair.$1.checkDate.day == date.day)
          .firstOrNull;

      final hr = dayMeasurements
          .where((m) => m.type == MeasurementType.heartRate)
          .firstOrNull;
      final bp = dayMeasurements
          .where((m) => m.type == MeasurementType.bloodPressure)
          .firstOrNull;
      final temp = dayMeasurements
          .where((m) => m.type == MeasurementType.temperature)
          .firstOrNull;
      final weight = dayMeasurements
          .where((m) => m.type == MeasurementType.weight)
          .firstOrNull;
      final glucose = dayMeasurements
          .where((m) => m.type == MeasurementType.bloodGlucose)
          .firstOrNull;

      final record = TimelineDayRecord(
        date: date,
        heartRate: hr,
        bloodPressure: bp,
        temperature: temp,
        weight: weight,
        glucose: glucose,
        dailyCheck: checkPair?.$1,
        dailyCheckSyncStatus: checkPair?.$2 ?? SyncStatus.synced,
        allDayMeasurements: dayMeasurements,
      );

      if (record.matchesMetricFilter(metricFilter)) {
        records.add(record);
      }
    }

    DateTime? nextCursor;
    if (hasMore && pagedDates.isNotEmpty) {
      final oldestDate = pagedDates.last;
      nextCursor = DateTime(oldestDate.year, oldestDate.month, oldestDate.day)
          .subtract(const Duration(seconds: 1));
    }

    return TimelinePageResult(
      records: records,
      hasMore: hasMore,
      pageIndex: pageIndex,
      nextCursor: nextCursor,
    );
  }

  /// Watch live updates for the timeline (first page) for reactive UI.
  Stream<TimelinePageResult> watchTimelinePage({
    required String profileId,
    int pageSize = 15,
    TimelineDateFilter dateFilter = TimelineDateFilter.last30Days,
    TimelineMetricFilter metricFilter = TimelineMetricFilter.all,
    DateTimeRange? customRange,
  }) {
    return db.select(db.localMeasurementsTable).watch().asyncMap((_) async {
      return getTimelinePage(
        profileId: profileId,
        pageIndex: 0,
        pageSize: pageSize,
        dateFilter: dateFilter,
        metricFilter: metricFilter,
        customRange: customRange,
      );
    });
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

  Measurement _mapMeasurementRow(LocalMeasurementsTableData r) {
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

  DailyCheck _mapDailyCheckRow(
    LocalDailyChecksTableData r,
    List<CheckSymptom> symptoms,
  ) {
    return DailyCheck(
      id: r.id,
      profileId: r.profileId,
      checkDate: r.checkDate,
      feeling: CheckFeeling.fromDbValue(r.feeling),
      symptoms: symptoms,
      medicationStatus: MedicationCheckStatus.fromDbValue(r.medicationStatus),
      notes: r.notes,
      isDeleted: r.isDeleted,
      version: r.version,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }
}
