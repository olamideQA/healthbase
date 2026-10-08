import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:healthbase/features/measurements/data/measurement_repository.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/measurements/presentation/screens/add_measurement_screen.dart';
import 'package:healthbase/features/measurements/presentation/screens/measurements_history_screen.dart';
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
    displayName: 'Test User',
    preferredUnits: UnitSystem.metric,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final sampleMeasurement = Measurement(
    id: 'm1',
    profileId: 'prof-p1',
    type: MeasurementType.heartRate,
    heartRateBpm: 72.0,
    source: MeasurementSource.manual,
    provenance: MeasurementProvenance.manuallyEntered,
    recordedAt: DateTime.now(),
    syncStatus: SyncStatus.synced,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(sampleMeasurement);
    registerFallbackValue(MeasurementType.heartRate);
  });

  setUp(() {
    mockProfileRepo = MockProfileRepository();
    mockMeasurementRepo = MockMeasurementRepository();

    when(() => mockProfileRepo.getMyProfile()).thenAnswer((_) async => sampleProfile);
    when(() => mockMeasurementRepo.watchMeasurements(
          profileId: any(named: 'profileId'),
          typeFilter: any(named: 'typeFilter'),
        )).thenAnswer((_) => Stream.value([sampleMeasurement]));
    when(() => mockMeasurementRepo.createMeasurement(any()))
        .thenAnswer((_) async => sampleMeasurement);
    when(() => mockMeasurementRepo.deleteMeasurement(any(), any()))
        .thenAnswer((_) async {});
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

  group('Measurements Widget Tests', () {
    testWidgets('AddMeasurementScreen renders input fields and records metric', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildSubject(const AddMeasurementScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Record Measurement'), findsOneWidget);
      expect(find.text('Measurement Type'), findsOneWidget);
      expect(find.text('Heart Rate (bpm)'), findsOneWidget);

      // Enter heart rate
      await tester.enterText(find.byType(TextFormField).first, '72');
      await tester.pump();

      // Submit
      await tester.ensureVisible(find.text('Save Measurement'));
      await tester.tap(find.text('Save Measurement'));
      await tester.pump();

      verify(() => mockMeasurementRepo.createMeasurement(any())).called(1);
    });

    testWidgets('MeasurementsHistoryScreen displays measurement cards with sync badges', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildSubject(const MeasurementsHistoryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Measurement History'), findsOneWidget);
      expect(find.text('Heart Rate'), findsWidgets);
      expect(find.text('72'), findsOneWidget);
      expect(find.text('bpm'), findsOneWidget);
      expect(find.text('Manually Entered'), findsOneWidget);

      // Delete icon is rendered
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });
}
