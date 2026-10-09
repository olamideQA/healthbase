import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import '../models/health_insight.dart';

/// Pure functional, deterministic engine that computes longitudinal health insights.
///
/// Follows the HealthBase Playbook rules:
/// - Explicit 3-part sentence structure: WHAT + HOW MUCH + COMPARED WITH
/// - Strictly non-diagnostic and non-judgmental (zero diagnostic claims or labels)
/// - Purely rule-based (no AI / LLM models)
/// - Deterministic outlier dampening using median comparison
/// - Full measurement traceability for every generated insight
class InsightGenerator {
  const InsightGenerator._();

  static const int minRecentReadings = 3;
  static const int minBaselineReadings = 5;

  /// Meaningful delta thresholds required to declare a statistical shift.
  static const double hrDeltaThreshold = 4.0; // bpm
  static const double bpSysDeltaThreshold = 6.0; // mmHg
  static const double bpDiaDeltaThreshold = 4.0; // mmHg
  static const double tempDeltaThresholdC = 0.4; // °C
  static const double tempDeltaThresholdF = 0.7; // °F
  static const double weightDeltaThresholdKg = 0.8; // kg
  static const double weightDeltaThresholdLbs = 1.8; // lbs
  static const double glucoseDeltaThresholdMmol = 0.6; // mmol/L
  static const double glucoseDeltaThresholdMgdl = 10.8; // mg/dL

  /// Generate comprehensive insights across all 5 vital metrics.
  static List<HealthInsight> generateAllInsights({
    required List<Measurement> recentMeasurements,
    required List<Measurement> baselineMeasurements,
    UnitSystem unitSystem = UnitSystem.metric,
    String recentPeriodName = 'the last 7 days',
    String baselinePeriodName = 'the previous 30 days',
  }) {
    return [
      generateHeartRateInsight(
        recent: recentMeasurements,
        baseline: baselineMeasurements,
        recentPeriodName: recentPeriodName,
        baselinePeriodName: baselinePeriodName,
      ),
      generateBloodPressureInsight(
        recent: recentMeasurements,
        baseline: baselineMeasurements,
        recentPeriodName: recentPeriodName,
        baselinePeriodName: baselinePeriodName,
      ),
      generateTemperatureInsight(
        recent: recentMeasurements,
        baseline: baselineMeasurements,
        unitSystem: unitSystem,
        recentPeriodName: recentPeriodName,
        baselinePeriodName: baselinePeriodName,
      ),
      generateWeightInsight(
        recent: recentMeasurements,
        baseline: baselineMeasurements,
        unitSystem: unitSystem,
        recentPeriodName: recentPeriodName,
        baselinePeriodName: baselinePeriodName,
      ),
      generateBloodGlucoseInsight(
        recent: recentMeasurements,
        baseline: baselineMeasurements,
        unitSystem: unitSystem,
        recentPeriodName: recentPeriodName,
        baselinePeriodName: baselinePeriodName,
      ),
    ];
  }

  /// Generate Heart Rate insight.
  static HealthInsight generateHeartRateInsight({
    required List<Measurement> recent,
    required List<Measurement> baseline,
    String recentPeriodName = 'the last 7 days',
    String baselinePeriodName = 'the previous 30 days',
  }) {
    final recentItems = recent
        .where((m) => m.type == MeasurementType.heartRate && m.heartRateBpm != null)
        .toList();
    final baselineItems = baseline
        .where((m) => m.type == MeasurementType.heartRate && m.heartRateBpm != null)
        .toList();

    return _generateScalarInsight(
      id: 'insight_heart_rate',
      type: MeasurementType.heartRate,
      title: 'Heart Rate',
      metricNoun: 'heart rate',
      unit: 'bpm',
      recentItems: recentItems,
      baselineItems: baselineItems,
      valueExtractor: (m) => m.heartRateBpm!,
      deltaThreshold: hrDeltaThreshold,
      decimals: 0,
      recentPeriodName: recentPeriodName,
      baselinePeriodName: baselinePeriodName,
    );
  }

