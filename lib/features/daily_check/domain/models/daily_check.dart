import 'package:flutter/foundation.dart';

enum CheckFeeling {
  good,
  okay,
  notGreat,
  unwell;

  String toDbValue() => switch (this) {
        CheckFeeling.good => 'good',
        CheckFeeling.okay => 'okay',
        CheckFeeling.notGreat => 'not_great',
        CheckFeeling.unwell => 'unwell',
      };

  static CheckFeeling fromDbValue(String value) => switch (value) {
        'good' => CheckFeeling.good,
        'okay' => CheckFeeling.okay,
        'not_great' => CheckFeeling.notGreat,
        'unwell' => CheckFeeling.unwell,
        _ => CheckFeeling.okay,
      };

  String get displayName => switch (this) {
        CheckFeeling.good => 'Good',
        CheckFeeling.okay => 'Okay',
        CheckFeeling.notGreat => 'Not Great',
        CheckFeeling.unwell => 'Unwell',
      };

  String get description => switch (this) {
        CheckFeeling.good => 'Feeling healthy and balanced',
        CheckFeeling.okay => 'Usual baseline, no significant complaints',
        CheckFeeling.notGreat => 'A bit under the weather or fatigued',
        CheckFeeling.unwell => 'Noticeably ill or unwell',
      };
}

enum MedicationCheckStatus {
  yes,
  no,
  some,
  noneScheduled;

  String toDbValue() => switch (this) {
        MedicationCheckStatus.yes => 'yes',
        MedicationCheckStatus.no => 'no',
        MedicationCheckStatus.some => 'some',
        MedicationCheckStatus.noneScheduled => 'none_scheduled',
      };

  static MedicationCheckStatus fromDbValue(String value) => switch (value) {
        'yes' => MedicationCheckStatus.yes,
        'no' => MedicationCheckStatus.no,
        'some' => MedicationCheckStatus.some,
        'none_scheduled' => MedicationCheckStatus.noneScheduled,
        _ => MedicationCheckStatus.noneScheduled,
      };

  String get displayName => switch (this) {
        MedicationCheckStatus.yes => 'Yes, all scheduled medications',
        MedicationCheckStatus.some => 'Some, but missed a dose',
        MedicationCheckStatus.no => 'No, missed scheduled medications',
        MedicationCheckStatus.noneScheduled => 'No medications scheduled today',
      };
}

@immutable
class CheckSymptom {
  const CheckSymptom({
    required this.symptomCode,
    required this.displayName,
    this.isUrgent = false,
    this.customDescription,
  });

  final String symptomCode;
  final String displayName;
  final bool isUrgent;
  final String? customDescription;

  static const List<CheckSymptom> catalogue = [
    // Standard symptoms
    CheckSymptom(symptomCode: 'headache', displayName: 'Headache'),
    CheckSymptom(symptomCode: 'fatigue', displayName: 'Unusual fatigue / low energy'),
    CheckSymptom(symptomCode: 'nausea', displayName: 'Nausea / stomach upset'),
    CheckSymptom(symptomCode: 'dizziness', displayName: 'Dizziness or lightheadedness'),
    CheckSymptom(symptomCode: 'cough', displayName: 'Cough or congestion'),
    CheckSymptom(symptomCode: 'fever', displayName: 'Chills or feverish feeling'),
    CheckSymptom(symptomCode: 'body_aches', displayName: 'Body or muscle aches'),
    CheckSymptom(symptomCode: 'sore_throat', displayName: 'Sore throat'),

    // Urgent Emergency Red-Flags (derived from SafetyBoundaries.urgentSymptoms)
    CheckSymptom(
      symptomCode: 'chest_discomfort',
      displayName: 'Chest discomfort or pain',
      isUrgent: true,
    ),
    CheckSymptom(
      symptomCode: 'shortness_of_breath',
      displayName: 'Severe shortness of breath',
      isUrgent: true,
    ),
    CheckSymptom(
      symptomCode: 'sudden_numbness',
      displayName: 'Sudden numbness or weakness',
      isUrgent: true,
    ),
    CheckSymptom(
      symptomCode: 'difficulty_speaking',
      displayName: 'Difficulty speaking or slurred speech',
      isUrgent: true,
    ),
    CheckSymptom(
      symptomCode: 'severe_headache',
      displayName: 'Severe sudden headache',
      isUrgent: true,
    ),
    CheckSymptom(
      symptomCode: 'loss_of_consciousness',
      displayName: 'Loss of consciousness or fainting',
      isUrgent: true,
    ),

    // Free-text fallback: details captured in customDescription.
    CheckSymptom(symptomCode: 'other', displayName: 'Other (describe below)'),
  ];

