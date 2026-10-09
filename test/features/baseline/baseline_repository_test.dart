import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/db/app_database.dart';
import 'package:healthbase/features/baseline/data/baseline_repository.dart';
import 'package:healthbase/features/baseline/domain/models/personal_baseline.dart';

void main() {
  late AppDatabase db;
  late BaselineRepository repository;
  final now = DateTime(2026, 10, 10, 12, 0);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = BaselineRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('BaselineRepository Database Tests', () {
    test('getPersonalBaseline queries SQLite and calculates baseline summary', () async {
      // Insert 6 heart rate readings into local SQLite
      for (int i = 0; i < 6; i++) {
        await db.into(db.localMeasurementsTable).insert(
              LocalMeasurementsTableCompanion.insert(
                id: 'hr_$i',
                profileId: 'user_1',
                type: 'heart_rate',
                heartRateBpm: drift.Value(70.0 + i),
                recordedAt: now.subtract(Duration(days: i + 1)),
                syncStatus: const drift.Value('synced'),
              ),
            );
      }

      final summary = await repository.getPersonalBaseline(
        profileId: 'user_1',
        window: BaselineWindow.days30,
        now: now,
      );

      expect(summary.heartRate.status, BaselineStatus.sufficient);
      expect(summary.heartRate.primaryStats!.measurementCount, 6);
      expect(summary.heartRate.primaryStats!.min, 70.0);
      expect(summary.heartRate.primaryStats!.max, 75.0);
      expect(summary.weight.status, BaselineStatus.insufficientData); // no weight readings
    });

    test('watchPersonalBaseline stream emits updates when measurements are added', () async {
      final stream = repository.watchPersonalBaseline(
        profileId: 'user_1',
        window: BaselineWindow.days7,
      );

      // Initially empty
      final initialSummary = await stream.first;
      expect(initialSummary.heartRate.status, BaselineStatus.insufficientData);

      // Insert 3 readings to meet the 7-day minimum threshold (minEntries: 3)
      for (int i = 0; i < 3; i++) {
        await db.into(db.localMeasurementsTable).insert(
              LocalMeasurementsTableCompanion.insert(
                id: 'hr_stream_$i',
                profileId: 'user_1',
                type: 'heart_rate',
                heartRateBpm: drift.Value(72.0 + i),
                recordedAt: DateTime.now().subtract(Duration(days: i)),
                syncStatus: const drift.Value('synced'),
              ),
            );
      }

      final updatedSummary = await stream.first;
      expect(updatedSummary.heartRate.status, BaselineStatus.sufficient);
      expect(updatedSummary.heartRate.primaryStats!.measurementCount, 3);
    });
  });
}
