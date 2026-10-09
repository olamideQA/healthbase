import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/features/medications/domain/models/medication.dart';
import 'package:healthbase/features/medications/domain/services/medication_reminder_service.dart';

void main() {
  group('MedicationAdherenceStats Playbook Tests', () {
    test('exact Playbook example: Scheduled 30, Recorded taken 27, Recorded missed 3', () {
      final events = <MedicationEvent>[
        for (int i = 0; i < 27; i++)
          MedicationEvent(
            id: 'taken_$i',
            profileId: 'user_1',
            medicationId: 'med_1',
            scheduledTime: DateTime(2026, 10, 1, 8).add(Duration(days: i)),
            status: MedicationEventStatus.taken,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        for (int i = 0; i < 3; i++)
          MedicationEvent(
            id: 'missed_$i',
            profileId: 'user_1',
            medicationId: 'med_1',
            scheduledTime: DateTime(2026, 10, 28, 8).add(Duration(days: i)),
            status: MedicationEventStatus.missed,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
      ];

      final stats = MedicationAdherenceStats.fromEvents(
        scheduledCount: 30,
        events: events,
      );

      expect(stats.scheduledCount, 30);
      expect(stats.takenCount, 27);
      expect(stats.missedCount, 3);
      expect(stats.notRecordedCount, 0);
      expect(stats.recordedAdherenceRate, 90.0);
      expect(stats.overallScheduledRate, 90.0);
    });

    test('strictly does not assume "not recorded" means missed', () {
      // 10 taken, 0 missed, 20 unrecorded out of 30 scheduled
      final events = <MedicationEvent>[
        for (int i = 0; i < 10; i++)
          MedicationEvent(
            id: 'taken_$i',
            profileId: 'user_1',
            medicationId: 'med_1',
            scheduledTime: DateTime(2026, 10, 1, 8).add(Duration(days: i)),
            status: MedicationEventStatus.taken,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
      ];

      final stats = MedicationAdherenceStats.fromEvents(
        scheduledCount: 30,
        events: events,
      );

      expect(stats.scheduledCount, 30);
      expect(stats.takenCount, 10);
      // Missed count must be exactly 0, NOT 20!
      expect(stats.missedCount, 0);
      expect(stats.notRecordedCount, 20);
      // Recorded rate of adherence for logged doses is 100%
      expect(stats.recordedAdherenceRate, 100.0);
      // Overall scheduled rate is 10/30 (33.3%)
      expect(stats.overallScheduledRate, closeTo(33.33, 0.05));
    });

    test('PRN / as-needed medication: scheduledCount matches logged events', () {
      final events = [
        MedicationEvent(
          id: 'prn_1',
          profileId: 'user_1',
          medicationId: 'med_prn',
          scheduledTime: DateTime.now(),
          status: MedicationEventStatus.taken,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final stats = MedicationAdherenceStats.fromEvents(
        scheduledCount: 1,
        events: events,
      );

      expect(stats.takenCount, 1);
      expect(stats.missedCount, 0);
      expect(stats.notRecordedCount, 0);
      expect(stats.recordedAdherenceRate, 100.0);
    });
  });

  group('MedicationReminderService Platform Support Tests', () {
    test('reports platform capability and support message', () {
      const service = MedicationReminderService();
      expect(service.supportMessage, isNotEmpty);
      expect(service.supportStatus, isNotNull);
    });
  });
}
