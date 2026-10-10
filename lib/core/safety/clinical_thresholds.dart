import 'package:flutter/foundation.dart';
import '../../features/measurements/domain/models/measurement.dart';

/// Clinical guideline source organization and publication context.
enum GuidelineAuthority {
  ahaAcc2017(
    authority: 'American Heart Association / American College of Cardiology',
    year: '2017',
    documentTitle: 'Guideline for the Prevention, Detection, Evaluation, and Management of High Blood Pressure in Adults',
  ),
  ada2024(
    authority: 'American Diabetes Association',
    year: '2024',
    documentTitle: 'Standards of Care in Diabetes',
  ),
  who2020(
    authority: 'World Health Organization',
    year: '2020',
    documentTitle: 'Pulse Oximetry Training Manual & Essential Physical Indicators',
  ),
  cdc2023(
    authority: 'Centers for Disease Control and Prevention',
    year: '2023',
    documentTitle: 'Vitals and Normal Physiological Boundaries Reference',
  ),
  nice2023(
    authority: 'National Institute for Health and Care Excellence',
    year: '2023',
    documentTitle: 'Fever in under 5s and Adults: Assessment and Initial Management',
  );

  const GuidelineAuthority({
    required this.authority,
    required this.year,
    required this.documentTitle,
  });

  final String authority;
  final String year;
  final String documentTitle;

  String get shortCitation => '$authority ($year)';
}

/// Clinical classification severity for physiological metric evaluations.
enum ClinicalSeverity {
  /// Well within published standard physiological baseline.
  normal,

  /// Slightly out of target range; warrants ongoing personal awareness.
  borderline,

  /// Clearly outside target range; recommends scheduling routine clinical evaluation.
  elevated,

  /// Critical/crisis level; requires immediate urgent professional evaluation.
  criticalUrgent,
}

/// Result of an automated clinical guideline evaluation for a metric.
@immutable
class ClinicalEvaluation {
  const ClinicalEvaluation({
    required this.severity,
    required this.categoryName,
    required this.guideline,
    required this.guidelineCitation,
    required this.advisoryMessage,
    this.requiresEmergencyPrompt = false,
    this.requiresPhysicianConsultation = false,
  });

  final ClinicalSeverity severity;
  final String categoryName;
  final GuidelineAuthority guideline;
  final String guidelineCitation;
  final String advisoryMessage;
  final bool requiresEmergencyPrompt;
  final bool requiresPhysicianConsultation;

  bool get isCritical => severity == ClinicalSeverity.criticalUrgent;
  bool get isElevated => severity == ClinicalSeverity.elevated || isCritical;
}

/// Centralized repository of authoritative clinical guideline thresholds.
///
/// NOTE: All thresholds and categorizations implemented here are derived exclusively
/// from published, peer-reviewed clinical guidelines (AHA/ACC, ADA, WHO, CDC, NICE).
/// They are provided purely for informational health record-keeping context and
/// NEVER constitute a formal clinical diagnosis.
class ClinicalThresholds {
  const ClinicalThresholds._();

  // ===========================================================================
  // BLOOD PRESSURE (AHA / ACC 2017 Guidelines)
  // ===========================================================================
  static const double bpNormalSysMax = 119.0;
  static const double bpNormalDiaMax = 79.0;

  static const double bpElevatedSysMin = 120.0;
  static const double bpElevatedSysMax = 129.0;

  static const double bpStage1SysMin = 130.0;
  static const double bpStage1SysMax = 139.0;
  static const double bpStage1DiaMin = 80.0;
  static const double bpStage1DiaMax = 89.0;

  static const double bpStage2SysMin = 140.0;
  static const double bpStage2DiaMin = 90.0;

  /// Hypertensive crisis: Systolic > 180 mmHg and/or Diastolic > 120 mmHg.
  /// Immediate medical evaluation is warranted.
  static const double bpHypertensiveCrisisSys = 180.0;
  static const double bpHypertensiveCrisisDia = 120.0;

