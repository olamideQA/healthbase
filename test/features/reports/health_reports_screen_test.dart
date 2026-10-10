import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:healthbase/features/medications/domain/models/medication.dart';
import 'package:healthbase/features/profile/data/profile_repository.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:healthbase/features/reports/data/report_repository.dart';
import 'package:healthbase/features/reports/domain/models/health_report_data.dart';
import 'package:healthbase/features/reports/presentation/screens/health_reports_screen.dart';

void main() {
  final now = DateTime(2026, 10, 10, 12, 0);

  final sampleProfile = HealthProfile(
    id: 'user_1',
    ownerAccountId: 'user_1',
    isSelf: true,
    displayName: 'Jane Doe',
    preferredUnits: UnitSystem.metric,
    createdAt: now.subtract(const Duration(days: 90)),
    updatedAt: now,
  );

  final sampleReportData = HealthReportData(
    profile: sampleProfile,
    startDate: now.subtract(const Duration(days: 30)),
    endDate: now,
    period: ReportPeriod.days30,
    metricSummaries: const [
      MetricStatSummary(
        type: MeasurementType.heartRate,
        readingCount: 12,
        average: 74.0,
        min: 65.0,
        max: 82.0,
        unit: 'bpm',
      ),
      MetricStatSummary(
        type: MeasurementType.bloodPressure,
        readingCount: 8,
        average: 120.0,
        min: 110.0,
        max: 130.0,
        secondaryAverage: 80.0,
        secondaryMin: 75.0,
        secondaryMax: 85.0,
        unit: 'mmHg',
      ),
    ],
    symptoms: [
      SymptomReportItem(
        name: 'Headache',
        occurrences: 3,
        mostRecentDate: now.subtract(const Duration(days: 2)),
      ),
    ],
    medications: const [
      MedicationReportItem(
        name: 'Lisinopril',
        dosage: '10mg',
        frequency: 'Daily',
        stats: MedicationAdherenceStats(
          scheduledCount: 30,
          takenCount: 27,
          missedCount: 3,
          notRecordedCount: 0,
        ),
      ),
    ],
    notableChanges: const [
      'Systolic blood pressure averaged 120 mmHg in the last 30 days.',
    ],
    generatedAt: now,
  );

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        myProfileProvider.overrideWith((ref) => sampleProfile),
        reportDataProvider.overrideWith((ref, args) => sampleReportData),
      ],
      child: const MaterialApp(
        home: HealthReportsScreen(),
      ),
    );
  }

  group('HealthReportsScreen Widget Tests', () {
    testWidgets('renders screen header and mandatory clinical disclaimer banner', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Title
      expect(find.text('Health Reports'), findsOneWidget);

      // Mandatory Non-diagnostic disclaimer banner
      expect(
        find.textContaining('HealthBase is a health monitoring and record-keeping tool. This report is not a medical diagnosis.'),
        findsOneWidget,
      );
    });

    testWidgets('renders period selection chips and allows selecting different periods', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('90 Days'), findsOneWidget);
      expect(find.text('Custom...'), findsOneWidget);

      // Tap 7 Days chip
      await tester.tap(find.text('7 Days'));
      await tester.pumpAndSettle();
    });

    testWidgets('renders export action card with preview and share buttons', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Healthcare Provider Report'), findsOneWidget);
      expect(find.text('Preview & Print'), findsOneWidget);
      expect(find.text('Share PDF'), findsOneWidget);
    });

    testWidgets('renders vitals summary, medication adherence, symptoms, and notable changes', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Section titles
      expect(find.text('MEASUREMENT SUMMARY & RANGES'), findsOneWidget);
      expect(find.text('MEDICATION ADHERENCE'), findsOneWidget);
      expect(find.text('LOGGED SYMPTOMS'), findsOneWidget);
      expect(find.text('STATISTICAL OBSERVATIONS'), findsOneWidget);

      // Vitals
      expect(find.text('Heart Rate'), findsOneWidget);
      expect(find.text('Blood Pressure'), findsOneWidget);
      expect(find.text('12 entries'), findsOneWidget);

      // Medication
      expect(find.text('Lisinopril'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('27 taken / 3 missed'), findsOneWidget);

      // Symptoms
      expect(find.text('Headache'), findsOneWidget);
      expect(find.textContaining('3x'), findsOneWidget);

      // Statistical observation
      expect(
        find.text('Systolic blood pressure averaged 120 mmHg in the last 30 days.'),
        findsOneWidget,
      );
    });
  });
}
