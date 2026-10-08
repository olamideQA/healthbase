import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/db/app_database.dart';
import 'package:healthbase/core/sync/sync_engine.dart';
import 'package:healthbase/features/daily_check/data/daily_check_repository.dart';
import 'package:healthbase/features/daily_check/domain/models/daily_check.dart';
import 'package:healthbase/features/measurements/data/measurement_repository.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  late AppDatabase db;
  late MockSyncEngine mockSyncEngine;
  late MeasurementRepository measurementRepository;
  late DailyCheckRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockSyncEngine = MockSyncEngine();
    when(() => mockSyncEngine.pushPendingMeasurements(any()))
        .thenAnswer((_) async => 1);
    when(() => mockSyncEngine.syncProfile(any())).thenAnswer((_) async {});

    measurementRepository =
        MeasurementRepository(db: db, syncEngine: mockSyncEngine);
    repository = DailyCheckRepository(
      db: db,
      syncEngine: mockSyncEngine,
      measurementRepository: measurementRepository,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('DailyCheckRepository Draft Tests', () {
    test('saveDraft, getDraft, and clearDraft lifecycle', () async {
      const profileId = 'user-profile-123';
      final draft = DailyCheckDraft(
        profileId: profileId,
        currentStep: 2,
        feeling: CheckFeeling.good,
        heartRateBpm: 72.0,
        systolicMmhg: 120.0,
        diastolicMmhg: 80.0,
        temperatureCelsius: 36.6,
        weightKg: 70.0,
        glucoseMmolL: 5.2,
        symptomCodes: const ['fatigue', 'headache'],
        medicationStatus: MedicationCheckStatus.yes,
        notes: 'Feeling well rested',
        updatedAt: DateTime.now(),
      );

      await repository.saveDraft(draft);

      final retrieved = await repository.getDraft(profileId);
      expect(retrieved, isNotNull);
      expect(retrieved!.profileId, profileId);
      expect(retrieved.currentStep, 2);
      expect(retrieved.feeling, CheckFeeling.good);
      expect(retrieved.heartRateBpm, 72.0);
      expect(retrieved.systolicMmhg, 120.0);
      expect(retrieved.diastolicMmhg, 80.0);
      expect(retrieved.temperatureCelsius, 36.6);
      expect(retrieved.weightKg, 70.0);
      expect(retrieved.glucoseMmolL, 5.2);
      expect(retrieved.symptomCodes, ['fatigue', 'headache']);
      expect(retrieved.medicationStatus, MedicationCheckStatus.yes);
      expect(retrieved.notes, 'Feeling well rested');

      // Clear draft
      await repository.clearDraft(profileId);
      final afterClear = await repository.getDraft(profileId);
      expect(afterClear, isNull);
    });

    test('getDraft ignores and clears drafts older than 24 hours', () async {
      const profileId = 'user-profile-old';
      final expiredDraft = DailyCheckDraft(
        profileId: profileId,
        currentStep: 1,
        feeling: CheckFeeling.okay,
        heartRateBpm: 70.0,
        updatedAt: DateTime.now().subtract(const Duration(hours: 25)),
      );

      // Save directly with older timestamp
      await repository.saveDraft(expiredDraft);
      // Manually set older updatedAt in DB
      await (db.update(db.localDailyCheckDraftsTable)
            ..where((tbl) => tbl.profileId.equals(profileId)))
          .write(LocalDailyCheckDraftsTableCompanion(
        updatedAt: Value(DateTime.now().subtract(const Duration(hours: 26))),
      ));

      final result = await repository.getDraft(profileId);
      expect(result, isNull);

      // Verify draft was deleted from table
      final directRow = await (db.select(db.localDailyCheckDraftsTable)
            ..where((tbl) => tbl.profileId.equals(profileId)))
          .getSingleOrNull();
      expect(directRow, isNull);
    });
  });

  group('DailyCheckRepository completeCheck & Query Tests', () {
    test('completeCheck commits daily check and creates linked measurements', () async {
      const profileId = 'user-profile-check';
      final symptoms = [
        const CheckSymptom(symptomCode: 'headache', displayName: 'Headache'),
        const CheckSymptom(
          symptomCode: 'chest_discomfort',
          displayName: 'Chest discomfort',
          isUrgent: true,
        ),
      ];

      final completedCheck = await repository.completeCheck(
        profileId: profileId,
        feeling: CheckFeeling.notGreat,
        medicationStatus: MedicationCheckStatus.some,
        symptoms: symptoms,
        notes: 'Mild discomfort upon waking',
        heartRateBpm: 84.0,
        systolicMmhg: 130.0,
        diastolicMmhg: 85.0,
        temperatureCelsius: 37.1,
        weightKg: 75.0,
        glucoseMmolL: 5.8,
      );

      expect(completedCheck.id, isNotEmpty);
      expect(completedCheck.profileId, profileId);
      expect(completedCheck.feeling, CheckFeeling.notGreat);
      expect(completedCheck.medicationStatus, MedicationCheckStatus.some);
      expect(completedCheck.symptoms.length, 2);
      expect(completedCheck.hasUrgentSymptoms, isTrue);

      // Verify today check query
      final todayCheck = await repository.getTodayCheck(profileId);
      expect(todayCheck, isNotNull);
      expect(todayCheck!.id, completedCheck.id);
      expect(todayCheck.symptoms.length, 2);

      // Verify linked measurements created in measurementRepository
      final measurements = await measurementRepository.getMeasurements(profileId: profileId);
      expect(measurements.length, 5); // HR, BP, Temp, Weight, Glucose

      final hrMeas = measurements.firstWhere((Measurement m) => m.type == MeasurementType.heartRate);
      expect(hrMeas.heartRateBpm, 84.0);
      expect(hrMeas.dailyCheckId, completedCheck.id);

      final bpMeas = measurements.firstWhere((Measurement m) => m.type == MeasurementType.bloodPressure);
      expect(bpMeas.systolicMmhg, 130.0);
      expect(bpMeas.diastolicMmhg, 85.0);
      expect(bpMeas.dailyCheckId, completedCheck.id);

      final tempMeas = measurements.firstWhere((Measurement m) => m.type == MeasurementType.temperature);
      expect(tempMeas.temperatureCelsius, 37.1);
      expect(tempMeas.dailyCheckId, completedCheck.id);

      final weightMeas = measurements.firstWhere((Measurement m) => m.type == MeasurementType.weight);
      expect(weightMeas.weightKg, 75.0);
      expect(weightMeas.dailyCheckId, completedCheck.id);

      final glucoseMeas = measurements.firstWhere((Measurement m) => m.type == MeasurementType.bloodGlucose);
      expect(glucoseMeas.glucoseMmolL, 5.8);
      expect(glucoseMeas.dailyCheckId, completedCheck.id);
    });

    test('watchTodayCheck emits reactive updates when completed', () async {
      const profileId = 'user-profile-stream';

      final expectation = expectLater(
        repository.watchTodayCheck(profileId),
        emitsThrough(predicate<DailyCheck?>((c) => c != null && c.profileId == profileId)),
      );

      await repository.completeCheck(
        profileId: profileId,
        feeling: CheckFeeling.good,
        medicationStatus: MedicationCheckStatus.yes,
        symptoms: const [],
        heartRateBpm: 68.0,
      );

      await expectation;
    });
  });
}
