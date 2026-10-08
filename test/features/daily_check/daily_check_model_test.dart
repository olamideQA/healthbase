import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/features/daily_check/domain/models/daily_check.dart';

void main() {
  group('DailyCheck Domain Model Tests', () {
    test('CheckFeeling converts to and from DB string correctly', () {
      expect(CheckFeeling.good.toDbValue(), 'good');
      expect(CheckFeeling.okay.toDbValue(), 'okay');
      expect(CheckFeeling.notGreat.toDbValue(), 'not_great');
      expect(CheckFeeling.unwell.toDbValue(), 'unwell');

      expect(CheckFeeling.fromDbValue('good'), CheckFeeling.good);
      expect(CheckFeeling.fromDbValue('okay'), CheckFeeling.okay);
      expect(CheckFeeling.fromDbValue('not_great'), CheckFeeling.notGreat);
      expect(CheckFeeling.fromDbValue('unwell'), CheckFeeling.unwell);
      expect(CheckFeeling.fromDbValue('unknown_value'), CheckFeeling.okay);

      expect(CheckFeeling.good.displayName, 'Good');
      expect(CheckFeeling.notGreat.displayName, 'Not Great');
    });

    test('MedicationCheckStatus converts to and from DB string correctly', () {
      expect(MedicationCheckStatus.yes.toDbValue(), 'yes');
      expect(MedicationCheckStatus.no.toDbValue(), 'no');
      expect(MedicationCheckStatus.some.toDbValue(), 'some');
      expect(MedicationCheckStatus.noneScheduled.toDbValue(), 'none_scheduled');

      expect(MedicationCheckStatus.fromDbValue('yes'), MedicationCheckStatus.yes);
      expect(MedicationCheckStatus.fromDbValue('no'), MedicationCheckStatus.no);
      expect(MedicationCheckStatus.fromDbValue('some'), MedicationCheckStatus.some);
      expect(MedicationCheckStatus.fromDbValue('none_scheduled'), MedicationCheckStatus.noneScheduled);
      expect(MedicationCheckStatus.fromDbValue('unknown_value'), MedicationCheckStatus.noneScheduled);
    });

    test('CheckSymptom catalogue includes all urgent and standard symptoms', () {
      expect(CheckSymptom.catalogue.length, greaterThanOrEqualTo(14));

      final urgentSymptoms = CheckSymptom.catalogue.where((s) => s.isUrgent).toList();
      expect(urgentSymptoms.length, greaterThanOrEqualTo(6));

      final urgentCodes = urgentSymptoms.map((s) => s.symptomCode).toSet();
      expect(urgentCodes, contains('chest_discomfort'));
      expect(urgentCodes, contains('shortness_of_breath'));
      expect(urgentCodes, contains('sudden_numbness'));
      expect(urgentCodes, contains('difficulty_speaking'));
      expect(urgentCodes, contains('severe_headache'));
      expect(urgentCodes, contains('loss_of_consciousness'));

      final chest = CheckSymptom.findByCode('chest_discomfort');
      expect(chest, isNotNull);
      expect(chest!.isUrgent, isTrue);

      final headache = CheckSymptom.findByCode('headache');
      expect(headache, isNotNull);
      expect(headache!.isUrgent, isFalse);

      expect(CheckSymptom.findByCode('nonexistent_code'), isNull);
    });

    test('DailyCheck hasUrgentSymptoms reflects present symptoms correctly', () {
      final now = DateTime.now();
      final standardCheck = DailyCheck(
        id: 'dc-1',
        profileId: 'p-1',
        checkDate: now,
        feeling: CheckFeeling.good,
        medicationStatus: MedicationCheckStatus.yes,
        symptoms: const [
          CheckSymptom(symptomCode: 'headache', displayName: 'Headache'),
        ],
        createdAt: now,
        updatedAt: now,
      );
      expect(standardCheck.hasUrgentSymptoms, isFalse);

      final urgentCheck = DailyCheck(
        id: 'dc-2',
        profileId: 'p-1',
        checkDate: now,
        feeling: CheckFeeling.unwell,
        medicationStatus: MedicationCheckStatus.yes,
        symptoms: const [
          CheckSymptom(symptomCode: 'chest_discomfort', displayName: 'Chest discomfort', isUrgent: true),
        ],
        createdAt: now,
        updatedAt: now,
      );
      expect(urgentCheck.hasUrgentSymptoms, isTrue);
    });

    test('DailyCheckDraft hasUrgentSymptoms reflects draft codes', () {
      final now = DateTime.now();
      final nonUrgentDraft = DailyCheckDraft(
        profileId: 'p-1',
        symptomCodes: const ['fatigue', 'headache'],
        updatedAt: now,
      );
      expect(nonUrgentDraft.hasUrgentSymptoms, isFalse);

      final urgentDraft = DailyCheckDraft(
        profileId: 'p-1',
        symptomCodes: const ['fatigue', 'shortness_of_breath'],
        updatedAt: now,
      );
      expect(urgentDraft.hasUrgentSymptoms, isTrue);
    });
  });
}
