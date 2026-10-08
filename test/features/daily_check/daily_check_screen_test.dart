import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/safety/safety_boundaries.dart';
import 'package:healthbase/features/daily_check/data/daily_check_repository.dart';
import 'package:healthbase/features/daily_check/domain/models/daily_check.dart';
import 'package:healthbase/features/daily_check/presentation/screens/daily_check_screen.dart';
import 'package:healthbase/features/profile/data/profile_repository.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockDailyCheckRepository extends Mock implements DailyCheckRepository {}

void main() {
  late MockProfileRepository mockProfileRepo;
  late MockDailyCheckRepository mockDailyCheckRepo;

  final sampleProfile = HealthProfile(
    id: 'prof-daily-1',
    ownerAccountId: 'u1',
    isSelf: true,
    displayName: 'Test User',
    preferredUnits: UnitSystem.metric,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(CheckFeeling.good);
    registerFallbackValue(MedicationCheckStatus.yes);
    registerFallbackValue(DailyCheckDraft(
      profileId: 'prof-daily-1',
      updatedAt: DateTime.now(),
    ));
  });

  setUp(() {
    mockProfileRepo = MockProfileRepository();
    mockDailyCheckRepo = MockDailyCheckRepository();

    when(() => mockProfileRepo.getMyProfile()).thenAnswer((_) async => sampleProfile);
    when(() => mockDailyCheckRepo.getTodayCheck(any())).thenAnswer((_) async => null);
    when(() => mockDailyCheckRepo.getDraft(any())).thenAnswer((_) async => null);
    when(() => mockDailyCheckRepo.saveDraft(any())).thenAnswer((_) async {});
    when(() => mockDailyCheckRepo.clearDraft(any())).thenAnswer((_) async {});
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        myProfileProvider.overrideWith((ref) async => sampleProfile),
        profileRepositoryProvider.overrideWithValue(mockProfileRepo),
        dailyCheckRepositoryProvider.overrideWithValue(mockDailyCheckRepo),
      ],
      child: const MaterialApp(
        home: DailyCheckScreen(),
      ),
    );
  }

  group('DailyCheckScreen Widget Tests', () {
    testWidgets('renders step 0 feeling options and stepper header', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Daily Health Check'), findsOneWidget);
      expect(find.text('How are you feeling today?'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Okay'), findsOneWidget);
      expect(find.text('Not Great'), findsOneWidget);
      expect(find.text('Unwell'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('displays validation error if attempting Next without feeling', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Next without selecting feeling
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Please select how you are feeling today.'), findsOneWidget);
    });

    testWidgets('emergency banner appears when urgent symptom is selected', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 1. Select Good feeling
      await tester.tap(find.text('Good'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // 2. Vitals step - enter Heart Rate
      expect(find.text("Today's Vitals"), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '75');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // 3. Symptoms step
      expect(find.text('Any symptoms today?'), findsOneWidget);
      expect(find.text('Chest discomfort or pain'), findsOneWidget);

      // Select urgent symptom
      await tester.tap(find.text('Chest discomfort or pain'));
      await tester.pumpAndSettle();

      // Verify emergency disclaimer warning banner is prominently visible
      expect(find.text(SafetyBoundaries.emergencyWarningMessage), findsOneWidget);
    });

    testWidgets('renders completed view when today check already exists', (tester) async {
      final now = DateTime.now();
      final completed = DailyCheck(
        id: 'dc-done',
        profileId: 'prof-daily-1',
        checkDate: now,
        feeling: CheckFeeling.good,
        medicationStatus: MedicationCheckStatus.yes,
        symptoms: const [],
        createdAt: now,
        updatedAt: now,
      );

      when(() => mockDailyCheckRepo.getTodayCheck(any())).thenAnswer((_) async => completed);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text("Today's Health Check Complete"), findsOneWidget);
      expect(find.text('Recorded Summary'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Back to Dashboard'), 50.0);
      expect(find.text('Back to Dashboard'), findsOneWidget);
    });
  });
}
