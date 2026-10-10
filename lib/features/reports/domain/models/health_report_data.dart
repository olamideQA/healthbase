import 'package:flutter/foundation.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/medications/domain/models/medication.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';

enum ReportPeriod {
  days7('7 Days', 7),
  days30('30 Days', 30),
  days90('90 Days', 90),
  custom('Custom Range', null);

  const ReportPeriod(this.displayName, this.days);

  final String displayName;
  final int? days;
}

@immutable
class MetricStatSummary {
  const MetricStatSummary({
    required this.type,
    required this.readingCount,
    required this.average,
    required this.min,
    required this.max,
    required this.unit,
    this.secondaryAverage,
    this.secondaryMin,
    this.secondaryMax,
    this.secondaryUnit,
  });

  final MeasurementType type;
  final int readingCount;
  final double? average;
  final double? min;
  final double? max;
  final String unit;

  // Dual-value metrics (e.g. Diastolic BP)
  final double? secondaryAverage;
  final double? secondaryMin;
  final double? secondaryMax;
  final String? secondaryUnit;

  bool get hasData => readingCount > 0 && average != null;

  String get summaryText {
    if (!hasData) return 'No readings in period';
    if (type == MeasurementType.bloodPressure) {
      final sysAvg = average?.toStringAsFixed(0) ?? '--';
      final diaAvg = secondaryAverage?.toStringAsFixed(0) ?? '--';
      final sysMin = min?.toStringAsFixed(0) ?? '--';
      final sysMax = max?.toStringAsFixed(0) ?? '--';
      final diaMin = secondaryMin?.toStringAsFixed(0) ?? '--';
      final diaMax = secondaryMax?.toStringAsFixed(0) ?? '--';
      return 'Avg: $sysAvg/$diaAvg $unit (Range: $sysMin-$sysMax / $diaMin-$diaMax)';
    }
    final avgStr = average?.toStringAsFixed(1) ?? '--';
    final minStr = min?.toStringAsFixed(1) ?? '--';
    final maxStr = max?.toStringAsFixed(1) ?? '--';
    return 'Avg: $avgStr $unit (Range: $minStr - $maxStr)';
  }
}

@immutable
class SymptomReportItem {
  const SymptomReportItem({
    required this.name,
    required this.occurrences,
    required this.mostRecentDate,
  });

  final String name;
  final int occurrences;
  final DateTime mostRecentDate;
}

@immutable
class MedicationReportItem {
  const MedicationReportItem({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.stats,
  });

  final String name;
  final String dosage;
  final String frequency;
  final MedicationAdherenceStats stats;
}

@immutable
class HealthReportData {
  const HealthReportData({
    required this.profile,
    required this.startDate,
    required this.endDate,
    required this.period,
    required this.metricSummaries,
    required this.symptoms,
    required this.medications,
    required this.notableChanges,
    required this.generatedAt,
  });

  final HealthProfile profile;
  final DateTime startDate;
  final DateTime endDate;
  final ReportPeriod period;
  final List<MetricStatSummary> metricSummaries;
  final List<SymptomReportItem> symptoms;
  final List<MedicationReportItem> medications;
  final List<String> notableChanges;
  final DateTime generatedAt;

  static const String disclaimer =
      'HealthBase is a health monitoring and record-keeping tool. '
      'This report is not a medical diagnosis. '
      'Consult a licensed healthcare professional for clinical advice.';
}
