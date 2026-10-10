import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:healthbase/features/daily_check/domain/models/daily_check.dart';
import 'package:healthbase/features/insights/domain/models/health_insight.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/medications/domain/models/medication.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:healthbase/features/reports/domain/models/health_report_data.dart';

class ReportGeneratorService {
  const ReportGeneratorService();

  /// Build deterministic HealthReportData from raw models.
  HealthReportData buildReportData({
    required HealthProfile profile,
    required DateTime startDate,
    required DateTime endDate,
    required ReportPeriod period,
    required List<Measurement> measurements,
    required List<DailyCheck> dailyChecks,
    required List<Medication> medications,
    required List<MedicationEvent> medicationEvents,
    required List<HealthInsight> insights,
  }) {
    // 1. Metric Summaries
    final isMetric = profile.preferredUnits != UnitSystem.imperial;
    final summaries = <MetricStatSummary>[
      _computeHrSummary(measurements),
      _computeBpSummary(measurements),
      _computeTempSummary(measurements, isMetric),
      _computeWeightSummary(measurements, isMetric),
      _computeGlucoseSummary(measurements, isMetric),
    ];

    // 2. Symptoms aggregation
    final symptomCounts = <String, ({int count, DateTime latest})>{};
    for (final check in dailyChecks) {
      for (final symptom in check.symptoms) {
        final symptomName = symptom.displayName;
        final existing = symptomCounts[symptomName];
        if (existing == null) {
          symptomCounts[symptomName] = (count: 1, latest: check.checkDate);
        } else {
          symptomCounts[symptomName] = (
            count: existing.count + 1,
            latest: check.checkDate.isAfter(existing.latest)
                ? check.checkDate
                : existing.latest,
          );
        }
      }
    }

    final symptomsList = symptomCounts.entries.map((e) {
      return SymptomReportItem(
        name: e.key,
        occurrences: e.value.count,
        mostRecentDate: e.value.latest,
      );
    }).toList()
      ..sort((a, b) => b.occurrences.compareTo(a.occurrences));

    // 3. Medication adherence aggregation
    final medicationItems = medications.map((med) {
      final events = medicationEvents.where((e) => e.medicationId == med.id).toList();
      final stats = MedicationAdherenceStats.fromEvents(
        scheduledCount: events.length,
        events: events,
      );
      return MedicationReportItem(
        name: med.name,
        dosage: med.dosage,
        frequency: med.frequency.displayName,
        stats: stats,
      );
    }).toList();

    // 4. Notable changes from insights
    final notableChanges = insights.map((i) => i.explanation).toList();

    return HealthReportData(
      profile: profile,
      startDate: startDate,
      endDate: endDate,
      period: period,
      metricSummaries: summaries,
      symptoms: symptomsList,
      medications: medicationItems,
      notableChanges: notableChanges,
      generatedAt: DateTime.now(),
    );
  }

