import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:healthbase/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:healthbase/features/profile/data/profile_repository.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockRepo;

  final sampleProfile = HealthProfile(
    id: 'prof-123',
    ownerAccountId: 'acc-123',
    isSelf: true,
    displayName: 'Alex',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(UnitSystem.metric);
    registerFallbackValue(SexType.male);
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockRepo = MockProfileRepository();
    when(() => mockRepo.getMyProfile()).thenAnswer((_) async => sampleProfile);
    when(() => mockRepo.updatePreferredUnits(any())).thenAnswer((_) async {});
    when(() => mockRepo.updateMyProfile(
          displayName: any(named: 'displayName'),
          dateOfBirth: any(named: 'dateOfBirth'),
          sex: any(named: 'sex'),
          heightCm: any(named: 'heightCm'),
          weightKg: any(named: 'weightKg'),
          onboardingCompletedAt: any(named: 'onboardingCompletedAt'),
        )).thenAnswer((_) async => sampleProfile);
  });

  Widget buildSubject() {
    final testRouter = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const Scaffold(body: Text('Dashboard Placeholder')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp.router(
        routerConfig: testRouter,
      ),
    );
  }

  group('OnboardingScreen Widget Tests', () {
    testWidgets('renders Step 0 with non-diagnostic disclaimer and boundary notice', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('HealthBase Setup'), findsOneWidget);
      expect(find.text('Your Health. Your Baseline.'), findsOneWidget);
      expect(
        find.textContaining('HealthBase helps you monitor your health over time.'),
        findsOneWidget,
      );
      expect(find.textContaining('It does not diagnose medical conditions.'), findsOneWidget);
      expect(find.text('Continue to Setup'), findsOneWidget);
    });

    testWidgets('navigates through Step 1 and Step 2 smoothly', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // Tap Continue to Setup
      await tester.tap(find.text('Continue to Setup'));
      await tester.pumpAndSettle();

      // Step 1: Preferences & Name
      expect(find.text('Preferences & Name'), findsOneWidget);
      expect(find.text('Your Name or Nickname'), findsOneWidget);
      expect(find.text('Metric (kg, cm, °C)'), findsOneWidget);
      expect(find.text('Imperial (lbs, in, °F)'), findsOneWidget);

      // Tap Continue to Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Health Profile (Optional)
      expect(find.text('Health Profile (Optional)'), findsOneWidget);
      expect(find.text('Complete Setup'), findsOneWidget);
      expect(find.text('Skip and Go to Dashboard'), findsOneWidget);
    });

    testWidgets('Skip All triggers skipOnboarding on controller', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // Advance to step 1 so 'Skip All' action shows in AppBar
      await tester.tap(find.text('Continue to Setup'));
      await tester.pumpAndSettle();

      expect(find.text('Skip All'), findsOneWidget);
      await tester.tap(find.text('Skip All'));
      await tester.pump();

      verify(() => mockRepo.updateMyProfile(
            onboardingCompletedAt: any(named: 'onboardingCompletedAt'),
          )).called(1);
    });
  });
}
