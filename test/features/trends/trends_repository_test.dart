import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/db/app_database.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:healthbase/features/trends/data/trends_repository.dart';
import 'package:healthbase/features/trends/domain/models/trend_chart_data.dart';

void main() {
  late AppDatabase db;
  late TrendsRepository repository;
  final now = DateTime(2026, 10, 10, 12, 0);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = TrendsRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('TrendsRepository queries SQLite and returns MetricTrendSeries', () async {
    for (int i = 1; i <= 5; i++) {
      await db.into(db.localMeasurementsTable).insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'hr_$i',
              profileId: 'user_1',
              type: 'heart_rate',
              heartRateBpm: drift.Value(70.0 + i),
              recordedAt: now.subtract(Duration(days: i)),
              syncStatus: const drift.Value('synced'),
            ),
          );
    }

    final series = await repository.getTrendSeries(
      profileId: 'user_1',
      type: MeasurementType.heartRate,
      period: TrendPeriod.days7,
      unitSystem: UnitSystem.metric,
      now: now,
    );

    expect(series.hasData, isTrue);
    expect(series.count, 5);
    expect(series.unit, 'bpm');
    expect(series.average, 73.0);
  });

  test('TrendsRepository watchTrendSeries stream emits updates', () async {
    final stream = repository.watchTrendSeries(
      profileId: 'user_1',
      type: MeasurementType.heartRate,
      period: TrendPeriod.days7,
      unitSystem: UnitSystem.metric,
    );

    final initialEmission = await stream.first;
    expect(initialEmission.hasData, isFalse);
  });
}
