import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/daily_check/domain/models/daily_check.dart';
import '../../features/measurements/domain/models/measurement.dart';
import 'clinical_thresholds.dart';

/// Regional emergency telephone numbers and jurisdictions.
enum EmergencyRegion {
  unitedStates(
    countryName: 'United States & Canada',
    emergencyNumber: '911',
    description: 'Police, Fire, Ambulance',
  ),
  unitedKingdom(
    countryName: 'United Kingdom',
    emergencyNumber: '999',
    description: 'Emergency Services (999) / NHS Non-Emergency (111)',
  ),
  europeanUnion(
    countryName: 'European Union / International GSM',
    emergencyNumber: '112',
    description: 'Universal European Emergency Number',
  ),
  australia(
    countryName: 'Australia',
    emergencyNumber: '000',
    description: 'Triple Zero Emergency Services',
  );

  const EmergencyRegion({
    required this.countryName,
    required this.emergencyNumber,
    required this.description,
  });

  final String countryName;
  final String emergencyNumber;
  final String description;
}

/// Information packet describing an urgent medical concern.
@immutable
class UrgentMedicalAlert {
  const UrgentMedicalAlert({
    required this.headline,
    required this.subheading,
    required this.guidance,
    required this.isImmediateEmergency,
    this.guidelineCitation,
    this.symptoms = const <String>[],
  });

  final String headline;
  final String subheading;
  final String guidance;
  final bool isImmediateEmergency;
  final String? guidelineCitation;
  final List<String> symptoms;
}

/// Central clinical emergency protocol router and evaluator.
class EmergencyProtocols {
  const EmergencyProtocols._();

  /// Authoritative red-flag symptoms that necessitate immediate urgent evaluation.
  static const List<String> redFlagSymptoms = <String>[
    'Chest discomfort, tightness, or pressure',
    'Severe or sudden shortness of breath',
    'Sudden numbness or facial/limb weakness',
    'Difficulty speaking or slurred speech',
    'Sudden thunderclap severe headache',
    'Loss of consciousness or acute syncope',
    'Coughing up blood (hemoptysis)',
    'Sudden loss of vision or diplopia',
  ];

  /// Standard clinical emergency directive statement.
  static const String emergencyDirective =
      'HealthBase is a record-keeping and personal monitoring tool, not an emergency clinical service. '
      'If you are experiencing acute medical distress, chest pain, or severe sudden symptoms, '
      'do NOT delay care or wait for app notifications. Call emergency services immediately.';

  /// Evaluates whether a measurement indicates an urgent crisis requiring emergency prompt.
  static UrgentMedicalAlert? evaluateMeasurement(Measurement measurement) {
    switch (measurement.type) {
      case MeasurementType.bloodPressure:
        final sys = measurement.systolicMmhg;
        final dia = measurement.diastolicMmhg;
        if (sys != null && dia != null) {
          final eval = ClinicalThresholds.evaluateBloodPressure(
            systolic: sys,
            diastolic: dia,
          );
          if (eval.isCritical) {
            return UrgentMedicalAlert(
              headline: 'Hypertensive Crisis Range Detected',
              subheading:
                  'Reading: ${sys.toStringAsFixed(0)}/${dia.toStringAsFixed(0)} mmHg',
              guidance:
                  'Blood pressure in this range (Systolic > 180 or Diastolic > 120 mmHg) requires immediate clinical attention. '
                  'If accompanied by chest discomfort, difficulty breathing, back pain, weakness, or changes in vision, call emergency services immediately.',
              isImmediateEmergency: true,
              guidelineCitation: eval.guidelineCitation,
            );
          }
        }
        break;

      case MeasurementType.heartRate:
        final hr = measurement.heartRateBpm ?? measurement.pulseBpm;
        if (hr != null) {
          final eval = ClinicalThresholds.evaluateHeartRate(hr);
          if (eval.isCritical) {
            return UrgentMedicalAlert(
              headline: hr < ClinicalThresholds.hrCriticalBradycardia
                  ? 'Severe Bradycardia Alert'
                  : 'Severe Tachycardia Alert',
              subheading: 'Heart rate: ${hr.toStringAsFixed(0)} bpm',
              guidance: eval.advisoryMessage,
              isImmediateEmergency: true,
              guidelineCitation: eval.guidelineCitation,
            );
          }
        }
        break;

      case MeasurementType.bloodGlucose:
        final g = measurement.glucoseMmolL;
        if (g != null) {
          final eval = ClinicalThresholds.evaluateBloodGlucose(g);
          if (eval.isCritical) {
            return UrgentMedicalAlert(
              headline: g < ClinicalThresholds.glucoseHypoglycemiaSevereMmol
                  ? 'Severe Hypoglycemia Warning'
                  : 'Severe Hyperglycemia Warning',
              subheading:
                  'Blood glucose: ${g.toStringAsFixed(1)} mmol/L (${(g * 18.0182).toStringAsFixed(0)} mg/dL)',
              guidance: eval.advisoryMessage,
              isImmediateEmergency: true,
              guidelineCitation: eval.guidelineCitation,
            );
          }
        }
        break;

      case MeasurementType.temperature:
        final t = measurement.temperatureCelsius;
        if (t != null) {
          final eval = ClinicalThresholds.evaluateTemperature(t);
          if (eval.isCritical) {
            return UrgentMedicalAlert(
              headline: t < ClinicalThresholds.tempHypothermiaCelsius
                  ? 'Hypothermia Warning'
                  : 'High Fever Warning',
              subheading:
                  'Core temperature: ${t.toStringAsFixed(1)} °C (${(t * 9 / 5 + 32).toStringAsFixed(1)} °F)',
              guidance: eval.advisoryMessage,
              isImmediateEmergency: true,
              guidelineCitation: eval.guidelineCitation,
            );
          }
        }
        break;

      case MeasurementType.weight:
        // Weight rarely triggers acute per-second emergency protocols.
        break;
    }
    return null;
  }

  /// Evaluates symptoms recorded in a Daily Check.
  static UrgentMedicalAlert? evaluateDailyCheck(DailyCheck check) {
    if (check.hasUrgentSymptoms) {
      final urgentNames = check.symptoms
          .where((s) => s.isUrgent)
          .map((s) => s.displayName)
          .toList();

      return UrgentMedicalAlert(
        headline: 'Emergency Red-Flag Symptoms Reported',
        subheading: 'Reported: ${urgentNames.join(', ')}',
        guidance:
            'You have indicated one or more symptoms that may signify an acute medical condition. '
            'Please seek immediate emergency medical care. Do not wait for symptoms to resolve on their own.',
        isImmediateEmergency: true,
        symptoms: urgentNames,
      );
    }
    return null;
  }

  /// Initiates a telephone call to an emergency service number.
  ///
  /// Returns `true` if the system dialer was successfully launched.
  static Future<bool> launchEmergencyCall(String emergencyNumber) async {
    final uri = Uri.parse('tel:$emergencyNumber');
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('[EmergencyProtocols] Failed to launch emergency call: $e');
    }
    return false;
  }
}
