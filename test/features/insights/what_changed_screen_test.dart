import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/safety/safety_boundaries.dart';
import 'package:healthbase/features/insights/data/insight_repository.dart';
import 'package:healthbase/features/insights/domain/models/health_insight.dart';
import 'package:healthbase/features/insights/presentation/screens/what_changed_screen.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/profile/data/profile_repository.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:mocktail/mocktail.dart';

class MockInsightRepository extends Mock implements InsightRepository {}

void main() {
  late MockInsightRepository mockInsightRepository;

  final sampleProfile = HealthProfile(
    id: 'user_1',
    ownerAccountId: 'user_1',
    isSelf: true,
    displayName: 'Olamide',
    preferredUnits: UnitSystem.metric,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final sampleInsights = [
    HealthInsight(
      id: 'insight_heart_rate',
      type: MeasurementType.heartRate,
      title: 'Heart Rate',
      direction: InsightDirection.higher,
      explanation:
          'Your average heart rate over the last 7 days is 86 bpm, compared with 78 bpm during the previous 30 days.',
      evidence: InsightEvidence(
        type: MeasurementType.heartRate,
        unit: 'bpm',
        recentCount: 3,
        recentAverage: 86.0,
        recentMedian: 86.0,
        baselineCount: 5,
        baselineAverage: 78.0,
        baselineMedian: 78.0,
        readings: [
          InsightEvidenceItem(
            measurementId: 'm1',
            recordedAt: DateTime(2026, 10, 9, 8, 30),
            primaryValue: 86.0,
            unit: 'bpm',
            isRecentWindow: true,
          ),
          InsightEvidenceItem(
            measurementId: 'm2',
            recordedAt: DateTime(2026, 9, 25, 8, 0),
            primaryValue: 78.0,
            unit: 'bpm',
            isRecentWindow: false,
          ),
        ],
      ),
      recentPeriodName: 'the last 7 days',
      baselinePeriodName: 'the previous 30 days',
    ),
    const HealthInsight(
      id: 'insight_blood_pressure',
      type: MeasurementType.bloodPressure,
      title: 'Blood Pressure',
      direction: InsightDirection.insufficientData,
      explanation:
          'Not enough history yet to compare blood pressure. Record at least 3 readings in the last 7 days and 5 in the previous 30 days.',
      evidence: InsightEvidence(
        type: MeasurementType.bloodPressure,
        unit: 'mmHg',
        recentCount: 0,
        recentAverage: 0,
        recentMedian: 0,
        baselineCount: 0,
        baselineAverage: 0,
        baselineMedian: 0,
        readings: [],
      ),
      recentPeriodName: 'the last 7 days',
      baselinePeriodName: 'the previous 30 days',
    ),
  ];

  setUp(() {
    mockInsightRepository = MockInsightRepository();

    when(() => mockInsightRepository.watchInsights(
          profileId: any(named: 'profileId'),
          unitSystem: any(named: 'unitSystem'),
        )).thenAnswer((_) => Stream.value(sampleInsights));
  });

  setUpAll(() {
    registerFallbackValue(UnitSystem.metric);
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        myProfileProvider.overrideWith((ref) async => sampleProfile),
        insightRepositoryProvider.overrideWithValue(mockInsightRepository),
      ],
      child: const MaterialApp(
        home: WhatChangedScreen(),
      ),
    );
  }

  group('WhatChangedScreen Widget Tests', () {
    testWidgets('renders title, clinical disclaimer, and insight cards',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('What Changed?'), findsOneWidget);
      expect(find.text('WHAT CHANGED?'), findsOneWidget);
      expect(
        find.text('Comparing recent measurements with your historical baseline.'),
        findsOneWidget,
      );
      expect(find.text(SafetyBoundaries.baselineExplanation), findsOneWidget);

      // Heart Rate Card
      expect(find.text('Heart Rate'), findsOneWidget);
      expect(find.text('Higher than baseline'), findsOneWidget);
      expect(
        find.text(
          'Your average heart rate over the last 7 days is 86 bpm, compared with 78 bpm during the previous 30 days.',
        ),
        findsOneWidget,
      );
      expect(find.text('View Evidence'), findsOneWidget);

      // Blood Pressure Cold Start Card
      expect(find.text('Blood Pressure'), findsOneWidget);
      expect(find.text('Not enough history yet'), findsOneWidget);
      expect(find.text('Record Reading'), findsOneWidget);
    });

    testWidgets('tapping View Evidence opens bottom sheet with measurements',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Evidence'));
      await tester.pumpAndSettle();

      // Bottom sheet content
      expect(find.text('Heart Rate Evidence'), findsOneWidget);
      expect(find.text('STATISTICAL COMPARISON'), findsOneWidget);
      expect(find.text('UNDERLYING MEASUREMENTS (2)'), findsOneWidget);
      expect(find.text('Recent'), findsNWidgets(2));
      expect(find.text('Baseline'), findsNWidgets(2));
    });
  });
}
