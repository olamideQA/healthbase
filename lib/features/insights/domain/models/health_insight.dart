import 'package:flutter/foundation.dart';
import '../../../measurements/domain/models/measurement.dart';
import '../../../profile/domain/models/health_profile.dart';

/// Statistical direction of recent metric readings compared to historical baseline.
enum InsightDirection {
  higher('Higher than baseline'),
  lower('Lower than baseline'),
  withinRange('Within personal range'),
  insufficientData('Not enough history yet');

  const InsightDirection(this.displayName);
  final String displayName;

  bool get isMeaningful => this == InsightDirection.higher || this == InsightDirection.lower;
}

/// Traceable evidence point corresponding to a single measurement record.
@immutable
class InsightEvidenceItem {
  const InsightEvidenceItem({
    required this.measurementId,
    required this.recordedAt,
    required this.primaryValue,
    this.secondaryValue,
    required this.unit,
    required this.isRecentWindow,
  });

  final String measurementId;
  final DateTime recordedAt;
  final double primaryValue;
  final double? secondaryValue;
  final String unit;
  final bool isRecentWindow;

  String formatDisplayValue({int decimals = 0}) {
    if (secondaryValue != null) {
      return '${primaryValue.round()}/${secondaryValue!.round()} $unit';
    }
    if (decimals == 0) {
      return '${primaryValue.round()} $unit';
    }
    return '${primaryValue.toStringAsFixed(decimals)} $unit';
  }
}

/// Traceable statistical evidence backing up a generated health insight.
@immutable
class InsightEvidence {
  const InsightEvidence({
    required this.type,
    required this.unit,
    required this.recentCount,
    required this.recentAverage,
    required this.recentMedian,
    this.recentSecondaryAverage,
    this.recentSecondaryMedian,
    required this.baselineCount,
    required this.baselineAverage,
    required this.baselineMedian,
    this.baselineSecondaryAverage,
    this.baselineSecondaryMedian,
    this.personalRangeMin,
    this.personalRangeMax,
    this.personalRangeSecondaryMin,
    this.personalRangeSecondaryMax,
    required this.readings,
  });

  final MeasurementType type;
  final String unit;

  // Recent period statistics (e.g. last 7 days)
  final int recentCount;
  final double recentAverage;
  final double recentMedian;
  final double? recentSecondaryAverage;
  final double? recentSecondaryMedian;

  // Historical baseline statistics (e.g. previous 30 days)
  final int baselineCount;
  final double baselineAverage;
  final double baselineMedian;
  final double? baselineSecondaryAverage;
  final double? baselineSecondaryMedian;

  // Established personal range bounds
  final double? personalRangeMin;
  final double? personalRangeMax;
  final double? personalRangeSecondaryMin;
  final double? personalRangeSecondaryMax;

  // Raw underlying measurement evidence list
  final List<InsightEvidenceItem> readings;

  bool get hasSufficientData => recentCount >= 3 && baselineCount >= 5;
}

/// Deterministic, non-diagnostic insight explaining what changed, how much, and compared with what period.
@immutable
class HealthInsight {
  const HealthInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.direction,
    required this.explanation,
    required this.evidence,
    required this.recentPeriodName,
    required this.baselinePeriodName,
    this.unitSystem = UnitSystem.metric,
  });

  final String id;
  final MeasurementType type;
  final String title;
  final InsightDirection direction;

  /// The exact 3-part explanation:
  /// WHAT changed + HOW MUCH it changed + COMPARED WITH what period
  final String explanation;

  /// Traceable measurement records backing up this insight.
  final InsightEvidence evidence;

  final String recentPeriodName;
  final String baselinePeriodName;
  final UnitSystem unitSystem;

  bool get isMeaningful => direction.isMeaningful;
  bool get hasSufficientData => evidence.hasSufficientData;
}