  /// Hypotension threshold: Systolic < 90 mmHg and/or Diastolic < 60 mmHg.
  static const double bpHypotensionSys = 90.0;
  static const double bpHypotensionDia = 60.0;

  // ===========================================================================
  // HEART RATE / PULSE (AHA / CDC Adult Resting Guidelines)
  // ===========================================================================
  static const double hrBradycardiaThreshold = 60.0;
  static const double hrNormalMin = 60.0;
  static const double hrNormalMax = 100.0;
  static const double hrTachycardiaThreshold = 100.0;

  /// Severe bradycardia (< 40 bpm) or severe resting tachycardia (> 140 bpm).
  static const double hrCriticalBradycardia = 40.0;
  static const double hrCriticalTachycardia = 140.0;

  // ===========================================================================
  // BLOOD GLUCOSE (ADA 2024 Standards of Care)
  // In mmol/L (and mg/dL equivalent)
  // ===========================================================================
  // Fasting ranges (mmol/L):
  static const double glucoseFastingNormalMinMmol = 3.9; // 70 mg/dL
  static const double glucoseFastingNormalMaxMmol = 5.5; // 99 mg/dL
  static const double glucoseFastingImpairedMaxMmol = 6.9; // 125 mg/dL
  static const double glucoseFastingDiabetesMinMmol = 7.0; // 126 mg/dL

  // Acute alerts (mmol/L):
  static const double glucoseHypoglycemiaAlertMmol = 3.9; // < 70 mg/dL (Level 1)
  static const double glucoseHypoglycemiaSevereMmol = 3.0; // < 54 mg/dL (Level 2 Severe)
  static const double glucoseSevereHyperglycemiaMmol = 16.7; // > 300 mg/dL

  // ===========================================================================
  // BODY TEMPERATURE (CDC / NICE Guidelines)
  // In Celsius
  // ===========================================================================
  static const double tempHypothermiaCelsius = 35.0; // < 95.0 °F
  static const double tempNormalMinCelsius = 36.1; // 97.0 °F
  static const double tempNormalMaxCelsius = 37.2; // 99.0 °F
  static const double tempLowGradeFeverCelsius = 37.3; // 99.1 °F
  static const double tempFeverCelsius = 38.0; // 100.4 °F
  static const double tempHighFeverCelsius = 39.5; // 103.1 °F

  // ===========================================================================
  // OXYGEN SATURATION (SpO2) (WHO Guidelines)
  // ===========================================================================
  static const double spo2NormalMin = 95.0; // 95% - 100%
  static const double spo2HypoxemiaLow = 90.0; // 90% - 94%
  static const double spo2CriticalHypoxia = 90.0; // < 90% Immediate medical care

  // ===========================================================================
  // BODY MASS INDEX (BMI) (WHO Adult Guidelines)
  // ===========================================================================
  static const double bmiUnderweightMax = 18.49;
  static const double bmiNormalMin = 18.5;
  static const double bmiNormalMax = 24.9;
  static const double bmiOverweightMin = 25.0;
  static const double bmiOverweightMax = 29.9;
  static const double bmiObesityClass1Min = 30.0;
  static const double bmiObesityClass2Min = 35.0;
  static const double bmiObesityClass3Min = 40.0;

  // ===========================================================================
  // PHYSICAL PLAUSIBILITY BOUNDARIES (Corruption / Typo rejection)
  // ===========================================================================
  static const double plausibilityMinHeartRate = 25.0;
  static const double plausibilityMaxHeartRate = 250.0;

  static const double plausibilityMinSystolic = 40.0;
  static const double plausibilityMaxSystolic = 300.0;

  static const double plausibilityMinDiastolic = 30.0;
  static const double plausibilityMaxDiastolic = 200.0;

  static const double plausibilityMinTemperatureC = 30.0;
  static const double plausibilityMaxTemperatureC = 45.0;

