import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/db/app_database.dart';
import 'package:healthbase/core/sync/sync_engine.dart';
import 'package:healthbase/features/daily_check/domain/models/daily_check.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/timeline/data/timeline_repository.dart';
import 'package:healthbase/features/timeline/domain/models/timeline_entry.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/drift.dart' as drift;

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  late AppDatabase db;
  late MockSyncEngine mockSyncEngine;
  late TimelineRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockSyncEngine = MockSyncEngine();
    when(() => mockSyncEngine.pushPendingMeasurements(any()))
        .thenAnswer((_) async => 0);
    when(() => mockSyncEngine.syncProfile(any())).thenAnswer((_) async {});

    repository = TimelineRepository(db: db, syncEngine: mockSyncEngine);
  });

  tearDown(() async {
    await db.close();
  });

  group('TimelineRepository Unit Tests', () {
    test('0 records returns empty timeline result', () async {
      final result = await repository.getTimelinePage(
        profileId: 'user_1',
        dateFilter: TimelineDateFilter.allTime,
      );

      expect(result.records, isEmpty);
      expect(result.hasMore, isFalse);
      expect(result.pageIndex, 0);
    });

    test('1 record correctly aggregates single day with measurements and daily check', () async {
      final now = DateTime(2026, 10, 8, 10, 30);
      final checkDate = DateTime(2026, 10, 8);

      // Insert measurement
      await db.into(db.localMeasurementsTable).insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'm1',
              profileId: 'user_1',
              type: 'heart_rate',
              heartRateBpm: const drift.Value(72.0),
              recordedAt: now,
              syncStatus: const drift.Value('synced'),
            ),
          );

      // Insert daily check
      await db.into(db.localDailyChecksTable).insert(
            LocalDailyChecksTableCompanion.insert(
              id: 'c1',
              profileId: 'user_1',
              checkDate: checkDate,
              feeling: 'good',
              medicationStatus: 'yes',
              syncStatus: const drift.Value('synced'),
            ),
          );

      // Insert symptom
      await db.into(db.localDailyCheckSymptomsTable).insert(
            LocalDailyCheckSymptomsTableCompanion.insert(
              id: 's1',
              dailyCheckId: 'c1',
              symptomCode: 'headache',
              isUrgent: const drift.Value(false),
            ),
          );

      final result = await repository.getTimelinePage(
        profileId: 'user_1',
        dateFilter: TimelineDateFilter.allTime,
      );

      expect(result.records.length, 1);
      final entry = result.records.first;
      expect(entry.date, checkDate);
      expect(entry.heartRate?.heartRateBpm, 72.0);
      expect(entry.dailyCheck?.feeling, CheckFeeling.good);
      expect(entry.medicationStatus, MedicationCheckStatus.yes);
      expect(entry.symptoms.length, 1);
      expect(entry.symptoms.first.symptomCode, 'headache');
      expect(entry.syncStatus, SyncStatus.synced);
      expect(result.hasMore, isFalse);
    });

    test('missing measurements handles partial data smoothly', () async {
      // Day 1: Only measurements (no daily check)
      final day1 = DateTime(2026, 10, 8, 9, 0);
      await db.into(db.localMeasurementsTable).insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'm_d1',
              profileId: 'user_1',
              type: 'blood_pressure',
              systolicMmhg: const drift.Value(120.0),
              diastolicMmhg: const drift.Value(80.0),
              recordedAt: day1,
              syncStatus: const drift.Value('synced'),
            ),
          );

      // Day 2: Only daily check (no measurements)
      final day2 = DateTime(2026, 10, 7);
      await db.into(db.localDailyChecksTable).insert(
            LocalDailyChecksTableCompanion.insert(
              id: 'c_d2',
              profileId: 'user_1',
              checkDate: day2,
              feeling: 'not_great',
              medicationStatus: 'no',
              syncStatus: const drift.Value('synced'),
            ),
          );

      final result = await repository.getTimelinePage(
        profileId: 'user_1',
        dateFilter: TimelineDateFilter.allTime,
      );

      expect(result.records.length, 2);
      // Day 1
      expect(result.records[0].date, DateTime(2026, 10, 8));
      expect(result.records[0].bloodPressure?.systolicMmhg, 120.0);
      expect(result.records[0].dailyCheck, isNull);
      expect(result.records[0].symptoms, isEmpty);

      // Day 2
      expect(result.records[1].date, day2);
      expect(result.records[1].bloodPressure, isNull);
      expect(result.records[1].dailyCheck?.feeling, CheckFeeling.notGreat);
      expect(result.records[1].medicationStatus, MedicationCheckStatus.no);
    });

    test('offline records reflect pending sync status on day record', () async {
      final now = DateTime(2026, 10, 8, 14, 0);

      await db.into(db.localMeasurementsTable).insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'm_offline',
              profileId: 'user_1',
              type: 'temperature',
              temperatureCelsius: const drift.Value(37.1),
              recordedAt: now,
              syncStatus: const drift.Value('pending_insert'),
            ),
          );

      final result = await repository.getTimelinePage(
        profileId: 'user_1',
        dateFilter: TimelineDateFilter.allTime,
      );

      expect(result.records.length, 1);
      expect(result.records.first.syncStatus, SyncStatus.pendingInsert);
    });

    test('100 records and large history respects page bounds and pagination', () async {
      final baseDate = DateTime(2026, 10, 8);

      // Insert 100 days of data (pageSize is 15)
      for (int i = 0; i < 100; i++) {
        final d = baseDate.subtract(Duration(days: i));
        await db.into(db.localMeasurementsTable).insert(
              LocalMeasurementsTableCompanion.insert(
                id: 'm_$i',
                profileId: 'user_1',
                type: 'heart_rate',
                heartRateBpm: drift.Value(60.0 + (i % 30)),
                recordedAt: DateTime(d.year, d.month, d.day, 12, 0),
                syncStatus: const drift.Value('synced'),
              ),
            );
      }

      // Page 0: should return 15 records with hasMore = true
      final page0 = await repository.getTimelinePage(
        profileId: 'user_1',
        pageIndex: 0,
        pageSize: 15,
        dateFilter: TimelineDateFilter.allTime,
      );

      expect(page0.records.length, 15);
      expect(page0.hasMore, isTrue);
      expect(page0.nextCursor, isNotNull);
      expect(page0.records.first.date, DateTime(2026, 10, 8));

      // Page 1: using nextCursor
      final page1 = await repository.getTimelinePage(
        profileId: 'user_1',
        pageIndex: 1,
        pageSize: 15,
        beforeCursor: page0.nextCursor,
        dateFilter: TimelineDateFilter.allTime,
      );

      expect(page1.records.length, 15);
      expect(page1.hasMore, isTrue);
      // Ensure records on Page 1 are strictly older than Page 0
      expect(page1.records.first.date.isBefore(page0.records.last.date), isTrue);
    });

    test('date filtering excludes records outside the specified range', () async {
      final today = DateTime.now();
      final insideDate = today.subtract(const Duration(days: 2));
      final outsideDate = today.subtract(const Duration(days: 45));

      await db.into(db.localMeasurementsTable).insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'm_in',
              profileId: 'user_1',
              type: 'heart_rate',
              heartRateBpm: const drift.Value(75.0),
              recordedAt: insideDate,
              syncStatus: const drift.Value('synced'),
            ),
          );

      await db.into(db.localMeasurementsTable).insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'm_out',
              profileId: 'user_1',
              type: 'heart_rate',
              heartRateBpm: const drift.Value(85.0),
              recordedAt: outsideDate,
              syncStatus: const drift.Value('synced'),
            ),
          );

      // Filter: last 7 days
      final result7d = await repository.getTimelinePage(
        profileId: 'user_1',
        dateFilter: TimelineDateFilter.last7Days,
      );

      expect(result7d.records.length, 1);
      expect(result7d.records.first.heartRate?.heartRateBpm, 75.0);

      // Filter: custom range targeting only outsideDate
      final customResult = await repository.getTimelinePage(
        profileId: 'user_1',
        dateFilter: TimelineDateFilter.custom,
        customRange: DateTimeRange(
          start: outsideDate.subtract(const Duration(days: 1)),
          end: outsideDate.add(const Duration(days: 1)),
        ),
      );

      expect(customResult.records.length, 1);
      expect(customResult.records.first.heartRate?.heartRateBpm, 85.0);
    });

    test('metric filtering only returns days matching selected metric', () async {
      final day1 = DateTime(2026, 10, 8, 10, 0);
      final day2 = DateTime(2026, 10, 7, 10, 0);

      // Day 1 has blood glucose
      await db.into(db.localMeasurementsTable).insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'm_glucose',
              profileId: 'user_1',
              type: 'blood_glucose',
              glucoseMmolL: const drift.Value(5.5),
              recordedAt: day1,
              syncStatus: const drift.Value('synced'),
            ),
          );

      // Day 2 has only heart rate
      await db.into(db.localMeasurementsTable).insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'm_hr',
              profileId: 'user_1',
              type: 'heart_rate',
              heartRateBpm: const drift.Value(68.0),
              recordedAt: day2,
              syncStatus: const drift.Value('synced'),
            ),
          );

      // Filter for blood glucose
      final glucoseOnly = await repository.getTimelinePage(
        profileId: 'user_1',
        dateFilter: TimelineDateFilter.allTime,
        metricFilter: TimelineMetricFilter.bloodGlucose,
      );

      expect(glucoseOnly.records.length, 1);
      expect(glucoseOnly.records.first.glucose?.glucoseMmolL, 5.5);
    });
  });
}
