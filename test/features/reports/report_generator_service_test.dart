import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/features/daily_check/domain/models/daily_check.dart';
import 'package:healthbase/features/insights/domain/models/health_insight.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/medications/domain/models/medication.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:healthbase/features/reports/domain/models/health_report_data.dart';
import 'package:healthbase/features/reports/domain/services/report_generator_service.dart';

void main() {
  const service = ReportGeneratorService();
  final now = DateTime(2026, 10, 10, 12, 0);
  final start = now.subtract(const Duration(days: 30));

  final metricProfile = HealthProfile(
    id: 'user_1',
    ownerAccountId: 'user_1',
    isSelf: true,
    displayName: 'Jane Doe',
    preferredUnits: UnitSystem.metric,
    createdAt: now.subtract(const Duration(days: 100)),
    updatedAt: now,
  );

  final imperialProfile = HealthProfile(
    id: 'user_2',
    ownerAccountId: 'user_2',
    isSelf: true,
    displayName: 'John Smith',
    preferredUnits: UnitSystem.imperial,
    createdAt: now.subtract(const Duration(days: 100)),
    updatedAt: now,
  );

  group('ReportGeneratorService - buildReportData', () {
    test('computes HR, BP, Temp, Weight, Glucose averages and ranges correctly', () {
      final measurements = [
        // Heart rate: 70, 80 -> avg 75, min 70, max 80
        Measurement(
          id: 'm1',
          profileId: 'user_1',
          type: MeasurementType.heartRate,
          heartRateBpm: 70,
          source: MeasurementSource.manual,
          provenance: MeasurementProvenance.manuallyEntered,
          recordedAt: now.subtract(const Duration(days: 5)),
          recordedUtcOffset: 0,
          isDeleted: false,
          syncStatus: SyncStatus.synced,
          createdAt: now,
          updatedAt: now,
        ),
        Measurement(
          id: 'm2',
          profileId: 'user_1',
          type: MeasurementType.heartRate,
          heartRateBpm: 80,
          source: MeasurementSource.manual,
          provenance: MeasurementProvenance.manuallyEntered,
          recordedAt: now.subtract(const Duration(days: 2)),
          recordedUtcOffset: 0,
          isDeleted: false,
          syncStatus: SyncStatus.synced,
          createdAt: now,
          updatedAt: now,
        ),
        // Blood pressure: 120/80, 130/90 -> sys avg 125, dia avg 85
        Measurement(
          id: 'm3',
          profileId: 'user_1',
          type: MeasurementType.bloodPressure,
          systolicMmhg: 120,
          diastolicMmhg: 80,
          source: MeasurementSource.manual,
          provenance: MeasurementProvenance.manuallyEntered,
          recordedAt: now.subtract(const Duration(days: 4)),
          recordedUtcOffset: 0,
          isDeleted: false,
          syncStatus: SyncStatus.synced,
          createdAt: now,
          updatedAt: now,
        ),
        Measurement(
          id: 'm4',
          profileId: 'user_1',
          type: MeasurementType.bloodPressure,
          systolicMmhg: 130,
          diastolicMmhg: 90,
          source: MeasurementSource.manual,
          provenance: MeasurementProvenance.manuallyEntered,
          recordedAt: now.subtract(const Duration(days: 1)),
          recordedUtcOffset: 0,
          isDeleted: false,
          syncStatus: SyncStatus.synced,
          createdAt: now,
          updatedAt: now,
        ),
        // Temperature: 36.5 C
        Measurement(
          id: 'm5',
          profileId: 'user_1',
          type: MeasurementType.temperature,
          temperatureCelsius: 36.5,
          source: MeasurementSource.manual,
          provenance: MeasurementProvenance.manuallyEntered,
          recordedAt: now.subtract(const Duration(days: 3)),
          recordedUtcOffset: 0,
          isDeleted: false,
          syncStatus: SyncStatus.synced,
          createdAt: now,
          updatedAt: now,
        ),
        // Weight: 70.0 kg
        Measurement(
          id: 'm6',
          profileId: 'user_1',
          type: MeasurementType.weight,
          weightKg: 70.0,
          source: MeasurementSource.manual,
          provenance: MeasurementProvenance.manuallyEntered,
          recordedAt: now.subtract(const Duration(days: 3)),
          recordedUtcOffset: 0,
          isDeleted: false,
          syncStatus: SyncStatus.synced,
          createdAt: now,
          updatedAt: now,
        ),
        // Glucose: 5.5 mmol/L
        Measurement(
          id: 'm7',
          profileId: 'user_1',
          type: MeasurementType.bloodGlucose,
          glucoseMmolL: 5.5,
          source: MeasurementSource.manual,
          provenance: MeasurementProvenance.manuallyEntered,
          recordedAt: now.subtract(const Duration(days: 2)),
          recordedUtcOffset: 0,
          isDeleted: false,
          syncStatus: SyncStatus.synced,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final reportData = service.buildReportData(
        profile: metricProfile,
        startDate: start,
        endDate: now,
        period: ReportPeriod.days30,
        measurements: measurements,
        dailyChecks: [],
        medications: [],
        medicationEvents: [],
        insights: [],
      );

      expect(reportData.period, ReportPeriod.days30);
      expect(reportData.metricSummaries.length, 5);

      final hr = reportData.metricSummaries.firstWhere((s) => s.type == MeasurementType.heartRate);
      expect(hr.readingCount, 2);
      expect(hr.average, 75.0);
      expect(hr.min, 70.0);
      expect(hr.max, 80.0);
      expect(hr.unit, 'bpm');

      final bp = reportData.metricSummaries.firstWhere((s) => s.type == MeasurementType.bloodPressure);
      expect(bp.readingCount, 2);
      expect(bp.average, 125.0);
      expect(bp.min, 120.0);
      expect(bp.max, 130.0);
      expect(bp.secondaryAverage, 85.0);
      expect(bp.secondaryMin, 80.0);
      expect(bp.secondaryMax, 90.0);
      expect(bp.unit, 'mmHg');

      final temp = reportData.metricSummaries.firstWhere((s) => s.type == MeasurementType.temperature);
      expect(temp.readingCount, 1);
      expect(temp.average, 36.5);
      expect(temp.unit, '°C');

      final weight = reportData.metricSummaries.firstWhere((s) => s.type == MeasurementType.weight);
      expect(weight.readingCount, 1);
      expect(weight.average, 70.0);
      expect(weight.unit, 'kg');

      final glucose = reportData.metricSummaries.firstWhere((s) => s.type == MeasurementType.bloodGlucose);
      expect(glucose.readingCount, 1);
      expect(glucose.average, 5.5);
      expect(glucose.unit, 'mmol/L');
    });

    test('converts units to Imperial when preferredUnits is imperial', () {
      final measurements = [
        Measurement(
          id: 'm1',
          profileId: 'user_2',
          type: MeasurementType.temperature,
          temperatureCelsius: 37.0, // (37 * 9/5) + 32 = 98.6 F
          source: MeasurementSource.manual,
          provenance: MeasurementProvenance.manuallyEntered,
          recordedAt: now,
          recordedUtcOffset: 0,
          isDeleted: false,
          syncStatus: SyncStatus.synced,
          createdAt: now,
          updatedAt: now,
        ),
        Measurement(
          id: 'm2',
          profileId: 'user_2',
          type: MeasurementType.weight,
          weightKg: 100.0, // 100 * 2.20462 = 220.462 lbs
          source: MeasurementSource.manual,
          provenance: MeasurementProvenance.manuallyEntered,
          recordedAt: now,
          recordedUtcOffset: 0,
          isDeleted: false,
          syncStatus: SyncStatus.synced,
          createdAt: now,
          updatedAt: now,
        ),
        Measurement(
          id: 'm3',
          profileId: 'user_2',
          type: MeasurementType.bloodGlucose,
          glucoseMmolL: 5.0, // 5.0 * 18.0182 = 90.091 mg/dL
          source: MeasurementSource.manual,
          provenance: MeasurementProvenance.manuallyEntered,
          recordedAt: now,
          recordedUtcOffset: 0,
          isDeleted: false,
          syncStatus: SyncStatus.synced,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final reportData = service.buildReportData(
        profile: imperialProfile,
        startDate: start,
        endDate: now,
        period: ReportPeriod.days30,
        measurements: measurements,
        dailyChecks: [],
        medications: [],
        medicationEvents: [],
        insights: [],
      );

      final temp = reportData.metricSummaries.firstWhere((s) => s.type == MeasurementType.temperature);
      expect(temp.unit, '°F');
      expect(temp.average, closeTo(98.6, 0.1));

      final weight = reportData.metricSummaries.firstWhere((s) => s.type == MeasurementType.weight);
      expect(weight.unit, 'lbs');
      expect(weight.average, closeTo(220.46, 0.1));

      final glucose = reportData.metricSummaries.firstWhere((s) => s.type == MeasurementType.bloodGlucose);
      expect(glucose.unit, 'mg/dL');
      expect(glucose.average, closeTo(90.09, 0.1));
    });

    test('handles empty measurements gracefully without NaN or errors', () {
      final reportData = service.buildReportData(
        profile: metricProfile,
        startDate: start,
        endDate: now,
        period: ReportPeriod.days7,
        measurements: [],
        dailyChecks: [],
        medications: [],
        medicationEvents: [],
        insights: [],
      );

      expect(reportData.period, ReportPeriod.days7);
      for (final summary in reportData.metricSummaries) {
        expect(summary.readingCount, 0);
        expect(summary.average, isNull);
        expect(summary.hasData, isFalse);
        expect(summary.summaryText, 'No readings in period');
      }
    });

    test('aggregates symptoms and sorts descending by occurrences', () {
      final dailyChecks = [
        DailyCheck(
          id: 'c1',
          profileId: 'user_1',
          checkDate: now.subtract(const Duration(days: 3)),
          feeling: CheckFeeling.okay,
          medicationStatus: MedicationCheckStatus.yes,
          symptoms: const [
            CheckSymptom(symptomCode: 'headache', displayName: 'Headache'),
            CheckSymptom(symptomCode: 'fatigue', displayName: 'Fatigue'),
          ],
          createdAt: now,
          updatedAt: now,
        ),
        DailyCheck(
          id: 'c2',
          profileId: 'user_1',
          checkDate: now.subtract(const Duration(days: 1)),
          feeling: CheckFeeling.notGreat,
          medicationStatus: MedicationCheckStatus.yes,
          symptoms: const [
            CheckSymptom(symptomCode: 'headache', displayName: 'Headache'),
          ],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final reportData = service.buildReportData(
        profile: metricProfile,
        startDate: start,
        endDate: now,
        period: ReportPeriod.days30,
        measurements: [],
        dailyChecks: dailyChecks,
        medications: [],
        medicationEvents: [],
        insights: [],
      );

      expect(reportData.symptoms.length, 2);
      expect(reportData.symptoms.first.name, 'Headache');
      expect(reportData.symptoms.first.occurrences, 2);
      expect(reportData.symptoms.first.mostRecentDate, dailyChecks[1].checkDate);
      expect(reportData.symptoms.last.name, 'Fatigue');
      expect(reportData.symptoms.last.occurrences, 1);
    });

    test('aggregates medication adherence accurately', () {
      final med = Medication(
        id: 'med-1',
        profileId: 'user_1',
        name: 'Amlodipine',
        dosage: '5mg once daily',
        frequency: MedicationFrequency.daily,
        startDate: now.subtract(const Duration(days: 10)),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final events = [
        MedicationEvent(
          id: 'e1',
          profileId: 'user_1',
          medicationId: 'med-1',
          scheduledTime: now.subtract(const Duration(days: 3)),
          status: MedicationEventStatus.taken,
          createdAt: now,
          updatedAt: now,
        ),
        MedicationEvent(
          id: 'e2',
          profileId: 'user_1',
          medicationId: 'med-1',
          scheduledTime: now.subtract(const Duration(days: 2)),
          status: MedicationEventStatus.taken,
          createdAt: now,
          updatedAt: now,
        ),
        MedicationEvent(
          id: 'e3',
          profileId: 'user_1',
          medicationId: 'med-1',
          scheduledTime: now.subtract(const Duration(days: 1)),
          status: MedicationEventStatus.missed,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final reportData = service.buildReportData(
        profile: metricProfile,
        startDate: start,
        endDate: now,
        period: ReportPeriod.days30,
        measurements: [],
        dailyChecks: [],
        medications: [med],
        medicationEvents: events,
        insights: [],
      );

      expect(reportData.medications.length, 1);
      final item = reportData.medications.first;
      expect(item.name, 'Amlodipine');
      expect(item.dosage, '5mg once daily');
      expect(item.stats.takenCount, 2);
      expect(item.stats.missedCount, 1);
      expect(item.stats.scheduledCount, 3);
      expect(item.stats.recordedAdherenceRate, closeTo(66.67, 0.1));
    });

    test('maps insights to notable changes sentences', () {
      final evidence = InsightEvidence(
        type: MeasurementType.bloodPressure,
        unit: 'mmHg',
        recentCount: 3,
        recentAverage: 132.0,
        recentMedian: 130.0,
        baselineCount: 10,
        baselineAverage: 120.0,
        baselineMedian: 120.0,
        readings: [],
      );

      final insights = [
        HealthInsight(
          id: 'i1',
          type: MeasurementType.bloodPressure,
          title: 'Blood Pressure Elevated',
          direction: InsightDirection.higher,
          explanation: 'Systolic blood pressure averaged 132 mmHg over the last 14 days.',
          evidence: evidence,
          recentPeriodName: 'Last 14 days',
          baselinePeriodName: 'Previous 30 days',
        ),
      ];

      final reportData = service.buildReportData(
        profile: metricProfile,
        startDate: start,
        endDate: now,
        period: ReportPeriod.days30,
        measurements: [],
        dailyChecks: [],
        medications: [],
        medicationEvents: [],
        insights: insights,
      );

      expect(reportData.notableChanges.length, 1);
      expect(reportData.notableChanges.first, contains('Systolic blood pressure averaged 132 mmHg'));
    });
  });

  group('ReportGeneratorService - generatePdfBytes', () {
    test('generates valid PDF byte stream with %PDF header', () async {
      final reportData = service.buildReportData(
        profile: metricProfile,
        startDate: start,
        endDate: now,
        period: ReportPeriod.days30,
        measurements: [],
        dailyChecks: [],
        medications: [],
        medicationEvents: [],
        insights: [],
      );

      final pdfBytes = await service.generatePdfBytes(reportData);

      expect(pdfBytes, isNotEmpty);
      // PDF documents start with magic header '%PDF'
      final header = ascii.decode(pdfBytes.sublist(0, 4));
      expect(header, '%PDF');
    });

    test('HealthReportData contains mandatory non-diagnostic disclaimer', () {
      expect(
        HealthReportData.disclaimer,
        contains('HealthBase is a health monitoring and record-keeping tool. This report is not a medical diagnosis.'),
      );
    });
  });
}