  static const double plausibilityMinWeightKg = 1.0;
  static const double plausibilityMaxWeightKg = 400.0;

  static const double plausibilityMinGlucoseMmol = 0.5;
  static const double plausibilityMaxGlucoseMmol = 45.0;

  /// Validates whether a metric entry is physically plausible.
  static bool isPhysicallyPlausible(Measurement measurement) {
    switch (measurement.type) {
      case MeasurementType.heartRate:
        final hr = measurement.heartRateBpm;
        return hr != null &&
            hr >= plausibilityMinHeartRate &&
            hr <= plausibilityMaxHeartRate;

      case MeasurementType.bloodPressure:
        final sys = measurement.systolicMmhg;
        final dia = measurement.diastolicMmhg;
        if (sys == null || dia == null) return false;
        if (sys < plausibilityMinSystolic || sys > plausibilityMaxSystolic) {
          return false;
        }
        if (dia < plausibilityMinDiastolic || dia > plausibilityMaxDiastolic) {
          return false;
        }
        if (sys <= dia) return false; // Systolic must be strictly greater than Diastolic
        return true;

      case MeasurementType.temperature:
        final t = measurement.temperatureCelsius;
        return t != null &&
            t >= plausibilityMinTemperatureC &&
            t <= plausibilityMaxTemperatureC;

      case MeasurementType.weight:
        final w = measurement.weightKg;
        return w != null &&
            w >= plausibilityMinWeightKg &&
            w <= plausibilityMaxWeightKg;

      case MeasurementType.bloodGlucose:
        final g = measurement.glucoseMmolL;
        return g != null &&
            g >= plausibilityMinGlucoseMmol &&
            g <= plausibilityMaxGlucoseMmol;
    }
  }

  // ===========================================================================
  // EVALUATION ENGINES
  // ===========================================================================

