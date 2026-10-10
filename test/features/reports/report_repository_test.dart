import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/db/app_database.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:healthbase/features/reports/data/report_repository.dart';
import 'package:healthbase/features/reports/domain/models/health_report_data.dart';
import 'package:healthbase/features/reports/domain/services/report_generator_service.dart';

void main() {
  late AppDatabase db;
  late ReportRepository repository;
  final now = DateTime(2026, 10, 10, 12, 0);

  final testProfile = HealthProfile(
    id: 'user_repo_test',
    ownerAccountId: 'user_repo_test',
    isSelf: true,
    displayName: 'Test User',
    preferredUnits: UnitSystem.metric,
    createdAt: now.subtract(const Duration(days: 60)),
    updatedAt: now,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ReportRepository(
      db: db,
      service: const ReportGeneratorService(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ReportRepository Database Filtering Tests', () {
    test('generateReportData correctly filters data within selected period and excludes out-of-range data', () async {
      // 1. Insert measurements: one inside last 30 days (5 days ago), one outside (40 days ago)
      await db.into(db.localMeasurementsTable).insert(
        LocalMeasurementsTableCompanion(
          id: const drift.Value('m_in'),
          profileId: drift.Value(testProfile.id),
          type: const drift.Value('heart_rate'),
          heartRateBpm: const drift.Value(72),
          source: const drift.Value('manual'),
          provenance: const drift.Value('manually_entered'),
          recordedAt: drift.Value(now.subtract(const Duration(days: 5))),
          recordedUtcOffset: const drift.Value(0),
          isDeleted: const drift.Value(false),
          syncStatus: const drift.Value('synced'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      await db.into(db.localMeasurementsTable).insert(
        LocalMeasurementsTableCompanion(
          id: const drift.Value('m_out'),
          profileId: drift.Value(testProfile.id),
          type: const drift.Value('heart_rate'),
          heartRateBpm: const drift.Value(95),
          source: const drift.Value('manual'),
          provenance: const drift.Value('manually_entered'),
          recordedAt: drift.Value(now.subtract(const Duration(days: 40))),
          recordedUtcOffset: const drift.Value(0),
          isDeleted: const drift.Value(false),
          syncStatus: const drift.Value('synced'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // 2. Insert daily checks: one inside (2 days ago), one outside (35 days ago)
      await db.into(db.localDailyChecksTable).insert(
        LocalDailyChecksTableCompanion(
          id: const drift.Value('check_in'),
          profileId: drift.Value(testProfile.id),
          checkDate: drift.Value(now.subtract(const Duration(days: 2))),
          feeling: const drift.Value('good'),
          medicationStatus: const drift.Value('yes'),
          isDeleted: const drift.Value(false),
          syncStatus: const drift.Value('synced'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );
      await db.into(db.localDailyCheckSymptomsTable).insert(
        const LocalDailyCheckSymptomsTableCompanion(
          id: drift.Value('sym_1'),
          dailyCheckId: drift.Value('check_in'),
          symptomCode: drift.Value('headache'),
          isUrgent: drift.Value(false),
        ),
      );

      await db.into(db.localDailyChecksTable).insert(
        LocalDailyChecksTableCompanion(
          id: const drift.Value('check_out'),
          profileId: drift.Value(testProfile.id),
          checkDate: drift.Value(now.subtract(const Duration(days: 35))),
          feeling: const drift.Value('unwell'),
          medicationStatus: const drift.Value('no'),
          isDeleted: const drift.Value(false),
          syncStatus: const drift.Value('synced'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );
      await db.into(db.localDailyCheckSymptomsTable).insert(
        const LocalDailyCheckSymptomsTableCompanion(
          id: drift.Value('sym_2'),
          dailyCheckId: drift.Value('check_out'),
          symptomCode: drift.Value('fever'),
          isUrgent: drift.Value(false),
        ),
      );

      // 3. Insert medication and adherence events
      await db.into(db.localMedicationsTable).insert(
        LocalMedicationsTableCompanion(
          id: const drift.Value('med_1'),
          profileId: drift.Value(testProfile.id),
          name: const drift.Value('Metformin'),
          dosage: const drift.Value('500mg'),
          frequency: const drift.Value('daily'),
          startDate: drift.Value(now.subtract(const Duration(days: 20))),
          isActive: const drift.Value(true),
          isDeleted: const drift.Value(false),
          syncStatus: const drift.Value('synced'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // Event inside range
      await db.into(db.localMedicationEventsTable).insert(
        LocalMedicationEventsTableCompanion(
          id: const drift.Value('event_in'),
          profileId: drift.Value(testProfile.id),
          medicationId: const drift.Value('med_1'),
          scheduledTime: drift.Value(now.subtract(const Duration(days: 3))),
          status: const drift.Value('taken'),
          isDeleted: const drift.Value(false),
          syncStatus: const drift.Value('synced'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // Event outside range (50 days ago)
      await db.into(db.localMedicationEventsTable).insert(
        LocalMedicationEventsTableCompanion(
          id: const drift.Value('event_out'),
          profileId: drift.Value(testProfile.id),
          medicationId: const drift.Value('med_1'),
          scheduledTime: drift.Value(now.subtract(const Duration(days: 50))),
          status: const drift.Value('missed'),
          isDeleted: const drift.Value(false),
          syncStatus: const drift.Value('synced'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // Generate report for 30 days
      final report = await repository.generateReportData(
        profile: testProfile,
        period: ReportPeriod.days30,
      );

      // Verify measurement: only m_in (72 bpm), m_out (95 bpm) is excluded
      final hrSummary = report.metricSummaries.firstWhere((s) => s.type.toDbValue() == 'heart_rate');
      expect(hrSummary.readingCount, 1);
      expect(hrSummary.average, 72.0);

      // Verify symptoms: only "Headache" is included, "Fever" is excluded
      expect(report.symptoms.length, 1);
      expect(report.symptoms.first.name, 'Headache');

      // Verify medication adherence: only event_in is counted (1 taken, 0 missed)
      expect(report.medications.length, 1);
      expect(report.medications.first.stats.takenCount, 1);
      expect(report.medications.first.stats.missedCount, 0);
    });

    test('generateReportData supports custom date range', () async {
      final customStart = now.subtract(const Duration(days: 15));
      final customEnd = now.subtract(const Duration(days: 10));

      // In range: 12 days ago
      await db.into(db.localMeasurementsTable).insert(
        LocalMeasurementsTableCompanion(
          id: const drift.Value('m_custom_in'),
          profileId: drift.Value(testProfile.id),
          type: const drift.Value('heart_rate'),
          heartRateBpm: const drift.Value(68),
          source: const drift.Value('manual'),
          provenance: const drift.Value('manually_entered'),
          recordedAt: drift.Value(now.subtract(const Duration(days: 12))),
          recordedUtcOffset: const drift.Value(0),
          isDeleted: const drift.Value(false),
          syncStatus: const drift.Value('synced'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // Outside custom range: 5 days ago
      await db.into(db.localMeasurementsTable).insert(
        LocalMeasurementsTableCompanion(
          id: const drift.Value('m_custom_out'),
          profileId: drift.Value(testProfile.id),
          type: const drift.Value('heart_rate'),
          heartRateBpm: const drift.Value(88),
          source: const drift.Value('manual'),
          provenance: const drift.Value('manually_entered'),
          recordedAt: drift.Value(now.subtract(const Duration(days: 5))),
          recordedUtcOffset: const drift.Value(0),
          isDeleted: const drift.Value(false),
          syncStatus: const drift.Value('synced'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      final report = await repository.generateReportData(
        profile: testProfile,
        period: ReportPeriod.custom,
        customStart: customStart,
        customEnd: customEnd,
      );

      expect(report.period, ReportPeriod.custom);
      expect(report.startDate, customStart);
      expect(report.endDate, customEnd);

      final hrSummary = report.metricSummaries.firstWhere((s) => s.type.toDbValue() == 'heart_rate');
      expect(hrSummary.readingCount, 1);
      expect(hrSummary.average, 68.0);
    });
  });
}
