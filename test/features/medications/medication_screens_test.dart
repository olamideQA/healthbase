import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/features/medications/data/medication_repository.dart';
import 'package:healthbase/features/medications/domain/models/medication.dart';
import 'package:healthbase/features/medications/presentation/screens/add_medication_screen.dart';
import 'package:healthbase/features/medications/presentation/screens/medication_detail_screen.dart';
import 'package:healthbase/features/medications/presentation/screens/medications_screen.dart';
import 'package:healthbase/features/profile/data/profile_repository.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockMedicationRepository extends Mock implements MedicationRepository {}

void main() {
  late MockProfileRepository mockProfileRepo;
  late MockMedicationRepository mockMedicationRepo;

  final sampleProfile = HealthProfile(
    id: 'user_1',
    ownerAccountId: 'user_1',
    isSelf: true,
    displayName: 'Olamide',
    preferredUnits: UnitSystem.metric,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final sampleMedication = Medication(
    id: 'med-1',
    profileId: 'user_1',
    name: 'Lisinopril',
    dosage: '10mg once daily',
    frequency: MedicationFrequency.daily,
    startDate: DateTime(2026, 1, 1),
    reminderTime: '08:00',
    notes: 'Take after breakfast',
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  const sampleAdherenceStats = MedicationAdherenceStats(
    scheduledCount: 30,
    takenCount: 27,
    missedCount: 3,
    notRecordedCount: 0,
  );

  setUpAll(() {
    registerFallbackValue(MedicationFrequency.daily);
    registerFallbackValue(MedicationEventStatus.taken);
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockProfileRepo = MockProfileRepository();
    mockMedicationRepo = MockMedicationRepository();

    when(() => mockProfileRepo.getMyProfile()).thenAnswer((_) async => sampleProfile);
    when(() => mockMedicationRepo.watchMedications(
          profileId: any(named: 'profileId'),
          activeOnly: any(named: 'activeOnly'),
        )).thenAnswer((_) => Stream.value([sampleMedication]));
    when(() => mockMedicationRepo.watchEventsForMedication(
          medicationId: any(named: 'medicationId'),
        )).thenAnswer((_) => Stream.value([]));
    when(() => mockMedicationRepo.getAdherenceStats(
          profileId: any(named: 'profileId'),
          medicationId: any(named: 'medicationId'),
          now: any(named: 'now'),
        )).thenAnswer((_) async => sampleAdherenceStats);
    when(() => mockMedicationRepo.recordEvent(
          profileId: any(named: 'profileId'),
          medicationId: any(named: 'medicationId'),
          scheduledTime: any(named: 'scheduledTime'),
          status: any(named: 'status'),
          notes: any(named: 'notes'),
        )).thenAnswer((_) async => 'event-1');
    when(() => mockMedicationRepo.addMedication(
          profileId: any(named: 'profileId'),
          name: any(named: 'name'),
          dosage: any(named: 'dosage'),
          frequency: any(named: 'frequency'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          reminderTime: any(named: 'reminderTime'),
          notes: any(named: 'notes'),
        )).thenAnswer((_) async => 'med-1');
    when(() => mockMedicationRepo.deleteMedication(any())).thenAnswer((_) async {});
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepo),
        myProfileProvider.overrideWith((ref) async => sampleProfile),
        medicationRepositoryProvider.overrideWithValue(mockMedicationRepo),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('MedicationsScreen Tests', () {
    testWidgets('renders header, safety boundary notice, and medication item',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(const MedicationsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Medication Tracker'), findsOneWidget);
      // Clinical safety boundary message
      expect(
        find.textContaining('HealthBase is a record-keeping tool. It never calculates or recommends dosages.'),
        findsOneWidget,
      );
      // Medication card items
      expect(find.text('Lisinopril'), findsOneWidget);
      expect(find.text('10mg once daily'), findsOneWidget);
      expect(find.text('Once Daily'), findsOneWidget);
      expect(find.text('Add Medication'), findsOneWidget);
    });

    testWidgets('renders empty state when no medications exist', (tester) async {
      when(() => mockMedicationRepo.watchMedications(
            profileId: any(named: 'profileId'),
            activeOnly: any(named: 'activeOnly'),
          )).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(buildTestableWidget(const MedicationsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('No medications tracked yet'), findsOneWidget);
      expect(
        find.text('Log your daily prescriptions to monitor adherence and view dose history.'),
        findsOneWidget,
      );
    });
  });

  group('AddMedicationScreen Tests', () {
    testWidgets('displays clinical safety banner and validates required fields',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const AddMedicationScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Add Medication'), findsOneWidget);
      // Non-calculation safety banner
      expect(
        find.textContaining('HealthBase does not calculate or recommend medication dosage'),
        findsOneWidget,
      );

      // Attempt submit without filling fields
      await tester.ensureVisible(find.text('Save Medication'));
      await tester.tap(find.text('Save Medication'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a medication name'), findsOneWidget);
      expect(find.text('Please enter dosage instructions'), findsOneWidget);
    });

    testWidgets('submits medication when valid inputs are provided', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const AddMedicationScreen()));
      await tester.pumpAndSettle();

      // Enter name and dosage into the text form fields
      await tester.enterText(
        find.byType(TextFormField).first,
        'Metformin',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '500mg twice daily with meals',
      );

      await tester.ensureVisible(find.text('Save Medication'));
      await tester.tap(find.text('Save Medication'));
      await tester.pumpAndSettle();

      verify(() => mockMedicationRepo.addMedication(
            profileId: 'user_1',
            name: 'Metformin',
            dosage: '500mg twice daily with meals',
            frequency: any(named: 'frequency'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            reminderTime: any(named: 'reminderTime'),
            notes: any(named: 'notes'),
          )).called(1);
    });
  });

  group('MedicationDetailScreen Tests', () {
    testWidgets('displays medication info and adherence statistics table',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            medicationRepositoryProvider.overrideWithValue(mockMedicationRepo),
            medicationAdherenceProvider((
              profileId: sampleMedication.profileId,
              medicationId: sampleMedication.id,
            )).overrideWith((ref) => Future.value(sampleAdherenceStats)),
          ],
          child: MaterialApp(
            home: MedicationDetailScreen(medication: sampleMedication),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lisinopril'), findsAtLeastNWidgets(1));
      expect(find.text('10mg once daily'), findsOneWidget);
      expect(find.text('Mark Taken'), findsOneWidget);
      expect(find.text('Mark Missed'), findsOneWidget);

      // Adherence stats
      expect(find.text('ADHERENCE STATISTICS'), findsOneWidget);
      expect(find.text('30'), findsOneWidget); // Scheduled
      expect(find.text('27'), findsOneWidget); // Recorded Taken
      expect(find.text('3'), findsOneWidget); // Recorded Missed
      expect(find.text('90.0%'), findsOneWidget);
    });

    testWidgets('records dose when Mark Taken is tapped', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            medicationRepositoryProvider.overrideWithValue(mockMedicationRepo),
            medicationAdherenceProvider((
              profileId: sampleMedication.profileId,
              medicationId: sampleMedication.id,
            )).overrideWith((ref) => Future.value(sampleAdherenceStats)),
          ],
          child: MaterialApp(
            home: MedicationDetailScreen(medication: sampleMedication),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark Taken'));
      await tester.pumpAndSettle();

      verify(() => mockMedicationRepo.recordEvent(
            profileId: 'user_1',
            medicationId: 'med-1',
            scheduledTime: any(named: 'scheduledTime'),
            status: MedicationEventStatus.taken,
          )).called(1);

      expect(find.text('Dose recorded as taken.'), findsOneWidget);
    });
  });
}