  /// Generate Blood Pressure insight (evaluating systolic and diastolic components).
  static HealthInsight generateBloodPressureInsight({
    required List<Measurement> recent,
    required List<Measurement> baseline,
    String recentPeriodName = 'the last 7 days',
    String baselinePeriodName = 'the previous 30 days',
  }) {
    final recentItems = recent
        .where((m) =>
            m.type == MeasurementType.bloodPressure &&
            m.systolicMmhg != null &&
            m.diastolicMmhg != null)
        .toList();
    final baselineItems = baseline
        .where((m) =>
            m.type == MeasurementType.bloodPressure &&
            m.systolicMmhg != null &&
            m.diastolicMmhg != null)
        .toList();

    final evidenceReadings = <InsightEvidenceItem>[
      ...recentItems.map((m) => InsightEvidenceItem(
            measurementId: m.id,
            recordedAt: m.recordedAt,
            primaryValue: m.systolicMmhg!,
            secondaryValue: m.diastolicMmhg!,
            unit: 'mmHg',
            isRecentWindow: true,
          )),
      ...baselineItems.map((m) => InsightEvidenceItem(
            measurementId: m.id,
            recordedAt: m.recordedAt,
            primaryValue: m.systolicMmhg!,
            secondaryValue: m.diastolicMmhg!,
            unit: 'mmHg',
            isRecentWindow: false,
          )),
    ];

    if (recentItems.length < minRecentReadings || baselineItems.length < minBaselineReadings) {
      final evidence = InsightEvidence(
        type: MeasurementType.bloodPressure,
        unit: 'mmHg',
        recentCount: recentItems.length,
        recentAverage: _mean(recentItems.map((m) => m.systolicMmhg!)),
        recentMedian: _median(recentItems.map((m) => m.systolicMmhg!)),
        recentSecondaryAverage: _mean(recentItems.map((m) => m.diastolicMmhg!)),
        recentSecondaryMedian: _median(recentItems.map((m) => m.diastolicMmhg!)),
        baselineCount: baselineItems.length,
        baselineAverage: _mean(baselineItems.map((m) => m.systolicMmhg!)),
        baselineMedian: _median(baselineItems.map((m) => m.systolicMmhg!)),
        baselineSecondaryAverage: _mean(baselineItems.map((m) => m.diastolicMmhg!)),
        baselineSecondaryMedian: _median(baselineItems.map((m) => m.diastolicMmhg!)),
        readings: evidenceReadings,
      );

      return HealthInsight(
        id: 'insight_blood_pressure',
        type: MeasurementType.bloodPressure,
        title: 'Blood Pressure',
        direction: InsightDirection.insufficientData,
        explanation:
            'Not enough history yet to compare blood pressure. Record at least $minRecentReadings readings in $recentPeriodName and $minBaselineReadings in $baselinePeriodName.',
        evidence: evidence,
        recentPeriodName: recentPeriodName,
        baselinePeriodName: baselinePeriodName,
      );
    }

    final recentSysAvg = _mean(recentItems.map((m) => m.systolicMmhg!));
    final recentSysMed = _median(recentItems.map((m) => m.systolicMmhg!));
    final recentDiaAvg = _mean(recentItems.map((m) => m.diastolicMmhg!));
    final recentDiaMed = _median(recentItems.map((m) => m.diastolicMmhg!));

    final baseSysAvg = _mean(baselineItems.map((m) => m.systolicMmhg!));
    final baseSysMed = _median(baselineItems.map((m) => m.systolicMmhg!));
    final baseDiaAvg = _mean(baselineItems.map((m) => m.diastolicMmhg!));
    final baseDiaMed = _median(baselineItems.map((m) => m.diastolicMmhg!));

    final baseSysMin = baselineItems.map((m) => m.systolicMmhg!).reduce((a, b) => a < b ? a : b);
    final baseSysMax = baselineItems.map((m) => m.systolicMmhg!).reduce((a, b) => a > b ? a : b);
    final baseDiaMin = baselineItems.map((m) => m.diastolicMmhg!).reduce((a, b) => a < b ? a : b);
    final baseDiaMax = baselineItems.map((m) => m.diastolicMmhg!).reduce((a, b) => a > b ? a : b);

    // Outlier dampening: effective delta combines mean & median shifts
    final sysDiff = _dampenedDiff(recentSysAvg, recentSysMed, baseSysAvg, baseSysMed);
    final diaDiff = _dampenedDiff(recentDiaAvg, recentDiaMed, baseDiaAvg, baseDiaMed);

    InsightDirection direction;
    String explanation;

    final isHigher = sysDiff >= bpSysDeltaThreshold || diaDiff >= bpDiaDeltaThreshold;
    final isLower = sysDiff <= -bpSysDeltaThreshold || diaDiff <= -bpDiaDeltaThreshold;

    final recentSysFmt = recentSysAvg.round();
    final recentDiaFmt = recentDiaAvg.round();
    final baseSysFmt = baseSysAvg.round();
    final baseDiaFmt = baseDiaAvg.round();

    if (isHigher) {
      direction = InsightDirection.higher;
      explanation =
          'Your average blood pressure over $recentPeriodName is $recentSysFmt/$recentDiaFmt mmHg, compared with $baseSysFmt/$baseDiaFmt mmHg during $baselinePeriodName.';
    } else if (isLower) {
      direction = InsightDirection.lower;
      explanation =
          'Your average blood pressure over $recentPeriodName is $recentSysFmt/$recentDiaFmt mmHg, compared with $baseSysFmt/$baseDiaFmt mmHg during $baselinePeriodName.';
    } else {
      direction = InsightDirection.withinRange;
      explanation =
          'Your recent blood pressure readings are within your recent personal range (${baseSysMin.round()}/${baseDiaMin.round()} – ${baseSysMax.round()}/${baseDiaMax.round()} mmHg).';
    }

    final evidence = InsightEvidence(
      type: MeasurementType.bloodPressure,
      unit: 'mmHg',
      recentCount: recentItems.length,
      recentAverage: recentSysAvg,
      recentMedian: recentSysMed,
      recentSecondaryAverage: recentDiaAvg,
      recentSecondaryMedian: recentDiaMed,
      baselineCount: baselineItems.length,
      baselineAverage: baseSysAvg,
      baselineMedian: baseSysMed,
      baselineSecondaryAverage: baseDiaAvg,
      baselineSecondaryMedian: baseDiaMed,
      personalRangeMin: baseSysMin,
      personalRangeMax: baseSysMax,
      personalRangeSecondaryMin: baseDiaMin,
      personalRangeSecondaryMax: baseDiaMax,
      readings: evidenceReadings,
    );

    return HealthInsight(
      id: 'insight_blood_pressure',
      type: MeasurementType.bloodPressure,
      title: 'Blood Pressure',
      direction: direction,
      explanation: explanation,
      evidence: evidence,
      recentPeriodName: recentPeriodName,
      baselinePeriodName: baselinePeriodName,
    );
  }

