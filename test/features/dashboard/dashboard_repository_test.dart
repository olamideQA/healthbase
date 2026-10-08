import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/theme/components/app_status_chip.dart';
import 'package:healthbase/features/daily_check/data/daily_check_repository.dart';
import 'package:healthbase/features/daily_check/domain/models/daily_check.dart';
import 'package:healthbase/features/dashboard/data/dashboard_repository.dart';
import 'package:healthbase/features/dashboard/domain/models/dashboard_summary.dart';
import 'package:healthbase/features/measurements/data/measurement_repository.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:mocktail/mocktail.dart';

class MockMeasurementRepository extends Mock implements MeasurementRepository {}
class MockDailyCheckRepository extends Mock implements DailyCheckRepository {}

void main() {
  late MockMeasurementRepository mockMeasurementRepo;
  late MockDailyCheckRepository mockDailyCheckRepo;
  late DashboardRepository repository;

  setUp(() {
    mockMeasurementRepo = MockMeasurementRepository();
    mockDailyCheckRepo = MockDailyCheckRepository();
    repository = DashboardRepository(
      measurementRepository: mockMeasurementRepo,
      dailyCheckRepository: mockDailyCheckRepo,
    );
  });

  group('DashboardSummary Time of Day Greeting Tests', () {
    test('getTimeOfDayGreeting returns expected text based on hour', () {
      expect(
        DashboardSummary.getTimeOfDayGreeting(DateTime(2026, 10, 8, 8, 30)),
        'Good morning',
      );
      expect(
        DashboardSummary.getTimeOfDayGreeting(DateTime(2026, 10, 8, 14, 0)),
        'Good afternoon',
      );
      expect(
        DashboardSummary.getTimeOfDayGreeting(DateTime(2026, 10, 8, 19, 45)),
        'Good evening',
      );
    });
  });

  group('DashboardRepository Trend Calculation Tests', () {
    test('returns insufficientData when fewer than 2 readings exist', () {
      final singleReading = [
        Measurement(
          id: '1',
          profileId: 'p-1',
          type: MeasurementType.heartRate,
          heartRateBpm: 72.0,
          recordedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      expect(
        DashboardRepository.calculateTrend(singleReading),
        HealthTrendStatus.insufficientData,
      );
      expect(
        DashboardRepository.calculateTrend([]),
        HealthTrendStatus.insufficientData,
      );
    });

    test('calculates stable trend when within delta threshold', () {
      final now = DateTime.now();
      final readings = [
        Measurement(
          id: '1',
          profileId: 'p-1',
          type: MeasurementType.heartRate,
          heartRateBpm: 73.0, // latest
          recordedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        Measurement(
          id: '2',
          profileId: 'p-1',
          type: MeasurementType.heartRate,
          heartRateBpm: 72.0, // history avg = 72
          recordedAt: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      expect(
        DashboardRepository.calculateTrend(readings),
        HealthTrendStatus.stable,
      );
    });

    test('calculates increased trend when delta exceeds positive threshold', () {
      final now = DateTime.now();
      final readings = [
        Measurement(
          id: '1',
          profileId: 'p-1',
          type: MeasurementType.heartRate,
          heartRateBpm: 85.0, // latest +15 bpm
          recordedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        Measurement(
          id: '2',
          profileId: 'p-1',
          type: MeasurementType.heartRate,
          heartRateBpm: 70.0,
          recordedAt: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      expect(
        DashboardRepository.calculateTrend(readings),
        HealthTrendStatus.increased,
      );
    });

    test('calculates decreased trend when delta falls below negative threshold', () {
      final now = DateTime.now();
      final readings = [
        Measurement(
          id: '1',
          profileId: 'p-1',
          type: MeasurementType.weight,
          weightKg: 68.0, // latest -2 kg
          recordedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        Measurement(
          id: '2',
          profileId: 'p-1',
          type: MeasurementType.weight,
          weightKg: 70.0,
          recordedAt: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      expect(
        DashboardRepository.calculateTrend(readings),
        HealthTrendStatus.decreased,
      );
    });
  });

  group('DashboardRepository watchDashboardSummary Tests', () {
    test('emits combined summary from measurements and daily check streams', () async {
      const profileId = 'prof-dash-1';
      final now = DateTime.now();

      final measurements = [
        Measurement(
          id: 'm-hr',
          profileId: profileId,
          type: MeasurementType.heartRate,
          heartRateBpm: 76.0,
          recordedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        Measurement(
          id: 'm-bp',
          profileId: profileId,
          type: MeasurementType.bloodPressure,
          systolicMmhg: 124.0,
          diastolicMmhg: 82.0,
          recordedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final todayCheck = DailyCheck(
        id: 'dc-1',
        profileId: profileId,
        checkDate: now,
        feeling: CheckFeeling.good,
        medicationStatus: MedicationCheckStatus.yes,
        createdAt: now,
        updatedAt: now,
      );

      when(() => mockMeasurementRepo.watchMeasurements(
            profileId: profileId,
            limit: any(named: 'limit'),
          )).thenAnswer((_) => Stream.value(measurements));

      when(() => mockDailyCheckRepo.watchTodayCheck(profileId))
          .thenAnswer((_) => Stream.value(todayCheck));

      final stream = repository.watchDashboardSummary(profileId);

      await expectLater(
        stream,
        emits(predicate<DashboardSummary>((summary) {
          return summary.profileId == profileId &&
              summary.hasTodayCheck &&
              summary.heartRate.latest?.heartRateBpm == 76.0 &&
              summary.bloodPressure.latest?.systolicMmhg == 124.0 &&
              summary.weight.latest == null;
        })),
      );
    });
  });
}
