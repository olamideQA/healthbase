import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/safety/emergency_protocols.dart';
import 'package:healthbase/core/safety/widgets/clinical_disclaimer_sheet.dart';
import 'package:healthbase/core/safety/widgets/emergency_dialog.dart';
import 'package:healthbase/core/safety/widgets/urgent_care_alert_banner.dart';

void main() {
  group('Clinical Safety Widgets Tests', () {
    testWidgets('UrgentCareAlertBanner renders headline, guidance, and emergency button', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const alert = UrgentMedicalAlert(
        headline: 'Hypertensive Crisis Alert',
        subheading: 'Reading: 210/130 mmHg',
        guidance: 'Immediate emergency medical care required.',
        isImmediateEmergency: true,
        guidelineCitation: 'AHA/ACC 2017 Guidelines',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UrgentCareAlertBanner(alert: alert),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hypertensive Crisis Alert'), findsOneWidget);
      expect(find.text('Reading: 210/130 mmHg'), findsOneWidget);
      expect(find.text('Immediate emergency medical care required.'), findsOneWidget);
      expect(find.text('Reference: AHA/ACC 2017 Guidelines'), findsOneWidget);
      expect(find.text('Emergency Care Info (911 / 112)'), findsOneWidget);
    });

    testWidgets('EmergencyDialog renders regional contact directory', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmergencyDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Urgent Medical Advisory'), findsOneWidget);
      expect(find.text('911'), findsOneWidget);
      expect(find.text('999'), findsOneWidget);
      expect(find.text('112'), findsOneWidget);
      expect(find.text('000'), findsOneWidget);
      expect(find.text('United States & Canada'), findsOneWidget);
      expect(find.text('United Kingdom'), findsOneWidget);
    });

    testWidgets('ClinicalDisclaimerSheet renders non-diagnostic statement and guideline citations', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClinicalDisclaimerSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clinical & Safety Policy'), findsOneWidget);
      expect(find.text('Non-Diagnostic Statement'), findsOneWidget);
      expect(find.text('Authoritative Clinical Guidelines Cited'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Understood'), 100);
      expect(find.text('Understood'), findsOneWidget);
    });
  });
}