  /// Generate Temperature insight.
  static HealthInsight generateTemperatureInsight({
    required List<Measurement> recent,
    required List<Measurement> baseline,
    UnitSystem unitSystem = UnitSystem.metric,
    String recentPeriodName = 'the last 7 days',
    String baselinePeriodName = 'the previous 30 days',
  }) {
    final recentItems = recent
        .where((m) => m.type == MeasurementType.temperature && m.temperatureCelsius != null)
        .toList();
    final baselineItems = baseline
        .where((m) => m.type == MeasurementType.temperature && m.temperatureCelsius != null)
        .toList();

    final isMetric = unitSystem == UnitSystem.metric;
    final unit = isMetric ? '°C' : '°F';
    final deltaThreshold = isMetric ? tempDeltaThresholdC : tempDeltaThresholdF;

    double extractValue(Measurement m) {
      final c = m.temperatureCelsius!;
      return isMetric ? c : (c * 9.0 / 5.0) + 32.0;
    }

    return _generateScalarInsight(
      id: 'insight_temperature',
      type: MeasurementType.temperature,
      title: 'Body Temperature',
      metricNoun: 'body temperature',
      unit: unit,
      recentItems: recentItems,
      baselineItems: baselineItems,
      valueExtractor: extractValue,
      deltaThreshold: deltaThreshold,
      decimals: 1,
      recentPeriodName: recentPeriodName,
      baselinePeriodName: baselinePeriodName,
      unitSystem: unitSystem,
    );
  }