  /// Evaluates Blood Pressure against AHA/ACC 2017 Guidelines.
  static ClinicalEvaluation evaluateBloodPressure({
    required double systolic,
    required double diastolic,
  }) {
    if (systolic >= bpHypertensiveCrisisSys ||
        diastolic >= bpHypertensiveCrisisDia) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.criticalUrgent,
        categoryName: 'Hypertensive Crisis Range',
        guideline: GuidelineAuthority.ahaAcc2017,
        guidelineCitation:
            'AHA/ACC 2017: Systolic > 180 mmHg or Diastolic > 120 mmHg',
        advisoryMessage:
            'This reading indicates dangerously high blood pressure. If accompanied by chest pain, shortness of breath, back pain, numbness/weakness, or visual changes, seek emergency medical care immediately.',
        requiresEmergencyPrompt: true,
        requiresPhysicianConsultation: true,
      );
    }

    if (systolic < bpHypotensionSys || diastolic < bpHypotensionDia) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.borderline,
        categoryName: 'Hypotension (Low Blood Pressure) Range',
        guideline: GuidelineAuthority.ahaAcc2017,
        guidelineCitation:
            'AHA/ACC: Systolic < 90 mmHg or Diastolic < 60 mmHg',
        advisoryMessage:
            'Your reading falls below the typical range. If experiencing lightheadedness, dizziness, or fainting, sit or lie down and consult a doctor.',
        requiresPhysicianConsultation: true,
      );
    }

    if (systolic >= bpStage2SysMin || diastolic >= bpStage2DiaMin) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.elevated,
        categoryName: 'Stage 2 Range',
        guideline: GuidelineAuthority.ahaAcc2017,
        guidelineCitation:
            'AHA/ACC 2017: Systolic >= 140 mmHg or Diastolic >= 90 mmHg',
        advisoryMessage:
            'Consistently elevated readings in this range suggest high blood pressure. Schedule a consultation with your healthcare provider for evaluation.',
        requiresPhysicianConsultation: true,
      );
    }

    if ((systolic >= bpStage1SysMin && systolic <= bpStage1SysMax) ||
        (diastolic >= bpStage1DiaMin && diastolic <= bpStage1DiaMax)) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.borderline,
        categoryName: 'Stage 1 Range',
        guideline: GuidelineAuthority.ahaAcc2017,
        guidelineCitation:
            'AHA/ACC 2017: Systolic 130-139 mmHg or Diastolic 80-89 mmHg',
        advisoryMessage:
            'Your reading is in the Stage 1 range. Discuss lifestyle habits and monitoring frequency with your healthcare professional.',
        requiresPhysicianConsultation: false,
      );
    }

    if (systolic >= bpElevatedSysMin &&
        systolic <= bpElevatedSysMax &&
        diastolic < bpNormalDiaMax + 1.0) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.borderline,
        categoryName: 'Elevated Range',
        guideline: GuidelineAuthority.ahaAcc2017,
        guidelineCitation:
            'AHA/ACC 2017: Systolic 120-129 mmHg and Diastolic < 80 mmHg',
        advisoryMessage:
            'Blood pressure is slightly elevated. Lifestyle modifications such as diet, exercise, and stress management are commonly recommended.',
      );
    }

    return const ClinicalEvaluation(
      severity: ClinicalSeverity.normal,
      categoryName: 'Normal Range',
      guideline: GuidelineAuthority.ahaAcc2017,
      guidelineCitation:
          'AHA/ACC 2017: Systolic < 120 mmHg and Diastolic < 80 mmHg',
      advisoryMessage:
          'Your blood pressure is within the standard guideline target.',
    );
  }

  /// Evaluates Heart Rate against CDC / AHA Guidelines.
  static ClinicalEvaluation evaluateHeartRate(double bpm) {
    if (bpm < hrCriticalBradycardia) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.criticalUrgent,
        categoryName: 'Severe Bradycardia',
        guideline: GuidelineAuthority.cdc2023,
        guidelineCitation: 'AHA / CDC: Heart Rate < 40 bpm',
        advisoryMessage:
            'Unusually low pulse rate. Unless you are an elite endurance athlete, low heart rates accompanied by dizziness, chest tightness, or weakness warrant immediate medical review.',
        requiresEmergencyPrompt: true,
        requiresPhysicianConsultation: true,
      );
    }

    if (bpm > hrCriticalTachycardia) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.criticalUrgent,
        categoryName: 'Severe Tachycardia',
        guideline: GuidelineAuthority.cdc2023,
        guidelineCitation: 'AHA / CDC: Resting Heart Rate > 140 bpm',
        advisoryMessage:
            'Significantly elevated resting heart rate. If occurring without vigorous physical exertion, or accompanied by palpitations, dizziness, or shortness of breath, seek prompt medical attention.',
        requiresEmergencyPrompt: true,
        requiresPhysicianConsultation: true,
      );
    }

    if (bpm < hrNormalMin) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.borderline,
        categoryName: 'Low Pulse (Bradycardia)',
        guideline: GuidelineAuthority.cdc2023,
        guidelineCitation: 'AHA / CDC: Resting Heart Rate < 60 bpm',
        advisoryMessage:
            'Heart rate is below standard adult resting range. Common in athletes, but consult a doctor if you feel lightheaded or fatigued.',
      );
    }

    if (bpm > hrNormalMax) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.elevated,
        categoryName: 'Elevated Pulse (Tachycardia)',
        guideline: GuidelineAuthority.cdc2023,
        guidelineCitation: 'AHA / CDC: Resting Heart Rate > 100 bpm',
        advisoryMessage:
            'Resting heart rate is elevated. Consider factors such as caffeine, hydration, stress, or recent exercise, and review with your doctor if persistent.',
        requiresPhysicianConsultation: true,
      );
    }

    return const ClinicalEvaluation(
      severity: ClinicalSeverity.normal,
      categoryName: 'Normal Resting Pulse',
      guideline: GuidelineAuthority.cdc2023,
      guidelineCitation: 'AHA / CDC: Resting Heart Rate 60 - 100 bpm',
      advisoryMessage:
          'Your resting pulse falls comfortably within normal physiological parameters.',
    );
  }

  /// Evaluates Blood Glucose against ADA 2024 Standards of Care.
  static ClinicalEvaluation evaluateBloodGlucose(double mmolL) {
    if (mmolL < glucoseHypoglycemiaSevereMmol) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.criticalUrgent,
        categoryName: 'Severe Hypoglycemia (Level 2)',
        guideline: GuidelineAuthority.ada2024,
        guidelineCitation: 'ADA 2024: Blood Glucose < 3.0 mmol/L (54 mg/dL)',
        advisoryMessage:
            'Critically low blood sugar level. Consume fast-acting carbohydrates (juice, glucose tablets) immediately. If accompanied by confusion or inability to swallow, emergency care is required.',
        requiresEmergencyPrompt: true,
        requiresPhysicianConsultation: true,
      );
    }

    if (mmolL < glucoseHypoglycemiaAlertMmol) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.elevated,
        categoryName: 'Hypoglycemia Alert (Level 1)',
        guideline: GuidelineAuthority.ada2024,
        guidelineCitation: 'ADA 2024: Blood Glucose < 3.9 mmol/L (70 mg/dL)',
        advisoryMessage:
            'Low blood glucose reading. Treat with 15 grams of fast-acting carbohydrate and re-check in 15 minutes (Rule of 15).',
        requiresPhysicianConsultation: true,
      );
    }

    if (mmolL >= glucoseSevereHyperglycemiaMmol) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.criticalUrgent,
        categoryName: 'Severe Hyperglycemia Alert',
        guideline: GuidelineAuthority.ada2024,
        guidelineCitation: 'ADA 2024: Blood Glucose > 16.7 mmol/L (300 mg/dL)',
        advisoryMessage:
            'Significantly elevated blood glucose level. High risk of ketoacidosis or hyperosmolar syndrome. Contact your healthcare team or urgent care.',
        requiresEmergencyPrompt: true,
        requiresPhysicianConsultation: true,
      );
    }

    if (mmolL >= glucoseFastingDiabetesMinMmol) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.elevated,
        categoryName: 'Elevated Glucose Range',
        guideline: GuidelineAuthority.ada2024,
        guidelineCitation:
            'ADA 2024: Fasting >= 7.0 mmol/L (126 mg/dL) or Random >= 11.1 mmol/L',
        advisoryMessage:
            'Blood sugar is elevated above standard fasting thresholds. Discuss personal targets and management with your clinician.',
        requiresPhysicianConsultation: true,
      );
    }

    if (mmolL > glucoseFastingNormalMaxMmol) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.borderline,
        categoryName: 'Mildly Elevated / Post-Meal Range',
        guideline: GuidelineAuthority.ada2024,
        guidelineCitation:
            'ADA 2024: Fasting 5.6 - 6.9 mmol/L (100 - 125 mg/dL)',
        advisoryMessage:
            'Typical for post-meal readings; if fasting, may indicate impaired fasting glucose. Mention to your healthcare professional.',
      );
    }

    return const ClinicalEvaluation(
      severity: ClinicalSeverity.normal,
      categoryName: 'Normal Target Range',
      guideline: GuidelineAuthority.ada2024,
      guidelineCitation: 'ADA 2024: Fasting 3.9 - 5.5 mmol/L (70 - 99 mg/dL)',
      advisoryMessage:
          'Blood glucose is within standard fasting baseline boundaries.',
    );
  }

  /// Evaluates Body Temperature against CDC / NICE Guidelines.
  static ClinicalEvaluation evaluateTemperature(double celsius) {
    if (celsius < tempHypothermiaCelsius) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.criticalUrgent,
        categoryName: 'Hypothermia Warning',
        guideline: GuidelineAuthority.nice2023,
        guidelineCitation: 'NICE / CDC: Core Temperature < 35.0 °C (95.0 °F)',
        advisoryMessage:
            'Abnormally low body temperature. Warm the individual gradually. Seek prompt medical care if shivering stops, speech slurs, or drowsiness occurs.',
        requiresEmergencyPrompt: true,
        requiresPhysicianConsultation: true,
      );
    }

    if (celsius >= tempHighFeverCelsius) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.criticalUrgent,
        categoryName: 'High Fever (Hyperpyrexia)',
        guideline: GuidelineAuthority.nice2023,
        guidelineCitation: 'NICE: Core Temperature >= 39.5 °C (103.1 °F)',
        advisoryMessage:
            'Significantly elevated fever. Stay well-hydrated. If accompanied by stiff neck, rash, confusion, or difficulty breathing, seek urgent medical evaluation.',
        requiresEmergencyPrompt: true,
        requiresPhysicianConsultation: true,
      );
    }

    if (celsius >= tempFeverCelsius) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.elevated,
        categoryName: 'Fever (Pyrexia)',
        guideline: GuidelineAuthority.cdc2023,
        guidelineCitation: 'CDC: Temperature >= 38.0 °C (100.4 °F)',
        advisoryMessage:
            'Fever detected. Rest, drink fluids, and monitor for other symptoms. Consult a clinician if the fever persists for more than 3 days.',
        requiresPhysicianConsultation: true,
      );
    }

    if (celsius >= tempLowGradeFeverCelsius) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.borderline,
        categoryName: 'Low-Grade Temperature Elevation',
        guideline: GuidelineAuthority.cdc2023,
        guidelineCitation: 'CDC: Temperature 37.3 - 37.9 °C (99.1 - 100.2 °F)',
        advisoryMessage:
            'Slight temperature elevation. Continue monitoring and maintain hydration.',
      );
    }

    return const ClinicalEvaluation(
      severity: ClinicalSeverity.normal,
      categoryName: 'Normal Body Temperature',
      guideline: GuidelineAuthority.cdc2023,
      guidelineCitation: 'CDC: Temperature 36.1 - 37.2 °C (97.0 - 99.0 °F)',
      advisoryMessage:
          'Body temperature is within the standard physiological range.',
    );
  }

  /// Evaluates Body Mass Index (BMI) against WHO Adult Guidelines.
  static ClinicalEvaluation evaluateBmi(double bmi) {
    if (bmi < bmiUnderweightMax) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.borderline,
        categoryName: 'Underweight Range',
        guideline: GuidelineAuthority.who2020,
        guidelineCitation: 'WHO: BMI < 18.5 kg/m²',
        advisoryMessage:
            'BMI is below standard reference range. Consider discussing nutritional targets with a healthcare professional.',
      );
    }

    if (bmi <= bmiNormalMax) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.normal,
        categoryName: 'Normal Weight Range',
        guideline: GuidelineAuthority.who2020,
        guidelineCitation: 'WHO: BMI 18.5 - 24.9 kg/m²',
        advisoryMessage:
            'BMI falls within standard international reference ranges.',
      );
    }

    if (bmi <= bmiOverweightMax) {
      return const ClinicalEvaluation(
        severity: ClinicalSeverity.borderline,
        categoryName: 'Overweight Range',
        guideline: GuidelineAuthority.who2020,
        guidelineCitation: 'WHO: BMI 25.0 - 29.9 kg/m²',
        advisoryMessage:
            'BMI is moderately above standard target. Lifestyle, physical activity, and balanced nutrition are helpful.',
      );
    }

    return const ClinicalEvaluation(
      severity: ClinicalSeverity.elevated,
      categoryName: 'Obesity Class Range',
      guideline: GuidelineAuthority.who2020,
      guidelineCitation: 'WHO: BMI >= 30.0 kg/m²',
      advisoryMessage:
          'BMI falls in the obesity classification. Consult your doctor or dietitian for an individualized cardiovascular and metabolic health plan.',
      requiresPhysicianConsultation: true,
    );
  }
}
