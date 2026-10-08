import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/components/app_status_chip.dart';
import '../../daily_check/data/daily_check_repository.dart';
import '../../daily_check/domain/models/daily_check.dart';
import '../../measurements/data/measurement_repository.dart';
import '../../measurements/domain/models/measurement.dart';
import '../domain/models/dashboard_summary.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final measurementRepo = ref.watch(measurementRepositoryProvider);
  final dailyCheckRepo = ref.watch(dailyCheckRepositoryProvider);
  return DashboardRepository(
    measurementRepository: measurementRepo,
    dailyCheckRepository: dailyCheckRepo,
  );
});

final dashboardSummaryStreamProvider =
    StreamProvider.family<DashboardSummary, String>((ref, profileId) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.watchDashboardSummary(profileId);
});

class DashboardRepository {
  DashboardRepository({
    required this.measurementRepository,
    required this.dailyCheckRepository,
  });

  final MeasurementRepository measurementRepository;
  final DailyCheckRepository dailyCheckRepository;

  /// Reactive stream combining latest measurements, trend computation, and daily check status.
  Stream<DashboardSummary> watchDashboardSummary(String profileId) {
    late StreamController<DashboardSummary> controller;
    List<Measurement>? lastMeasurements;
    DailyCheck? lastDailyCheck;
    bool hasCheckEmitted = false;
    StreamSubscription<List<Measurement>>? measSub;
    StreamSubscription<DailyCheck?>? checkSub;

    void emitIfReady() {
      if (lastMeasurements == null || !hasCheckEmitted) return;
      final metricStates = <MeasurementType, MetricLatestState>{};

      for (final type in MeasurementType.values) {
        final typeMeasurements =
            lastMeasurements!.where((m) => m.type == type).toList();

        if (typeMeasurements.isEmpty) {
          metricStates[type] = MetricLatestState(
            type: type,
            trend: HealthTrendStatus.insufficientData,
          );
        } else {
          final latest = typeMeasurements.first;
          final trend = calculateTrend(typeMeasurements);
          metricStates[type] = MetricLatestState(
            type: type,
            latest: latest,
            trend: trend,
          );
        }
      }

      controller.add(DashboardSummary(
        profileId: profileId,
        metrics: metricStates,
        todayDailyCheck: lastDailyCheck,
        lastUpdated: DateTime.now(),
      ));
    }

    controller = StreamController<DashboardSummary>(
      onListen: () {
        measSub = measurementRepository
            .watchMeasurements(profileId: profileId, limit: 100)
            .listen((meas) {
          lastMeasurements = meas;
          emitIfReady();
        }, onError: controller.addError);

        checkSub = dailyCheckRepository
            .watchTodayCheck(profileId)
            .listen((check) {
          lastDailyCheck = check;
          hasCheckEmitted = true;
          emitIfReady();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await measSub?.cancel();
        await checkSub?.cancel();
        await controller.close();
      },
    );

    return controller.stream;
  }

  /// Calculates statistical trend without medical diagnostic claims.
  static HealthTrendStatus calculateTrend(List<Measurement> readings) {
    if (readings.length < 2) {
      return HealthTrendStatus.insufficientData;
    }

    final latest = readings.first;
    final historical = readings.sublist(1, math.min(readings.length, 10));

    final latestValue = _extractValue(latest);
    if (latestValue == null) return HealthTrendStatus.insufficientData;

    final historicalValues =
        historical.map(_extractValue).whereType<double>().toList();
    if (historicalValues.isEmpty) return HealthTrendStatus.insufficientData;

    final avgHistory =
        historicalValues.reduce((a, b) => a + b) / historicalValues.length;
    final diff = latestValue - avgHistory;

    // Thresholds per vital metric type
    final double threshold = switch (latest.type) {
      MeasurementType.heartRate => 4.0,
      MeasurementType.bloodPressure => 4.0,
      MeasurementType.weight => 0.4,
      MeasurementType.temperature => 0.2,
      MeasurementType.bloodGlucose => 0.4,
    };

    // If 5+ historical readings exist, check personal baseline bounds (mean +/- 1.5 SD)
    if (historicalValues.length >= 5) {
      final variance = historicalValues
              .map((v) => math.pow(v - avgHistory, 2))
              .reduce((a, b) => a + b) /
          historicalValues.length;
      final stdDev = math.sqrt(variance);

      if (stdDev > 0) {
        if (latestValue > avgHistory + (1.5 * stdDev)) {
          return HealthTrendStatus.higherThanBaseline;
        } else if (latestValue < avgHistory - (1.5 * stdDev)) {
          return HealthTrendStatus.lowerThanBaseline;
        }
      }
    }

    if (diff.abs() <= threshold) {
      return HealthTrendStatus.stable;
    } else if (diff > threshold) {
      return HealthTrendStatus.increased;
    } else {
      return HealthTrendStatus.decreased;
    }
  }

  static double? _extractValue(Measurement m) {
    return switch (m.type) {
      MeasurementType.heartRate => m.heartRateBpm,
      MeasurementType.bloodPressure => m.systolicMmhg,
      MeasurementType.weight => m.weightKg,
      MeasurementType.temperature => m.temperatureCelsius,
      MeasurementType.bloodGlucose => m.glucoseMmolL,
    };
  }
}