  /// Generate Weight insight.
  static HealthInsight generateWeightInsight({
    required List<Measurement> recent,
    required List<Measurement> baseline,
    UnitSystem unitSystem = UnitSystem.metric,
    String recentPeriodName = 'the last 7 days',
    String baselinePeriodName = 'the previous 30 days',
  }) {
    final recentItems = recent
        .where((m) => m.type == MeasurementType.weight && m.weightKg != null)
        .toList();
    final baselineItems = baseline
        .where((m) => m.type == MeasurementType.weight && m.weightKg != null)
        .toList();

    final isMetric = unitSystem == UnitSystem.metric;
    final unit = isMetric ? 'kg' : 'lbs';
    final deltaThreshold = isMetric ? weightDeltaThresholdKg : weightDeltaThresholdLbs;

    double extractValue(Measurement m) {
      final kg = m.weightKg!;
      return isMetric ? kg : kg * 2.20462;
    }

    return _generateScalarInsight(
      id: 'insight_weight',
      type: MeasurementType.weight,
      title: 'Weight',
      metricNoun: 'weight',
      unit: unit,
      recentItems: recentItems,
      baselineItems: baselineItems,
      valueExtractor: extractValue,
      deltaThreshold: deltaThreshold,
      decimals: 1,
      recentPeriodName: recentPeriodName,
      baselinePeriodName: baselinePeriodName,
      unitSystem: unitSystem,
    );
  }

  /// Generate Blood Glucose insight.
  static HealthInsight generateBloodGlucoseInsight({
    required List<Measurement> recent,
    required List<Measurement> baseline,
    UnitSystem unitSystem = UnitSystem.metric,
    String recentPeriodName = 'the last 7 days',
    String baselinePeriodName = 'the previous 30 days',
  }) {
    final recentItems = recent
        .where((m) => m.type == MeasurementType.bloodGlucose && m.glucoseMmolL != null)
        .toList();
    final baselineItems = baseline
        .where((m) => m.type == MeasurementType.bloodGlucose && m.glucoseMmolL != null)
        .toList();

    final isMetric = unitSystem == UnitSystem.metric;
    final unit = isMetric ? 'mmol/L' : 'mg/dL';
    final deltaThreshold = isMetric ? glucoseDeltaThresholdMmol : glucoseDeltaThresholdMgdl;

    double extractValue(Measurement m) {
      final mmol = m.glucoseMmolL!;
      return isMetric ? mmol : mmol * 18.0182;
    }

    return _generateScalarInsight(
      id: 'insight_blood_glucose',
      type: MeasurementType.bloodGlucose,
      title: 'Blood Glucose',
      metricNoun: 'blood glucose',
      unit: unit,
      recentItems: recentItems,
      baselineItems: baselineItems,
      valueExtractor: extractValue,
      deltaThreshold: deltaThreshold,
      decimals: 1,
      recentPeriodName: recentPeriodName,
      baselinePeriodName: baselinePeriodName,
      unitSystem: unitSystem,
    );
  }

  // --- Helper: Pure Scalar Insight Calculation ---

