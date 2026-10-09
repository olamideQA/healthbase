import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/safety/safety_boundaries.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/profile/data/profile_repository.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:healthbase/features/trends/data/trends_repository.dart';
import 'package:healthbase/features/trends/domain/models/trend_chart_data.dart';
import 'package:healthbase/features/trends/presentation/screens/trends_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockTrendsRepository extends Mock implements TrendsRepository {}

void main() {
  late MockTrendsRepository mockTrendsRepository;

  final sampleProfile = HealthProfile(
    id: 'user_1',
    ownerAccountId: 'user_1',
    isSelf: true,
    displayName: 'Olamide',
    preferredUnits: UnitSystem.metric,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final samplePoints = [
    ChartDataPoint(
      timestamp: DateTime(2026, 10, 8, 8, 0),
      primaryValue: 72.0,
      unit: 'bpm',
      source: MeasurementSource.manual,
      measurementId: 'm1',
    ),
    ChartDataPoint(
      timestamp: DateTime(2026, 10, 9, 8, 0),
      primaryValue: 76.0,
      unit: 'bpm',
      source: MeasurementSource.manual,
      measurementId: 'm2',
    ),
  ];

  final sampleSeriesWithData = MetricTrendSeries(
    type: MeasurementType.heartRate,
    period: TrendPeriod.days30,
    unit: 'bpm',
    points: samplePoints,
    minY: 50.0,
    maxY: 100.0,
    average: 74.0,
    median: 74.0,
  );

  setUp(() {
    mockTrendsRepository = MockTrendsRepository();

    when(() => mockTrendsRepository.watchTrendSeries(
          profileId: any(named: 'profileId'),
          type: any(named: 'type'),
          period: any(named: 'period'),
          unitSystem: any(named: 'unitSystem'),
        )).thenAnswer((_) => Stream.value(sampleSeriesWithData));
  });

  setUpAll(() {
    registerFallbackValue(MeasurementType.heartRate);
    registerFallbackValue(TrendPeriod.days30);
    registerFallbackValue(UnitSystem.metric);
  });

  Widget createWidgetUnderTest({MetricTrendSeries? series}) {
    if (series != null) {
      when(() => mockTrendsRepository.watchTrendSeries(
            profileId: any(named: 'profileId'),
            type: any(named: 'type'),
            period: any(named: 'period'),
            unitSystem: any(named: 'unitSystem'),
          )).thenAnswer((_) => Stream.value(series));
    }

    return ProviderScope(
      overrides: [
        myProfileProvider.overrideWith((ref) async => sampleProfile),
        trendsRepositoryProvider.overrideWithValue(mockTrendsRepository),
      ],
      child: const MaterialApp(
        home: TrendsScreen(),
      ),
    );
  }

  group('TrendsScreen Widget Tests', () {
    testWidgets('renders screen controls, chart, inspected reading, and stats',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Screen Header & Clinical Disclaimer
      expect(find.text('Trends & Charts'), findsOneWidget);
      expect(find.text(SafetyBoundaries.baselineExplanation), findsOneWidget);

      // Period Segment Buttons
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('90 Days'), findsOneWidget);
      expect(find.text('1 Year'), findsOneWidget);

      // Metric Chips
      expect(find.text('Heart Rate'), findsOneWidget);
      expect(find.text('Blood Pressure'), findsOneWidget);
      expect(find.text('Body Temperature'), findsOneWidget);

      // Chart card & summary
      expect(find.text('Heart Rate Trend'), findsOneWidget);
      expect(find.text('INSPECTED READING'), findsOneWidget);
      expect(find.text('Period Summary'), findsOneWidget);
      expect(find.text('Average'), findsOneWidget);
      expect(find.text('Median'), findsOneWidget);
      expect(find.text('Readings'), findsOneWidget);
    });

    testWidgets('renders TrendInsufficientView when series has no data',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final emptySeries = MetricTrendSeries.empty(
        type: MeasurementType.heartRate,
        period: TrendPeriod.days30,
        unit: 'bpm',
      );

      await tester.pumpWidget(createWidgetUnderTest(series: emptySeries));
      await tester.pumpAndSettle();

      expect(find.text('More data needed'), findsOneWidget);
      expect(find.text('Record Reading'), findsOneWidget);
    });

    testWidgets('tapping different period button triggers watchTrendSeries with new period',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('7 Days'));
      await tester.pumpAndSettle();

      verify(() => mockTrendsRepository.watchTrendSeries(
            profileId: 'user_1',
            type: MeasurementType.heartRate,
            period: TrendPeriod.days7,
            unitSystem: UnitSystem.metric,
          )).called(1);
    });
  });
}
