import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/features/family/data/family_repository.dart';
import 'package:healthbase/features/family/domain/models/family_profile.dart';
import 'package:healthbase/features/family/presentation/screens/add_family_member_screen.dart';
import 'package:healthbase/features/family/presentation/screens/family_screen.dart';
import 'package:healthbase/features/family/presentation/widgets/share_profile_dialog.dart';
import 'package:healthbase/features/profile/data/profile_repository.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockFamilyRepository extends Mock implements FamilyRepository {}

void main() {
  late MockProfileRepository mockProfileRepo;
  late MockFamilyRepository mockFamilyRepo;

  final sampleSelfProfile = HealthProfile(
    id: 'user_1',
    ownerAccountId: 'user_1',
    isSelf: true,
    displayName: 'Olamide',
    preferredUnits: UnitSystem.metric,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final sampleMumProfile = FamilyProfile(
    id: 'prof-mum',
    ownerAccountId: 'user_1',
    isSelf: false,
    displayName: 'Mum',
    relationshipLabel: 'Mum',
    effectiveRole: AccessRole.manage,
    isOwner: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(AccessRole.view);
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockProfileRepo = MockProfileRepository();
    mockFamilyRepo = MockFamilyRepository();

    when(() => mockProfileRepo.getMyProfile()).thenAnswer((_) async => sampleSelfProfile);
    when(() => mockFamilyRepo.watchFamilyProfiles())
        .thenAnswer((_) => Stream.value([sampleMumProfile]));
    when(() => mockFamilyRepo.getFamilyProfiles())
        .thenAnswer((_) async => [sampleMumProfile]);
    when(() => mockFamilyRepo.createFamilyMember(
          displayName: any(named: 'displayName'),
          relationshipLabel: any(named: 'relationshipLabel'),
          dateOfBirth: any(named: 'dateOfBirth'),
          sex: any(named: 'sex'),
          heightCm: any(named: 'heightCm'),
          weightKg: any(named: 'weightKg'),
        )).thenAnswer((_) async => 'prof-new');
    when(() => mockFamilyRepo.createInvite(
          profileId: any(named: 'profileId'),
          role: any(named: 'role'),
          invitedEmail: any(named: 'invitedEmail'),
        )).thenAnswer((_) async => 'TESTCODE');
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepo),
        myProfileProvider.overrideWith((ref) async => sampleSelfProfile),
        familyRepositoryProvider.overrideWithValue(mockFamilyRepo),
        familyProfilesStreamProvider.overrideWith((ref) => Stream.value([sampleMumProfile])),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('FamilyScreen Tests', () {
    testWidgets('renders header, active profile banner, disclaimer, and member list',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(const FamilyScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Family Health'), findsOneWidget);
      expect(find.text('ACTIVE PROFILE'), findsOneWidget);
      expect(find.text('Olamide'), findsAtLeastNWidgets(1));
      expect(
        find.textContaining('does not assume biological relationships'),
        findsOneWidget,
      );
      expect(find.text('Mum'), findsAtLeastNWidgets(1));
      expect(find.text('Switch'), findsOneWidget);
      expect(find.text('Add Family Member'), findsOneWidget);
    });

    testWidgets('switches active profile context when Switch button is tapped',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(const FamilyScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();

      // After switching to Mum, the active banner displays Mum
      expect(find.text('Mum'), findsAtLeastNWidgets(1));
      expect(find.text('Switch to Self'), findsOneWidget);
    });
  });

  group('AddFamilyMemberScreen Tests', () {
    testWidgets('displays non-biological disclaimer, chips, and validates required name',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const AddFamilyMemberScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Add Family Member'), findsOneWidget);
      expect(
        find.textContaining('HealthBase supports all families and does not assume biological relationships'),
        findsOneWidget,
      );

      // Verify relationship chips
      expect(find.text('Mum'), findsOneWidget);
      expect(find.text('Dad'), findsOneWidget);
      expect(find.text('Spouse'), findsOneWidget);
      expect(find.text('Grandparent'), findsOneWidget);

      // Submit with empty name
      await tester.ensureVisible(find.text('Save Family Profile'));
      await tester.tap(find.text('Save Family Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a name for this family member'), findsOneWidget);
    });

    testWidgets('creates family member when valid data is entered', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const AddFamilyMemberScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'Dad',
      );

      // Select 'Dad' chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Dad'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save Family Profile'));
      await tester.tap(find.text('Save Family Profile'));
      await tester.pumpAndSettle();

      verify(() => mockFamilyRepo.createFamilyMember(
            displayName: 'Dad',
            relationshipLabel: 'Dad',
            dateOfBirth: any(named: 'dateOfBirth'),
            sex: any(named: 'sex'),
            heightCm: any(named: 'heightCm'),
            weightKg: any(named: 'weightKg'),
          )).called(1);
    });
  });

  group('ShareProfileDialog Tests', () {
    testWidgets('displays explicit permission roles and generates invite code',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            familyRepositoryProvider.overrideWithValue(mockFamilyRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ShareProfileDialog(profile: sampleMumProfile),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Share Mum'), findsOneWidget);
      expect(
        find.textContaining('Explicit Permission Rule: Access is never granted automatically'),
        findsOneWidget,
      );

      // Roles
      expect(find.text('View Only'), findsOneWidget);
      expect(find.text('Contributor'), findsOneWidget);
      expect(find.text('Manager'), findsOneWidget);

      // Tap Generate Code
      await tester.tap(find.text('Generate Code'));
      await tester.pumpAndSettle();

      expect(find.text('INVITE CODE'), findsOneWidget);
      expect(find.text('TESTCODE'), findsOneWidget);
      expect(find.text('Copy Code'), findsOneWidget);
    });
  });
}