  static CheckSymptom? findByCode(String code) {
    try {
      return catalogue.firstWhere((s) => s.symptomCode == code);
    } catch (_) {
      return null;
    }
  }
}

/// Represents a completed Daily Health Check record.
@immutable
class DailyCheck {
  const DailyCheck({
    required this.id,
    required this.profileId,
    required this.checkDate,
    required this.feeling,
    required this.medicationStatus,
    this.symptoms = const [],
    this.notes,
    this.isDeleted = false,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String profileId;
  final DateTime checkDate;
  final CheckFeeling feeling;
  final MedicationCheckStatus medicationStatus;
  final List<CheckSymptom> symptoms;
  final String? notes;
  final bool isDeleted;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasUrgentSymptoms => symptoms.any((s) => s.isUrgent);

  Map<String, dynamic> toRemoteJson() {
    return <String, dynamic>{
      'id': id,
      'profile_id': profileId,
      'check_date': checkDate.toIso8601String().split('T').first,
      'feeling': feeling.toDbValue(),
      'medication_status': medicationStatus.toDbValue(),
      if (notes != null) 'notes': notes,
      'is_deleted': isDeleted,
    };
  }

  DailyCheck copyWith({
    String? id,
    String? profileId,
    DateTime? checkDate,
    CheckFeeling? feeling,
    MedicationCheckStatus? medicationStatus,
    List<CheckSymptom>? symptoms,
    String? notes,
    bool? isDeleted,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyCheck(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      checkDate: checkDate ?? this.checkDate,
      feeling: feeling ?? this.feeling,
      medicationStatus: medicationStatus ?? this.medicationStatus,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// In-progress draft state for the guided daily check stepper.
@immutable
class DailyCheckDraft {
  const DailyCheckDraft({
    required this.profileId,
    this.currentStep = 0,
    this.feeling,
    this.heartRateBpm,
    this.systolicMmhg,
    this.diastolicMmhg,
    this.temperatureCelsius,
    this.weightKg,
    this.glucoseMmolL,
    this.symptomCodes = const [],
    this.otherSymptomText,
    this.medicationStatus,
    this.notes,
    required this.updatedAt,
  });

  final String profileId;
  final int currentStep;
  final CheckFeeling? feeling;
  final double? heartRateBpm;
  final double? systolicMmhg;
  final double? diastolicMmhg;
  final double? temperatureCelsius;
  final double? weightKg;
  final double? glucoseMmolL;
  final List<String> symptomCodes;
  final String? otherSymptomText;
  final MedicationCheckStatus? medicationStatus;
  final String? notes;
  final DateTime updatedAt;

  bool get hasUrgentSymptoms {
    return symptomCodes.any((code) {
      final s = CheckSymptom.findByCode(code);
      return s?.isUrgent ?? false;
    });
  }

  DailyCheckDraft copyWith({
    int? currentStep,
    CheckFeeling? feeling,
    double? heartRateBpm,
    double? systolicMmhg,
    double? diastolicMmhg,
    double? temperatureCelsius,
    double? weightKg,
    double? glucoseMmolL,
    List<String>? symptomCodes,
    String? otherSymptomText,
    bool clearOtherSymptomText = false,
    MedicationCheckStatus? medicationStatus,
    String? notes,
    DateTime? updatedAt,
  }) {
    return DailyCheckDraft(
      profileId: profileId,
      currentStep: currentStep ?? this.currentStep,
      feeling: feeling ?? this.feeling,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      systolicMmhg: systolicMmhg ?? this.systolicMmhg,
      diastolicMmhg: diastolicMmhg ?? this.diastolicMmhg,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      weightKg: weightKg ?? this.weightKg,
      glucoseMmolL: glucoseMmolL ?? this.glucoseMmolL,
      symptomCodes: symptomCodes ?? this.symptomCodes,
      otherSymptomText: clearOtherSymptomText
          ? null
          : (otherSymptomText ?? this.otherSymptomText),
      medicationStatus: medicationStatus ?? this.medicationStatus,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
