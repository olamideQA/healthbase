import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:healthbase/features/measurements/data/measurement_repository.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/measurements/presentation/screens/add_measurement_screen.dart';
import 'package:healthbase/features/profile/data/profile_repository.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockMeasurementRepository extends Mock implements MeasurementRepository {}

void main() {
  late MockProfileRepository mockProfileRepo;
  late MockMeasurementRepository mockMeasurementRepo;

  final sampleProfile = HealthProfile(
    id: 'prof-p1',
    ownerAccountId: 'u1',
    isSelf: true,
    displayName: 'Safety User',
    preferredUnits: UnitSystem.metric,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final sampleMeasurement = Measurement(
    id: 'm1',
    profileId: 'prof-p1',
    type: MeasurementType.bloodPressure,
    systolicMmhg: 120.0,
    diastolicMmhg: 80.0,
    source: MeasurementSource.manual,
    provenance: MeasurementProvenance.manuallyEntered,
    recordedAt: DateTime.now(),
    syncStatus: SyncStatus.synced,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(sampleMeasurement);
    registerFallbackValue(MeasurementType.bloodPressure);
  });

  setUp(() {
    mockProfileRepo = MockProfileRepository();
    mockMeasurementRepo = MockMeasurementRepository();

    when(() => mockProfileRepo.getMyProfile()).thenAnswer((_) async => sampleProfile);
    when(() => mockMeasurementRepo.createMeasurement(any()))
        .thenAnswer((_) async => sampleMeasurement);
  });

  Widget buildSubject(Widget screen) {
    final router = GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(
          path: '/test',
          builder: (context, state) => screen,
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepo),
        measurementRepositoryProvider.overrideWithValue(mockMeasurementRepo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('AddMeasurementScreen - Clinical Safety Integration', () {
    testWidgets('entering Hypertensive Crisis BP displays live UrgentCareAlertBanner', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildSubject(const AddMeasurementScreen(initialType: MeasurementType.bloodPressure)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Systolic Pressure (mmHg)'), findsOneWidget);
      expect(find.text('Diastolic Pressure (mmHg)'), findsOneWidget);

      // Enter crisis BP: 200 / 125 mmHg
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '200');
      await tester.enterText(textFields.at(1), '125');
      await tester.pumpAndSettle();

      // Verify Urgent Care Alert Banner is triggered in live form
      expect(find.text('Hypertensive Crisis Range Detected'), findsOneWidget);
      expect(find.text('Emergency Care Info (911 / 112)'), findsOneWidget);
    });

    testWidgets('submitting physically implausible values (sys <= dia) is rejected', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildSubject(const AddMeasurementScreen(initialType: MeasurementType.bloodPressure)),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      // Systolic 70, Diastolic 100 (Sys < Dia)
      await tester.enterText(textFields.at(0), '70');
      await tester.enterText(textFields.at(1), '100');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save Measurement'));
      await tester.tap(find.text('Save Measurement'));
      await tester.pumpAndSettle();

      // Repository createMeasurement must NOT be called
      verifyNever(() => mockMeasurementRepo.createMeasurement(any()));
      expect(find.textContaining('outside physically plausible boundaries'), findsOneWidget);
    });
  });
}