  static HealthInsight _generateScalarInsight({
    required String id,
    required MeasurementType type,
    required String title,
    required String metricNoun,
    required String unit,
    required List<Measurement> recentItems,
    required List<Measurement> baselineItems,
    required double Function(Measurement) valueExtractor,
    required double deltaThreshold,
    required int decimals,
    required String recentPeriodName,
    required String baselinePeriodName,
    UnitSystem unitSystem = UnitSystem.metric,
  }) {
    final evidenceReadings = <InsightEvidenceItem>[
      ...recentItems.map((m) => InsightEvidenceItem(
            measurementId: m.id,
            recordedAt: m.recordedAt,
            primaryValue: valueExtractor(m),
            unit: unit,
            isRecentWindow: true,
          )),
      ...baselineItems.map((m) => InsightEvidenceItem(
            measurementId: m.id,
            recordedAt: m.recordedAt,
            primaryValue: valueExtractor(m),
            unit: unit,
            isRecentWindow: false,
          )),
    ];

    if (recentItems.length < minRecentReadings || baselineItems.length < minBaselineReadings) {
      final recentValues = recentItems.map(valueExtractor);
      final baselineValues = baselineItems.map(valueExtractor);

      final evidence = InsightEvidence(
        type: type,
        unit: unit,
        recentCount: recentItems.length,
        recentAverage: _mean(recentValues),
        recentMedian: _median(recentValues),
        baselineCount: baselineItems.length,
        baselineAverage: _mean(baselineValues),
        baselineMedian: _median(baselineValues),
        readings: evidenceReadings,
      );

      return HealthInsight(
        id: id,
        type: type,
        title: title,
        direction: InsightDirection.insufficientData,
        explanation:
            'Not enough history yet to compare $metricNoun. Record at least $minRecentReadings readings in $recentPeriodName and $minBaselineReadings in $baselinePeriodName.',
        evidence: evidence,
        recentPeriodName: recentPeriodName,
        baselinePeriodName: baselinePeriodName,
        unitSystem: unitSystem,
      );
    }

    final recentValues = recentItems.map(valueExtractor).toList();
    final baselineValues = baselineItems.map(valueExtractor).toList();

    final recentAvg = _mean(recentValues);
    final recentMed = _median(recentValues);
    final baseAvg = _mean(baselineValues);
    final baseMed = _median(baselineValues);

    final baseMin = baselineValues.reduce((a, b) => a < b ? a : b);
    final baseMax = baselineValues.reduce((a, b) => a > b ? a : b);

    // Outlier-dampened delta: combines mean shift and median shift
    final diff = _dampenedDiff(recentAvg, recentMed, baseAvg, baseMed);

    InsightDirection direction;
    String explanation;

    final recentFmt = decimals == 0 ? '${recentAvg.round()}' : recentAvg.toStringAsFixed(decimals);
    final baseFmt = decimals == 0 ? '${baseAvg.round()}' : baseAvg.toStringAsFixed(decimals);
    final minFmt = decimals == 0 ? '${baseMin.round()}' : baseMin.toStringAsFixed(decimals);
    final maxFmt = decimals == 0 ? '${baseMax.round()}' : baseMax.toStringAsFixed(decimals);

    if (diff >= deltaThreshold) {
      direction = InsightDirection.higher;
      explanation =
          'Your average $metricNoun over $recentPeriodName is $recentFmt $unit, compared with $baseFmt $unit during $baselinePeriodName.';
    } else if (diff <= -deltaThreshold) {
      direction = InsightDirection.lower;
      explanation =
          'Your average $metricNoun over $recentPeriodName is $recentFmt $unit, compared with $baseFmt $unit during $baselinePeriodName.';
    } else {
      direction = InsightDirection.withinRange;
      explanation =
          'Your recent $metricNoun readings are within your recent personal range ($minFmt – $maxFmt $unit).';
    }

    final evidence = InsightEvidence(
      type: type,
      unit: unit,
      recentCount: recentItems.length,
      recentAverage: recentAvg,
      recentMedian: recentMed,
      baselineCount: baselineItems.length,
      baselineAverage: baseAvg,
      baselineMedian: baseMed,
      personalRangeMin: baseMin,
      personalRangeMax: baseMax,
      readings: evidenceReadings,
    );

    return HealthInsight(
      id: id,
      type: type,
      title: title,
      direction: direction,
      explanation: explanation,
      evidence: evidence,
      recentPeriodName: recentPeriodName,
      baselinePeriodName: baselinePeriodName,
      unitSystem: unitSystem,
    );
  }

  /// Calculates outlier-dampened difference:
  /// When an extreme outlier shifts the mean, the median acts as a dampener.
  static double _dampenedDiff(
    double recentAvg,
    double recentMed,
    double baseAvg,
    double baseMed,
  ) {
    final meanDiff = recentAvg - baseAvg;
    final medianDiff = recentMed - baseMed;

    // If mean and median disagree on sign or diverge substantially (skewness from outliers),
    // dampen by prioritizing the robust median difference.
    if ((meanDiff > 0 && medianDiff < 0) ||
        (meanDiff < 0 && medianDiff > 0) ||
        (meanDiff.abs() > medianDiff.abs() * 2.0)) {
      if (medianDiff.abs() < 2.0) {
        return medianDiff;
      }
      return (medianDiff * 0.85) + (meanDiff * 0.15);
    }

    return meanDiff;
  }

  static double _mean(Iterable<double> values) {
    if (values.isEmpty) return 0.0;
    final sum = values.fold<double>(0.0, (acc, v) => acc + v);
    return sum / values.length;
  }

  static double _median(Iterable<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = values.toList()..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[mid];
    }
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }
}
