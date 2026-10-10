import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/errors/failures.dart';
import 'package:healthbase/features/profile/data/profile_repository.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:healthbase/features/profile/presentation/controllers/profile_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockRepo;
  late ProviderContainer container;

  final sampleProfile = HealthProfile(
    id: 'prof-123',
    ownerAccountId: 'acc-123',
    isSelf: true,
    displayName: 'Alex',
    dateOfBirth: DateTime(1995, 5, 10),
    sex: SexType.male,
    heightCm: 175.0,
    weightKg: 70.0,
    preferredUnits: UnitSystem.metric,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(UnitSystem.metric);
    registerFallbackValue(SexType.male);
    registerFallbackValue(DateTime.now());
  });

  setUp(() async {
    mockRepo = MockProfileRepository();
    when(() => mockRepo.getMyProfile()).thenAnswer((_) async => sampleProfile);
    when(() => mockRepo.updatePreferredUnits(any())).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    await container.read(profileControllerProvider.notifier).loadProfile();
  });

  tearDown(() {
    container.dispose();
  });

  group('ProfileController Unit Tests', () {
    test('initial state loads myProfile from repository', () async {
      final controller = container.read(profileControllerProvider.notifier);
      await controller.loadProfile();

      final state = container.read(profileControllerProvider);
      expect(state.value, equals(sampleProfile));
      verify(() => mockRepo.getMyProfile()).called(greaterThanOrEqualTo(1));
    });

    test('updateProfile validates maximum display name length', () async {
      final controller = container.read(profileControllerProvider.notifier);
      final tooLongName = 'A' * 81;

      final result = await controller.updateProfile(displayName: tooLongName);
      expect(result, isFalse);

      final state = container.read(profileControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<ValidationFailure>());
      expect(
        (state.error as ValidationFailure).message,
        contains('Display name cannot exceed 80 characters'),
      );
    });

    test('updateProfile validates date of birth plausible bounds', () async {
      final controller = container.read(profileControllerProvider.notifier);

      // Future date
      final futureDate = DateTime.now().add(const Duration(days: 2));
      final futureResult = await controller.updateProfile(dateOfBirth: futureDate);
      expect(futureResult, isFalse);
      expect(
        (container.read(profileControllerProvider).error as ValidationFailure).message,
        contains('Date of birth cannot be in the future'),
      );

      // Too old / before 1900
      final ancientDate = DateTime(1850);
      final ancientResult = await controller.updateProfile(dateOfBirth: ancientDate);
      expect(ancientResult, isFalse);
      expect(
        (container.read(profileControllerProvider).error as ValidationFailure).message,
        contains('1900 or later'),
      );
    });

    test('updateProfile validates height bounds (40cm to 260cm)', () async {
      final controller = container.read(profileControllerProvider.notifier);

      // Height too low
      final lowResult = await controller.updateProfile(heightCm: 35.0);
      expect(lowResult, isFalse);
      expect(
        (container.read(profileControllerProvider).error as ValidationFailure).message,
        contains('Height must be between 40 cm and 260 cm'),
      );

      // Height too high
      final highResult = await controller.updateProfile(heightCm: 270.0);
      expect(highResult, isFalse);
      expect(
        (container.read(profileControllerProvider).error as ValidationFailure).message,
        contains('Height must be between 40 cm and 260 cm'),
      );
    });

    test('updateProfile validates weight bounds (1kg to 400kg)', () async {
      final controller = container.read(profileControllerProvider.notifier);

      // Weight zero
      final zeroResult = await controller.updateProfile(weightKg: 0.5);
      expect(zeroResult, isFalse);
      expect(
        (container.read(profileControllerProvider).error as ValidationFailure).message,
        contains('Weight must be between 1 kg and 400 kg'),
      );

      // Weight extreme
      final extremeResult = await controller.updateProfile(weightKg: 500.0);
      expect(extremeResult, isFalse);
      expect(
        (container.read(profileControllerProvider).error as ValidationFailure).message,
        contains('Weight must be between 1 kg and 400 kg'),
      );
    });

    test('updateProfile succeeds on valid data and persists to repo', () async {
      final updatedProfile = sampleProfile.copyWith(
        displayName: 'Alexander',
        heightCm: 180.0,
      );

      when(() => mockRepo.updateMyProfile(
            displayName: 'Alexander',
            dateOfBirth: any(named: 'dateOfBirth'),
            sex: any(named: 'sex'),
            heightCm: 180.0,
            weightKg: any(named: 'weightKg'),
          )).thenAnswer((_) async => updatedProfile);

      final controller = container.read(profileControllerProvider.notifier);
      final success = await controller.updateProfile(
        displayName: 'Alexander',
        heightCm: 180.0,
      );

      expect(success, isTrue);
      expect(container.read(profileControllerProvider).value, equals(updatedProfile));
    });

    test('completeOnboarding marks onboardingCompletedAt timestamp and updates repo', () async {
      final onboardedProfile = sampleProfile.copyWith(
        onboardingCompletedAt: DateTime.now(),
      );

      when(() => mockRepo.updateMyProfile(
            displayName: any(named: 'displayName'),
            dateOfBirth: any(named: 'dateOfBirth'),
            sex: any(named: 'sex'),
            heightCm: any(named: 'heightCm'),
            weightKg: any(named: 'weightKg'),
            onboardingCompletedAt: any(named: 'onboardingCompletedAt'),
          )).thenAnswer((_) async => onboardedProfile);

      final controller = container.read(profileControllerProvider.notifier);
      final success = await controller.completeOnboarding(
        displayName: 'Alex',
        preferredUnits: UnitSystem.imperial,
      );

      expect(success, isTrue);
      verify(() => mockRepo.updatePreferredUnits(UnitSystem.imperial)).called(1);
      verify(() => mockRepo.updateMyProfile(
            displayName: 'Alex',
            onboardingCompletedAt: any(named: 'onboardingCompletedAt'),
          )).called(1);
    });

    test('skipOnboarding marks onboarding completed without vitals', () async {
      final skippedProfile = sampleProfile.copyWith(
        onboardingCompletedAt: DateTime.now(),
      );

      when(() => mockRepo.updateMyProfile(
            onboardingCompletedAt: any(named: 'onboardingCompletedAt'),
          )).thenAnswer((_) async => skippedProfile);

      final controller = container.read(profileControllerProvider.notifier);
      final success = await controller.skipOnboarding(preferredUnits: UnitSystem.metric);

      expect(success, isTrue);
      verify(() => mockRepo.updatePreferredUnits(UnitSystem.metric)).called(1);
      verify(() => mockRepo.updateMyProfile(
            onboardingCompletedAt: any(named: 'onboardingCompletedAt'),
          )).called(1);
    });

    test('updatePreferredUnits optimistically updates state and notifies repository', () async {
      final controller = container.read(profileControllerProvider.notifier);
      final success = await controller.updatePreferredUnits(UnitSystem.imperial);

      expect(success, isTrue);
      expect(container.read(profileControllerProvider).value?.preferredUnits, UnitSystem.imperial);
      verify(() => mockRepo.updatePreferredUnits(UnitSystem.imperial)).called(1);
    });
  });
}
