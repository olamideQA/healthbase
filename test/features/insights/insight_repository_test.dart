import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/db/app_database.dart';
import 'package:healthbase/features/insights/data/insight_repository.dart';
import 'package:healthbase/features/insights/domain/models/health_insight.dart';

void main() {
  late AppDatabase db;
  late InsightRepository repository;
  final now = DateTime(2026, 10, 10, 12, 0);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = InsightRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('InsightRepository queries SQLite and generates insights', () async {
    // Insert 3 recent heart rate readings
    for (int i = 1; i <= 3; i++) {
      await db.into(db.localMeasurementsTable).insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'recent_$i',
              profileId: 'user_1',
              type: 'heart_rate',
              heartRateBpm: drift.Value(85.0 + i),
              recordedAt: now.subtract(Duration(days: i)),
              syncStatus: const drift.Value('synced'),
            ),
          );
    }

    // Insert 5 baseline heart rate readings
    for (int i = 1; i <= 5; i++) {
      await db.into(db.localMeasurementsTable).insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'baseline_$i',
              profileId: 'user_1',
              type: 'heart_rate',
              heartRateBpm: const drift.Value(72.0),
              recordedAt: now.subtract(Duration(days: 8 + (i * 2))),
              syncStatus: const drift.Value('synced'),
            ),
          );
    }

    final insights = await repository.getInsights(
      profileId: 'user_1',
      now: now,
    );

    expect(insights.length, 5);
    final hrInsight = insights.firstWhere((i) => i.id == 'insight_heart_rate');
    expect(hrInsight.direction, InsightDirection.higher);
    expect(hrInsight.hasSufficientData, isTrue);
    expect(hrInsight.evidence.readings.length, 8);
  });

  test('InsightRepository watchInsights stream emits reactive updates', () async {
    final stream = repository.watchInsights(profileId: 'user_1');

    final emission = stream.first;

    // Insert a measurement
    await db.into(db.localMeasurementsTable).insert(
          LocalMeasurementsTableCompanion.insert(
            id: 'm_live',
            profileId: 'user_1',
            type: 'heart_rate',
            heartRateBpm: const drift.Value(75.0),
            recordedAt: DateTime.now(),
            syncStatus: const drift.Value('synced'),
          ),
        );

    final result = await emission;
    expect(result.length, 5);
  });
}
