import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/theme/components/app_status_chip.dart';
import 'package:healthbase/features/auth/data/auth_repository.dart';
import 'package:healthbase/features/auth/domain/models/auth_user.dart';
import 'package:healthbase/features/daily_check/domain/models/daily_check.dart';
import 'package:healthbase/features/dashboard/data/dashboard_repository.dart';
import 'package:healthbase/features/dashboard/domain/models/dashboard_summary.dart';
import 'package:healthbase/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/profile/data/profile_repository.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}
class MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockProfileRepository mockProfileRepo;
  late MockDashboardRepository mockDashboardRepo;

  final sampleUser = AuthUser(
    id: 'u-1',
    email: 'test@healthbase.app',
    displayName: 'Alex Rivers',
  );

  final sampleProfile = HealthProfile(
    id: 'prof-dash-1',
    ownerAccountId: 'u-1',
    isSelf: true,
    displayName: 'Alex Rivers',
    preferredUnits: UnitSystem.metric,
    onboardingCompletedAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final now = DateTime.now();
  final sampleSummary = DashboardSummary(
    profileId: 'prof-dash-1',
    metrics: {
      MeasurementType.heartRate: MetricLatestState(
        type: MeasurementType.heartRate,
        latest: Measurement(
          id: 'm-1',
          profileId: 'prof-dash-1',
          type: MeasurementType.heartRate,
          heartRateBpm: 78.0,
          recordedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        trend: HealthTrendStatus.stable,
      ),
      MeasurementType.bloodPressure: MetricLatestState(
        type: MeasurementType.bloodPressure,
        latest: Measurement(
          id: 'm-2',
          profileId: 'prof-dash-1',
          type: MeasurementType.bloodPressure,
          systolicMmhg: 128.0,
          diastolicMmhg: 82.0,
          recordedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        trend: HealthTrendStatus.stable,
      ),
      MeasurementType.weight: MetricLatestState(
        type: MeasurementType.weight,
        latest: Measurement(
          id: 'm-3',
          profileId: 'prof-dash-1',
          type: MeasurementType.weight,
          weightKg: 74.2,
          recordedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        trend: HealthTrendStatus.stable,
      ),
      MeasurementType.temperature: MetricLatestState(
        type: MeasurementType.temperature,
        latest: Measurement(
          id: 'm-4',
          profileId: 'prof-dash-1',
          type: MeasurementType.temperature,
          temperatureCelsius: 36.7,
          recordedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        trend: HealthTrendStatus.stable,
      ),
      MeasurementType.bloodGlucose: MetricLatestState(
        type: MeasurementType.bloodGlucose,
        latest: null,
        trend: HealthTrendStatus.insufficientData,
      ),
    },
    todayDailyCheck: DailyCheck(
      id: 'dc-1',
      profileId: 'prof-dash-1',
      checkDate: now,
      feeling: CheckFeeling.good,
      medicationStatus: MedicationCheckStatus.yes,
      createdAt: now,
      updatedAt: now,
    ),
    lastUpdated: now,
  );

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockProfileRepo = MockProfileRepository();
    mockDashboardRepo = MockDashboardRepository();

    when(() => mockAuthRepo.currentUser).thenReturn(sampleUser);
    when(() => mockProfileRepo.getMyProfile()).thenAnswer((_) async => sampleProfile);
    when(() => mockDashboardRepo.watchDashboardSummary('prof-dash-1'))
        .thenAnswer((_) => Stream.value(sampleSummary));
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        myProfileProvider.overrideWith((ref) async => sampleProfile),
        profileRepositoryProvider.overrideWithValue(mockProfileRepo),
        dashboardRepositoryProvider.overrideWithValue(mockDashboardRepo),
        dashboardSummaryStreamProvider('prof-dash-1')
            .overrideWith((ref) => Stream.value(sampleSummary)),
      ],
      child: const MaterialApp(
        home: DashboardScreen(),
      ),
    );
  }

  group('DashboardScreen Widget Tests', () {
    testWidgets('renders greeting, name, and How am I doing question', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Alex Rivers'), findsOneWidget);
      expect(find.text('How am I doing?'), findsOneWidget);
      expect(find.text("Today's check complete"), findsOneWidget);
    });

    testWidgets('renders YOUR HEALTH TODAY real measurements grid', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('YOUR HEALTH TODAY'), findsOneWidget);

      // Heart rate
      expect(find.text('Heart rate'), findsWidgets);
      expect(find.text('78'), findsOneWidget);
      expect(find.text('BPM'), findsOneWidget);

      // Blood pressure
      expect(find.text('Blood pressure'), findsWidgets);
      expect(find.text('128/82'), findsOneWidget);
      expect(find.text('mmHg'), findsOneWidget);

      // Weight
      expect(find.text('Weight'), findsWidgets);
      expect(find.text('74.2'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);

      // Temperature
      expect(find.text('Temperature'), findsWidgets);
      expect(find.text('36.7'), findsOneWidget);
      expect(find.text('°C'), findsOneWidget);

      // Blood glucose empty state
      expect(find.text('Blood glucose'), findsWidgets);
      expect(find.text('--'), findsOneWidget);
      expect(find.text('No readings yet'), findsOneWidget);
    });

    testWidgets('renders YOUR TREND section with non-judgmental status chips', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('YOUR TREND'), findsOneWidget);
      expect(find.text('Current Baseline Directions'), findsOneWidget);

      // Stable chips
      expect(find.text('Stable'), findsWidgets);
      // Not enough history chip for glucose
      expect(find.text('Not enough history yet'), findsOneWidget);
    });

    testWidgets('renders QUICK ACTIONS panel buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('QUICK ACTIONS'), findsOneWidget);
      expect(find.text("Today's Check"), findsWidgets);
      expect(find.text('Record Vital'), findsOneWidget);
      expect(find.text('View History'), findsOneWidget);
      expect(find.text('View Trends'), findsOneWidget);
      expect(find.text('What Changed?'), findsOneWidget);
    });
  });
}