  /// Generate a professional PDF document from HealthReportData.
  Future<Uint8List> generatePdfBytes(HealthReportData data) async {
    final pdf = pw.Document(
      title: 'HealthBase Health Report - ${data.profile.displayName ?? "Record"}',
      author: 'HealthBase Application',
    );

    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(data, dateFormat),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Clinical Mandatory Disclaimer Banner
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'NOTICE: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                ),
                pw.Expanded(
                  child: pw.Text(
                    'HealthBase is a health monitoring and record-keeping tool. This report is not a medical diagnosis. '
                    'Share this summary with your qualified healthcare provider for clinical evaluation.',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Section 1: Patient / Profile Overview
          _buildPatientSection(data, dateFormat, timeFormat),
          pw.SizedBox(height: 16),

          // Section 2: Vitals & Measurements Table (Averages & Ranges)
          _buildVitalsSection(data),
          pw.SizedBox(height: 16),

          // Section 3: Medication Adherence
          _buildMedicationSection(data),
          pw.SizedBox(height: 16),

          // Section 4: Logged Symptoms
          _buildSymptomsSection(data, dateFormat),
          pw.SizedBox(height: 16),

          // Section 5: Notable Changes & Insights
          if (data.notableChanges.isNotEmpty) ...[
            _buildNotableChangesSection(data),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfHeader(HealthReportData data, DateFormat dateFormat) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue700, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'HEALTHBASE',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                  letterSpacing: 1.2,
                ),
              ),
              pw.Text(
                'Health Monitoring & Record-Keeping Report',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Text(
            'Period: ${dateFormat.format(data.startDate)} - ${dateFormat.format(data.endDate)}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'HealthBase Report · Not a medical diagnosis',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPatientSection(HealthReportData data, DateFormat df, DateFormat tf) {
    final name = data.profile.displayName ?? 'Primary Profile';
    final units = data.profile.preferredUnits == UnitSystem.imperial ? 'Imperial' : 'Metric';

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('RECORD INFORMATION', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Profile: $name', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Preferred Units: $units', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Generated: ${df.format(data.generatedAt)} ${tf.format(data.generatedAt)}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildVitalsSection(HealthReportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('MEASUREMENT SUMMARY & RANGES', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5),
            1: const pw.FlexColumnWidth(1.2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableHeader('Vital Sign / Metric'),
                _tableHeader('Readings'),
                _tableHeader('Average'),
                _tableHeader('Recorded Range'),
              ],
            ),
            ...data.metricSummaries.map((metric) {
              String avg = '--';
              String range = '--';
              if (metric.hasData) {
                if (metric.type == MeasurementType.bloodPressure) {
                  avg = '${metric.average?.toStringAsFixed(0)} / ${metric.secondaryAverage?.toStringAsFixed(0)} ${metric.unit}';
                  range = '${metric.min?.toStringAsFixed(0)}-${metric.max?.toStringAsFixed(0)} / ${metric.secondaryMin?.toStringAsFixed(0)}-${metric.secondaryMax?.toStringAsFixed(0)}';
                } else {
                  avg = '${metric.average?.toStringAsFixed(1)} ${metric.unit}';
                  range = '${metric.min?.toStringAsFixed(1)} - ${metric.max?.toStringAsFixed(1)} ${metric.unit}';
                }
              }

              return pw.TableRow(
                children: [
                  _tableCell(metric.type.displayName),
                  _tableCell('${metric.readingCount}', align: pw.TextAlign.center),
                  _tableCell(avg),
                  _tableCell(range),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildMedicationSection(HealthReportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('MEDICATION ADHERENCE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.SizedBox(height: 6),
        if (data.medications.isEmpty)
          pw.Text('No active medications tracked during this period.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(1.2),
              5: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _tableHeader('Medication'),
                  _tableHeader('Dosage (User Stated)'),
                  _tableHeader('Frequency'),
                  _tableHeader('Taken'),
                  _tableHeader('Missed'),
                  _tableHeader('Adherence'),
                ],
              ),
              ...data.medications.map((m) {
                final rate = m.stats.recordedAdherenceRate != null
                    ? '${m.stats.recordedAdherenceRate!.toStringAsFixed(0)}%'
                    : 'N/A';
                return pw.TableRow(
                  children: [
                    _tableCell(m.name),
                    _tableCell(m.dosage),
                    _tableCell(m.frequency),
                    _tableCell('${m.stats.takenCount}', align: pw.TextAlign.center),
                    _tableCell('${m.stats.missedCount}', align: pw.TextAlign.center),
                    _tableCell(rate, align: pw.TextAlign.center),
                  ],
                );
              }),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildSymptomsSection(HealthReportData data, DateFormat df) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('LOGGED SYMPTOMS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.SizedBox(height: 6),
        if (data.symptoms.isEmpty)
          pw.Text('No symptoms recorded during this period.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _tableHeader('Reported Symptom'),
                  _tableHeader('Occurrences'),
                  _tableHeader('Most Recent'),
                ],
              ),
              ...data.symptoms.map((s) {
                return pw.TableRow(
                  children: [
                    _tableCell(s.name),
                    _tableCell('${s.occurrences}', align: pw.TextAlign.center),
                    _tableCell(df.format(s.mostRecentDate)),
                  ],
                );
              }),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildNotableChangesSection(HealthReportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('STATISTICAL OBSERVATIONS (WHAT CHANGED?)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.SizedBox(height: 6),
        ...data.notableChanges.map((change) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Expanded(
                  child: pw.Text(change, style: const pw.TextStyle(fontSize: 9.5)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _tableCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  // --- Helpers for metric summaries ---
  MetricStatSummary _computeHrSummary(List<Measurement> list) {
    final values = list
        .where((m) => m.type == MeasurementType.heartRate && m.heartRateBpm != null)
        .map((m) => m.heartRateBpm!)
        .toList();

    return _buildSingleSummary(MeasurementType.heartRate, values, 'bpm');
  }

  MetricStatSummary _computeBpSummary(List<Measurement> list) {
    final bpList = list
        .where((m) =>
            m.type == MeasurementType.bloodPressure &&
            m.systolicMmhg != null &&
            m.diastolicMmhg != null)
        .toList();

    if (bpList.isEmpty) {
      return const MetricStatSummary(
        type: MeasurementType.bloodPressure,
        readingCount: 0,
        average: null,
        min: null,
        max: null,
        unit: 'mmHg',
      );
    }

    final sys = bpList.map((m) => m.systolicMmhg!).toList();
    final dia = bpList.map((m) => m.diastolicMmhg!).toList();

    sys.sort();
    dia.sort();

    final sysAvg = sys.reduce((a, b) => a + b) / sys.length;
    final diaAvg = dia.reduce((a, b) => a + b) / dia.length;

    return MetricStatSummary(
      type: MeasurementType.bloodPressure,
      readingCount: bpList.length,
      average: sysAvg,
      min: sys.first,
      max: sys.last,
      unit: 'mmHg',
      secondaryAverage: diaAvg,
      secondaryMin: dia.first,
      secondaryMax: dia.last,
      secondaryUnit: 'mmHg',
    );
  }

  MetricStatSummary _computeTempSummary(List<Measurement> list, bool isMetric) {
    final values = list
        .where((m) => m.type == MeasurementType.temperature && m.temperatureCelsius != null)
        .map((m) {
          final c = m.temperatureCelsius!;
          return isMetric ? c : (c * 9 / 5) + 32;
        })
        .toList();

    return _buildSingleSummary(
      MeasurementType.temperature,
      values,
      isMetric ? '°C' : '°F',
    );
  }

  MetricStatSummary _computeWeightSummary(List<Measurement> list, bool isMetric) {
    final values = list
        .where((m) => m.type == MeasurementType.weight && m.weightKg != null)
        .map((m) {
          final kg = m.weightKg!;
          return isMetric ? kg : kg * 2.20462;
        })
        .toList();

    return _buildSingleSummary(
      MeasurementType.weight,
      values,
      isMetric ? 'kg' : 'lbs',
    );
  }

  MetricStatSummary _computeGlucoseSummary(List<Measurement> list, bool isMetric) {
    final values = list
        .where((m) => m.type == MeasurementType.bloodGlucose && m.glucoseMmolL != null)
        .map((m) {
          final mmol = m.glucoseMmolL!;
          return isMetric ? mmol : mmol * 18.0182;
        })
        .toList();

    return _buildSingleSummary(
      MeasurementType.bloodGlucose,
      values,
      isMetric ? 'mmol/L' : 'mg/dL',
    );
  }

  MetricStatSummary _buildSingleSummary(
    MeasurementType type,
    List<double> values,
    String unit,
  ) {
    if (values.isEmpty) {
      return MetricStatSummary(
        type: type,
        readingCount: 0,
        average: null,
        min: null,
        max: null,
        unit: unit,
      );
    }

    values.sort();
    final avg = values.reduce((a, b) => a + b) / values.length;

    return MetricStatSummary(
      type: type,
      readingCount: values.length,
      average: avg,
      min: values.first,
      max: values.last,
      unit: unit,
    );
  }
}
