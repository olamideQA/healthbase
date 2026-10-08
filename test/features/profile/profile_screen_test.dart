import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/features/auth/data/auth_repository.dart';
import 'package:healthbase/features/auth/domain/models/auth_user.dart';
import 'package:healthbase/features/profile/data/profile_repository.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:healthbase/features/profile/presentation/screens/profile_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockProfileRepository mockProfileRepo;
  late MockAuthRepository mockAuthRepo;

  final sampleProfile = HealthProfile(
    id: 'prof-123',
    ownerAccountId: 'u1',
    isSelf: true,
    displayName: 'Alex Smith',
    dateOfBirth: DateTime(1990, 1, 1),
    sex: SexType.male,
    heightCm: 180.0,
    weightKg: 75.0,
    preferredUnits: UnitSystem.metric,
    onboardingCompletedAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  const sampleUser = AuthUser(
    id: 'u1',
    email: 'alex@example.com',
  );

  setUpAll(() {
    registerFallbackValue(UnitSystem.metric);
    registerFallbackValue(SexType.male);
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockProfileRepo = MockProfileRepository();
    mockAuthRepo = MockAuthRepository();

    when(() => mockProfileRepo.getMyProfile()).thenAnswer((_) async => sampleProfile);
    when(() => mockProfileRepo.updatePreferredUnits(any())).thenAnswer((_) async {});
    when(() => mockAuthRepo.currentUser).thenReturn(sampleUser);
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepo),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
      child: const MaterialApp(
        home: ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('renders profile read view with baseline vitals and account email', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Health Profile'), findsOneWidget);
      expect(find.text('Alex Smith'), findsOneWidget);
      expect(find.text('alex@example.com'), findsOneWidget);
      expect(find.text('180.0 cm'), findsOneWidget);
      expect(find.text('75.0 kg'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('transitions to edit view and cancels back to read view', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Health Profile'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Health Profile'), findsNothing);
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('toggling unit preference calls repository', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockProfileRepo.updateMyProfile(
            displayName: any(named: 'displayName'),
            dateOfBirth: any(named: 'dateOfBirth'),
            sex: any(named: 'sex'),
            heightCm: any(named: 'heightCm'),
            weightKg: any(named: 'weightKg'),
          )).thenAnswer((_) async => sampleProfile.copyWith(preferredUnits: UnitSystem.imperial));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Tap imperial segmented button
      await tester.tap(find.text('Imperial (lbs, in, °F)'));
      await tester.pump();

      verify(() => mockProfileRepo.updatePreferredUnits(UnitSystem.imperial)).called(1);
    });
  });
}
