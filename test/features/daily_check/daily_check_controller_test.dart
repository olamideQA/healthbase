import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/features/daily_check/data/daily_check_repository.dart';
import 'package:healthbase/features/daily_check/domain/models/daily_check.dart';
import 'package:healthbase/features/daily_check/presentation/controllers/daily_check_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockDailyCheckRepository extends Mock implements DailyCheckRepository {}

void main() {
  late MockDailyCheckRepository mockRepo;
  late DailyCheckController controller;

  setUpAll(() {
    registerFallbackValue(CheckFeeling.good);
    registerFallbackValue(MedicationCheckStatus.yes);
    registerFallbackValue(DailyCheckDraft(
      profileId: 'dummy',
      updatedAt: DateTime.now(),
    ));
    registerFallbackValue(const <CheckSymptom>[]);
  });

  setUp(() {
    mockRepo = MockDailyCheckRepository();
    when(() => mockRepo.saveDraft(any())).thenAnswer((_) async {});
    when(() => mockRepo.clearDraft(any())).thenAnswer((_) async {});
    controller = DailyCheckController(mockRepo);
  });

  group('DailyCheckController State & Stepper Tests', () {
    test('initial state defaults', () {
      final state = controller.state;
      expect(state.currentStep, 0);
      expect(state.feeling, isNull);
      expect(state.heartRateBpm, isNull);
      expect(state.symptoms, isEmpty);
      expect(state.medicationStatus, isNull);
      expect(state.isLoading, isFalse);
      expect(state.hasDraft, isFalse);
    });

    test('step 0 validation requires feeling', () {
      expect(controller.validateCurrentStep(), 'Please select how you are feeling today.');
      expect(controller.nextStep('p-1'), isFalse);

      controller.setFeeling(CheckFeeling.good, profileId: 'p-1');
      expect(controller.validateCurrentStep(), isNull);
      expect(controller.nextStep('p-1'), isTrue);
      expect(controller.state.currentStep, 1);
    });

    test('step 1 validation requires plausible heart rate', () {
      controller.goToStep(1);

      // Missing HR
      expect(controller.validateCurrentStep(), 'Heart rate is required to complete your daily check.');
      expect(controller.nextStep('p-1'), isFalse);

      // Out of bounds HR low
      controller.setHeartRate(15.0);
      expect(controller.validateCurrentStep(), contains('Heart rate must be between 25 and 250 bpm'));

      // Out of bounds HR high
      controller.setHeartRate(300.0);
      expect(controller.validateCurrentStep(), contains('Heart rate must be between 25 and 250 bpm'));

      // Valid HR
      controller.setHeartRate(75.0);
      expect(controller.validateCurrentStep(), isNull);

      // Incoherent BP (systolic without diastolic)
      controller.setBloodPressure(120.0, null);
      expect(
        controller.validateCurrentStep(),
        'Both systolic and diastolic values are required for blood pressure.',
      );

      // Incoherent BP (systolic <= diastolic)
      controller.setBloodPressure(80.0, 120.0);
      expect(
        controller.validateCurrentStep(),
        'Systolic pressure must be greater than diastolic pressure.',
      );

      // Coherent BP
      controller.setBloodPressure(120.0, 80.0);
      expect(controller.validateCurrentStep(), isNull);
      expect(controller.nextStep('p-1'), isTrue);
      expect(controller.state.currentStep, 2);
    });

    test('step 2 symptoms toggle and emergency flag detection', () {
      controller.goToStep(2);
      expect(controller.state.hasUrgentSymptoms, isFalse);

      final headache = CheckSymptom.findByCode('headache')!;
      final chest = CheckSymptom.findByCode('chest_discomfort')!;

      controller.toggleSymptom(headache);
      expect(controller.state.symptoms, [headache]);
      expect(controller.state.hasUrgentSymptoms, isFalse);

      // Add emergency red-flag symptom
      controller.toggleSymptom(chest);
      expect(controller.state.hasUrgentSymptoms, isTrue);

      // Toggle off
      controller.toggleSymptom(chest);
      expect(controller.state.hasUrgentSymptoms, isFalse);

      // Symptoms are optional so nextStep succeeds
      expect(controller.nextStep('p-1'), isTrue);
      expect(controller.state.currentStep, 3);
    });

    test('step 3 medication adherence validation', () {
      controller.goToStep(3);

      expect(controller.validateCurrentStep(), 'Please select your medication adherence status.');
      expect(controller.nextStep('p-1'), isFalse);

      controller.setMedicationStatus(MedicationCheckStatus.yes);
      expect(controller.validateCurrentStep(), isNull);
      expect(controller.nextStep('p-1'), isTrue);
      expect(controller.state.currentStep, 4);
    });

    test('loadInitial restores saved draft correctly', () async {
      when(() => mockRepo.getTodayCheck('p-1')).thenAnswer((_) async => null);
      when(() => mockRepo.getDraft('p-1')).thenAnswer(
        (_) async => DailyCheckDraft(
          profileId: 'p-1',
          currentStep: 2,
          feeling: CheckFeeling.okay,
          heartRateBpm: 80.0,
          symptomCodes: const ['fatigue'],
          updatedAt: DateTime.now(),
        ),
      );

      await controller.loadInitial('p-1');

      expect(controller.state.hasDraft, isTrue);
      expect(controller.state.currentStep, 2);
      expect(controller.state.feeling, CheckFeeling.okay);
      expect(controller.state.heartRateBpm, 80.0);
      expect(controller.state.symptoms.first.symptomCode, 'fatigue');
    });

    test('submitCheck completes successfully and resets draft', () async {
      final now = DateTime.now();
      when(() => mockRepo.completeCheck(
            profileId: any(named: 'profileId'),
            feeling: any(named: 'feeling'),
            medicationStatus: any(named: 'medicationStatus'),
            symptoms: any(named: 'symptoms'),
            notes: any(named: 'notes'),
            heartRateBpm: any(named: 'heartRateBpm'),
            systolicMmhg: any(named: 'systolicMmhg'),
            diastolicMmhg: any(named: 'diastolicMmhg'),
            temperatureCelsius: any(named: 'temperatureCelsius'),
            weightKg: any(named: 'weightKg'),
            glucoseMmolL: any(named: 'glucoseMmolL'),
          )).thenAnswer(
        (_) async => DailyCheck(
          id: 'check-1',
          profileId: 'p-1',
          checkDate: now,
          feeling: CheckFeeling.good,
          medicationStatus: MedicationCheckStatus.yes,
          createdAt: now,
          updatedAt: now,
        ),
      );

      controller.setFeeling(CheckFeeling.good);
      controller.setHeartRate(72.0);
      controller.setMedicationStatus(MedicationCheckStatus.yes);

      final success = await controller.submitCheck('p-1');
      expect(success, isTrue);
      expect(controller.state.isSuccess, isTrue);
      expect(controller.state.hasExistingCheckToday, isTrue);
      expect(controller.state.todayCheck?.id, 'check-1');
      verify(() => mockRepo.clearDraft('p-1')).called(1);
    });
  });
}
