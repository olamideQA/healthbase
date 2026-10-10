import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthbase/core/db/app_database.dart';
import 'package:healthbase/features/daily_check/domain/models/daily_check.dart';
import 'package:healthbase/features/insights/domain/services/insight_generator.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/medications/domain/models/medication.dart';
import 'package:healthbase/features/profile/data/profile_repository.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:healthbase/features/reports/domain/models/health_report_data.dart';
import 'package:healthbase/features/reports/domain/services/report_generator_service.dart';

final reportGeneratorServiceProvider = Provider<ReportGeneratorService>((ref) {
  return const ReportGeneratorService();
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final service = ref.watch(reportGeneratorServiceProvider);
  return ReportRepository(db: db, service: service);
});

typedef ReportQueryArgs = ({
  String profileId,
  ReportPeriod period,
  DateTime? customStart,
  DateTime? customEnd,
});

final reportDataProvider =
    FutureProvider.family<HealthReportData, ReportQueryArgs>((ref, args) async {
  final repo = ref.watch(reportRepositoryProvider);
  final profileRepo = ref.watch(profileRepositoryProvider);

  // Fetch target profile (or self fallback)
  final selfProfile = await profileRepo.getMyProfile();
  final profile = selfProfile ??
      HealthProfile(
        id: args.profileId,
        ownerAccountId: args.profileId,
        isSelf: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  return repo.generateReportData(
    profile: profile,
    period: args.period,
    customStart: args.customStart,
    customEnd: args.customEnd,
  );
});

class ReportRepository {
  ReportRepository({
    required this.db,
    required this.service,
  });

  final AppDatabase db;
  final ReportGeneratorService service;

  /// Assemble complete HealthReportData for a given profile and date range.
  Future<HealthReportData> generateReportData({
    required HealthProfile profile,
    required ReportPeriod period,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final now = DateTime.now();
    final DateTime startDate;
    final DateTime endDate;

    if (period == ReportPeriod.custom && customStart != null && customEnd != null) {
      startDate = customStart;
      endDate = customEnd;
    } else {
      final days = period.days ?? 30;
      startDate = now.subtract(Duration(days: days));
      endDate = now;
    }

    // 1. Query measurements in date range
    final measQuery = db.select(db.localMeasurementsTable)
      ..where((tbl) =>
          tbl.profileId.equals(profile.id) &
          tbl.isDeleted.equals(false) &
          tbl.recordedAt.isBiggerOrEqualValue(startDate) &
          tbl.recordedAt.isSmallerOrEqualValue(endDate))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.recordedAt, mode: OrderingMode.asc),
      ]);
    final measRows = await measQuery.get();
    final measurements = measRows.map(_mapRowToMeasurement).toList();

    // 2. Query daily checks in date range
    final checkQuery = db.select(db.localDailyChecksTable)
      ..where((tbl) =>
          tbl.profileId.equals(profile.id) &
          tbl.isDeleted.equals(false) &
          tbl.checkDate.isBiggerOrEqualValue(startDate) &
          tbl.checkDate.isSmallerOrEqualValue(endDate))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.checkDate, mode: OrderingMode.desc),
      ]);
    final checkRows = await checkQuery.get();
    final dailyChecks = <DailyCheck>[];
    for (final row in checkRows) {
      final symptomQuery = db.select(db.localDailyCheckSymptomsTable)
        ..where((tbl) => tbl.dailyCheckId.equals(row.id));
      final symptomRows = await symptomQuery.get();
      final symptoms = symptomRows.map((s) {
        final match = CheckSymptom.findByCode(s.symptomCode);
        return CheckSymptom(
          symptomCode: s.symptomCode,
          displayName: match?.displayName ?? s.symptomCode,
          isUrgent: s.isUrgent,
          customDescription: s.customDescription,
        );
      }).toList();

      dailyChecks.add(DailyCheck(
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
      ));
    }

    // 3. Query medications and adherence events
    final medQuery = db.select(db.localMedicationsTable)
      ..where((tbl) => tbl.profileId.equals(profile.id) & tbl.isDeleted.equals(false));
    final medRows = await medQuery.get();
    final medications = medRows.map(_mapRowToMedication).toList();

    final eventQuery = db.select(db.localMedicationEventsTable)
      ..where((tbl) =>
          tbl.profileId.equals(profile.id) &
          tbl.isDeleted.equals(false) &
          tbl.scheduledTime.isBiggerOrEqualValue(startDate) &
          tbl.scheduledTime.isSmallerOrEqualValue(endDate));
    final eventRows = await eventQuery.get();
    final medicationEvents = eventRows.map(_mapRowToEvent).toList();

    // 4. Generate statistical insights (What Changed?)
    final recentCutoff = now.subtract(const Duration(days: 7));
    final recentMeasurements = measurements
        .where((m) => m.recordedAt.isAfter(recentCutoff) || m.recordedAt.isAtSameMomentAs(recentCutoff))
        .toList();
    final baselineMeasurements = measurements
        .where((m) => m.recordedAt.isBefore(recentCutoff))
        .toList();

    final allInsights = InsightGenerator.generateAllInsights(
      recentMeasurements: recentMeasurements,
      baselineMeasurements: baselineMeasurements,
      unitSystem: profile.preferredUnits,
    );
    final insights = allInsights.where((i) => i.isMeaningful).toList();

    return service.buildReportData(
      profile: profile,
      startDate: startDate,
      endDate: endDate,
      period: period,
      measurements: measurements,
      dailyChecks: dailyChecks,
      medications: medications,
      medicationEvents: medicationEvents,
      insights: insights,
    );
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
      recordedAt: r.recordedAt,
      recordedUtcOffset: r.recordedUtcOffset,
      notes: r.notes,
      dailyCheckId: r.dailyCheckId,
      isDeleted: r.isDeleted,
      syncStatus: SyncStatus.fromDbValue(r.syncStatus),
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
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
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }
}
