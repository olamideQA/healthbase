import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/safety/safety_boundaries.dart';
import 'package:healthbase/features/baseline/data/baseline_repository.dart';
import 'package:healthbase/features/baseline/domain/models/personal_baseline.dart';
import 'package:healthbase/features/baseline/presentation/screens/personal_baseline_screen.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/profile/data/profile_repository.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:mocktail/mocktail.dart';

class MockBaselineRepository extends Mock implements BaselineRepository {}

void main() {
  late MockBaselineRepository mockBaselineRepository;

  final sampleProfile = HealthProfile(
    id: 'user_1',
    ownerAccountId: 'user_1',
    isSelf: true,
    displayName: 'Olamide',
    preferredUnits: UnitSystem.metric,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final establishedSummary = PersonalBaselineSummary(
    profileId: 'user_1',
    window: BaselineWindow.days30,
    calculatedAt: DateTime(2026, 10, 10),
    heartRate: const MetricBaseline(
      type: MeasurementType.heartRate,
      window: BaselineWindow.days30,
      status: BaselineStatus.sufficient,
      statusMessage: 'Recent personal range established',
      primaryStats: StatisticalRange(
        average: 73.5,
        median: 74.0,
        min: 68.0,
        max: 80.0,
        standardDeviation: 3.2,
        measurementCount: 15,
      ),
      recentTrend: RecentTrend.stable,
      latestValue: 74.0,
    ),
    bloodPressure: const MetricBaseline(
      type: MeasurementType.bloodPressure,
      window: BaselineWindow.days30,
      status: BaselineStatus.insufficientData,
      statusMessage: 'Not enough history yet',
      recentTrend: RecentTrend.insufficientData,
    ),
    temperature: const MetricBaseline(
      type: MeasurementType.temperature,
      window: BaselineWindow.days30,
      status: BaselineStatus.insufficientData,
      statusMessage: 'Not enough history yet',
      recentTrend: RecentTrend.insufficientData,
    ),
    weight: const MetricBaseline(
      type: MeasurementType.weight,
      window: BaselineWindow.days30,
      status: BaselineStatus.insufficientData,
      statusMessage: 'Not enough history yet',
      recentTrend: RecentTrend.insufficientData,
    ),
    bloodGlucose: const MetricBaseline(
      type: MeasurementType.bloodGlucose,
      window: BaselineWindow.days30,
      status: BaselineStatus.insufficientData,
      statusMessage: 'Not enough history yet',
      recentTrend: RecentTrend.insufficientData,
    ),
  );

  setUpAll(() {
    registerFallbackValue(BaselineWindow.days30);
  });

  setUp(() {
    mockBaselineRepository = MockBaselineRepository();
  });

  Widget createWidgetUnderTest({PersonalBaselineSummary? summary}) {
    when(() => mockBaselineRepository.watchPersonalBaseline(
          profileId: any(named: 'profileId'),
          window: any(named: 'window'),
        )).thenAnswer((_) => Stream.value(summary ?? establishedSummary));

    return ProviderScope(
      overrides: [
        baselineRepositoryProvider.overrideWithValue(mockBaselineRepository),
        myProfileProvider.overrideWith((ref) async => sampleProfile),
      ],
      child: const MaterialApp(
        home: PersonalBaselineScreen(),
      ),
    );
  }

  group('PersonalBaselineScreen Widget Tests', () {
    testWidgets('renders header, segmented window buttons, and clinical disclaimer',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Personal Baseline'), findsOneWidget);
      expect(find.text('Last 7 Days'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsOneWidget);
      expect(find.text('Last 90 Days'), findsOneWidget);
      expect(find.text('ABOUT YOUR PERSONAL RANGE'), findsOneWidget);
      expect(find.text(SafetyBoundaries.baselineExplanation), findsOneWidget);
    });

    testWidgets('renders established range card and cold start insufficient cards',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Established Heart Rate Card
      expect(find.text('RECENT PERSONAL RANGE'), findsOneWidget);
      expect(find.text('68 – 80 bpm'), findsOneWidget);
      expect(find.text('Median'), findsOneWidget);
      expect(find.text('74'), findsOneWidget);
      expect(find.text('Stable'), findsOneWidget);

      // Cold start cards (Blood Pressure, Temperature, Weight, Glucose)
      expect(find.text('Not enough history yet'), findsNWidgets(4));
      expect(find.text('Record Reading'), findsNWidgets(4));
    });

    testWidgets('toggling window segment switches active window query',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap 'Last 7 Days'
      await tester.tap(find.text('Last 7 Days'));
      await tester.pumpAndSettle();

      verify(() => mockBaselineRepository.watchPersonalBaseline(
            profileId: 'user_1',
            window: BaselineWindow.days7,
          )).called(1);
    });
  });
}
