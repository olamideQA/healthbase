import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/theme/components/app_button.dart';
import 'package:healthbase/features/daily_check/domain/models/daily_check.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/profile/data/profile_repository.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:healthbase/features/timeline/data/timeline_repository.dart';
import 'package:healthbase/features/timeline/domain/models/timeline_entry.dart';
import 'package:healthbase/features/timeline/presentation/screens/timeline_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockTimelineRepository extends Mock implements TimelineRepository {}

void main() {
  late MockTimelineRepository mockTimelineRepository;

  final sampleProfile = HealthProfile(
    id: 'user_1',
    ownerAccountId: 'user_1',
    isSelf: true,
    displayName: 'Olamide',
    preferredUnits: UnitSystem.metric,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(TimelineDateFilter.allTime);
    registerFallbackValue(TimelineMetricFilter.all);
  });

  setUp(() {
    mockTimelineRepository = MockTimelineRepository();
  });

  Widget createWidgetUnderTest({
    required List<TimelineDayRecord> initialRecords,
    bool hasMore = false,
  }) {
    when(() => mockTimelineRepository.getTimelinePage(
          profileId: any(named: 'profileId'),
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
          beforeCursor: any(named: 'beforeCursor'),
          dateFilter: any(named: 'dateFilter'),
          metricFilter: any(named: 'metricFilter'),
          customRange: any(named: 'customRange'),
        )).thenAnswer((_) async => TimelinePageResult(
          records: initialRecords,
          hasMore: hasMore,
          pageIndex: 0,
        ));

    return ProviderScope(
      overrides: [
        timelineRepositoryProvider.overrideWithValue(mockTimelineRepository),
        myProfileProvider.overrideWith((ref) async => sampleProfile),
      ],
      child: const MaterialApp(
        home: TimelineScreen(),
      ),
    );
  }

  group('TimelineScreen Widget Tests', () {
    testWidgets('renders empty timeline state with action buttons when 0 records exist',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(initialRecords: []));
      await tester.pumpAndSettle();

      expect(find.text('Health Timeline'), findsOneWidget);
      expect(find.text('Your Health Timeline is Empty'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Daily Check'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Record Vital'), findsOneWidget);
    });

    testWidgets('renders timeline day card with vitals, feelings, symptoms, and sync icon',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);

      final dayRecord = TimelineDayRecord(
        date: todayMidnight,
        heartRate: Measurement(
          id: 'm1',
          profileId: 'user_1',
          type: MeasurementType.heartRate,
          heartRateBpm: 74.0,
          recordedAt: now,
          createdAt: now,
          updatedAt: now,
          syncStatus: SyncStatus.synced,
        ),
        dailyCheck: DailyCheck(
          id: 'c1',
          profileId: 'user_1',
          checkDate: todayMidnight,
          feeling: CheckFeeling.good,
          medicationStatus: MedicationCheckStatus.yes,
          symptoms: const [
            CheckSymptom(symptomCode: 'headache', displayName: 'Headache'),
          ],
          createdAt: now,
          updatedAt: now,
        ),
        dailyCheckSyncStatus: SyncStatus.synced,
        allDayMeasurements: [
          Measurement(
            id: 'm1',
            profileId: 'user_1',
            type: MeasurementType.heartRate,
            heartRateBpm: 74.0,
            recordedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.synced,
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(initialRecords: [dayRecord]));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('74'), findsOneWidget);
      expect(find.text('bpm'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Headache'), findsOneWidget);
    });

    testWidgets('tapping day card opens entry details bottom sheet',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);

      final dayRecord = TimelineDayRecord(
        date: todayMidnight,
        heartRate: Measurement(
          id: 'm1',
          profileId: 'user_1',
          type: MeasurementType.heartRate,
          heartRateBpm: 72.0,
          notes: 'Morning resting pulse',
          recordedAt: now,
          createdAt: now,
          updatedAt: now,
          syncStatus: SyncStatus.synced,
        ),
        allDayMeasurements: [
          Measurement(
            id: 'm1',
            profileId: 'user_1',
            type: MeasurementType.heartRate,
            heartRateBpm: 72.0,
            notes: 'Morning resting pulse',
            recordedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.synced,
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(initialRecords: [dayRecord]));
      await tester.pumpAndSettle();

      // Tap card
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // Detail sheet should be rendered
      expect(find.text('RECORDED VITALS & MEASUREMENTS'), findsOneWidget);
      expect(find.text('“Morning resting pulse”'), findsOneWidget);
      expect(find.text('Manually Entered'), findsOneWidget);
    });

    testWidgets('switching metric filter triggers reload with selected metric',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(initialRecords: []));
      await tester.pumpAndSettle();

      // Tap 'Heart Rate' filter chip
      await tester.tap(find.text('Heart Rate'));
      await tester.pumpAndSettle();

      verify(() => mockTimelineRepository.getTimelinePage(
            profileId: 'user_1',
            pageIndex: 0,
            pageSize: 15,
            dateFilter: any(named: 'dateFilter'),
            metricFilter: TimelineMetricFilter.heartRate,
            customRange: any(named: 'customRange'),
          )).called(1);
    });

    testWidgets('renders filter empty state with Reset Filters button when filter has no matches',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(initialRecords: []));
      await tester.pumpAndSettle();

      // Tap 'Last 7 Days' date chip
      await tester.tap(find.text('Last 7 Days'));
      await tester.pumpAndSettle();

      expect(find.text('No records match this filter'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Reset Filters'), findsOneWidget);

      // Tap Reset Filters
      await tester.tap(find.widgetWithText(AppButton, 'Reset Filters'));
      await tester.pumpAndSettle();

      verify(() => mockTimelineRepository.getTimelinePage(
            profileId: 'user_1',
            pageIndex: 0,
            pageSize: 15,
            dateFilter: TimelineDateFilter.allTime,
            metricFilter: TimelineMetricFilter.all,
            customRange: any(named: 'customRange'),
          )).called(greaterThanOrEqualTo(1));
    });
  });
}
