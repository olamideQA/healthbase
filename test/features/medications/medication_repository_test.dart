import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/db/app_database.dart';
import 'package:healthbase/features/medications/data/medication_repository.dart';
import 'package:healthbase/features/medications/domain/models/medication.dart';

void main() {
  late AppDatabase db;
  late MedicationRepository repository;
  final now = DateTime(2026, 10, 10, 12, 0);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = MedicationRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('MedicationRepository Database Tests', () {
    test('addMedication persists locally and queues sync outbox action', () async {
      final id = await repository.addMedication(
        profileId: 'user_1',
        name: 'Lisinopril',
        dosage: '10mg once daily in morning',
        frequency: MedicationFrequency.daily,
        startDate: now.subtract(const Duration(days: 10)),
        reminderTime: '08:00',
        notes: 'Take with full glass of water',
      );

      expect(id, isNotEmpty);

      // Verify persisted in SQLite
      final meds = await repository.getMedications(profileId: 'user_1');
      expect(meds.length, 1);
      expect(meds.first.name, 'Lisinopril');
      expect(meds.first.dosage, '10mg once daily in morning');
      expect(meds.first.frequency, MedicationFrequency.daily);
      expect(meds.first.reminderTime, '08:00');
      expect(meds.first.isActive, isTrue);

      // Verify sync outbox action queued
      final outboxRows = await db.select(db.syncOutboxTable).get();
      expect(outboxRows.length, 1);
      expect(outboxRows.first.entityType, 'medication');
      expect(outboxRows.first.action, 'create');
    });

    test('recordEvent and getAdherenceStats calculates adherence statistics', () async {
      final medId = await repository.addMedication(
        profileId: 'user_1',
        name: 'Metformin',
        dosage: '500mg twice daily with meals',
        frequency: MedicationFrequency.twiceDaily,
        startDate: now.subtract(const Duration(days: 5)), // 5 days * 2 = 10 scheduled
      );

      // Record 4 taken and 1 missed
      for (int i = 0; i < 4; i++) {
        await repository.recordEvent(
          profileId: 'user_1',
          medicationId: medId,
          scheduledTime: now.subtract(Duration(days: i)),
          status: MedicationEventStatus.taken,
        );
      }
      await repository.recordEvent(
        profileId: 'user_1',
        medicationId: medId,
        scheduledTime: now.subtract(const Duration(days: 4)),
        status: MedicationEventStatus.missed,
      );

      final stats = await repository.getAdherenceStats(
        profileId: 'user_1',
        medicationId: medId,
        now: now,
      );

      expect(stats.takenCount, 4);
      expect(stats.missedCount, 1);
      expect(stats.scheduledCount, greaterThanOrEqualTo(5));
      expect(stats.recordedAdherenceRate, 80.0); // 4 / (4 + 1)
    });

    test('deleteMedication soft-deletes and removes from active list', () async {
      final id = await repository.addMedication(
        profileId: 'user_1',
        name: 'Atorvastatin',
        dosage: '20mg at bedtime',
        frequency: MedicationFrequency.daily,
        startDate: now,
      );

      var active = await repository.getMedications(profileId: 'user_1', activeOnly: true);
      expect(active.length, 1);

      await repository.deleteMedication(id);

      active = await repository.getMedications(profileId: 'user_1', activeOnly: true);
      expect(active.isEmpty, isTrue);
    });
  });
}
