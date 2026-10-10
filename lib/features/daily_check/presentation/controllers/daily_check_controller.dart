import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/safety/safety_boundaries.dart';
import '../../data/daily_check_repository.dart';
import '../../domain/models/daily_check.dart';

@immutable
class DailyCheckState {
  const DailyCheckState({
    this.currentStep = 0,
    this.feeling,
    this.heartRateBpm,
    this.systolicMmhg,
    this.diastolicMmhg,
    this.temperatureCelsius,
    this.weightKg,
    this.glucoseMmolL,
    this.symptoms = const [],
    this.otherSymptomText,
    this.medicationStatus,
    this.notes,
    this.isLoading = false,
    this.hasExistingCheckToday = false,
    this.todayCheck,
    this.hasDraft = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  final int currentStep;
  final CheckFeeling? feeling;
  final double? heartRateBpm;
  final double? systolicMmhg;
  final double? diastolicMmhg;
  final double? temperatureCelsius;
  final double? weightKg;
  final double? glucoseMmolL;
  final List<CheckSymptom> symptoms;
  final String? otherSymptomText;
  final MedicationCheckStatus? medicationStatus;
  final String? notes;
  final bool isLoading;
  final bool hasExistingCheckToday;
  final DailyCheck? todayCheck;
  final bool hasDraft;
  final String? errorMessage;
  final bool isSuccess;

  bool get hasUrgentSymptoms => symptoms.any((s) => s.isUrgent);

  DailyCheckDraft toDraft(String profileId) {
    return DailyCheckDraft(
      profileId: profileId,
      currentStep: currentStep,
      feeling: feeling,
      heartRateBpm: heartRateBpm,
      systolicMmhg: systolicMmhg,
      diastolicMmhg: diastolicMmhg,
      temperatureCelsius: temperatureCelsius,
      weightKg: weightKg,
      glucoseMmolL: glucoseMmolL,
      symptomCodes: symptoms.map((s) => s.symptomCode).toList(),
      otherSymptomText: otherSymptomText,
      medicationStatus: medicationStatus,
      notes: notes,
      updatedAt: DateTime.now(),
    );
  }

  DailyCheckState copyWith({
    int? currentStep,
    CheckFeeling? feeling,
    double? heartRateBpm,
    bool clearHeartRate = false,
    double? systolicMmhg,
    bool clearSystolic = false,
    double? diastolicMmhg,
    bool clearDiastolic = false,
    double? temperatureCelsius,
    bool clearTemperature = false,
    double? weightKg,
    bool clearWeight = false,
    double? glucoseMmolL,
    bool clearGlucose = false,
    List<CheckSymptom>? symptoms,
    String? otherSymptomText,
    bool clearOtherSymptomText = false,
    MedicationCheckStatus? medicationStatus,
    String? notes,
    bool clearNotes = false,
    bool? isLoading,
    bool? hasExistingCheckToday,
    DailyCheck? todayCheck,
    bool? hasDraft,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isSuccess,
  }) {
    return DailyCheckState(
      currentStep: currentStep ?? this.currentStep,
      feeling: feeling ?? this.feeling,
      heartRateBpm: clearHeartRate ? null : (heartRateBpm ?? this.heartRateBpm),
      systolicMmhg: clearSystolic ? null : (systolicMmhg ?? this.systolicMmhg),
      diastolicMmhg: clearDiastolic ? null : (diastolicMmhg ?? this.diastolicMmhg),
      temperatureCelsius: clearTemperature ? null : (temperatureCelsius ?? this.temperatureCelsius),
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      glucoseMmolL: clearGlucose ? null : (glucoseMmolL ?? this.glucoseMmolL),
      symptoms: symptoms ?? this.symptoms,
      otherSymptomText: clearOtherSymptomText
          ? null
          : (otherSymptomText ?? this.otherSymptomText),
      medicationStatus: medicationStatus ?? this.medicationStatus,
      notes: clearNotes ? null : (notes ?? this.notes),
      isLoading: isLoading ?? this.isLoading,
      hasExistingCheckToday: hasExistingCheckToday ?? this.hasExistingCheckToday,
      todayCheck: todayCheck ?? this.todayCheck,
      hasDraft: hasDraft ?? this.hasDraft,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

final dailyCheckControllerProvider =
    StateNotifierProvider<DailyCheckController, DailyCheckState>((ref) {
  final repo = ref.watch(dailyCheckRepositoryProvider);
  return DailyCheckController(repo);
});

class DailyCheckController extends StateNotifier<DailyCheckState> {
  DailyCheckController(this._repo) : super(const DailyCheckState());

  final DailyCheckRepository _repo;

  /// Load initial check status or saved draft.
  Future<void> loadInitial(String profileId) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final existingToday = await _repo.getTodayCheck(profileId);
      if (existingToday != null) {
        state = state.copyWith(
          isLoading: false,
          hasExistingCheckToday: true,
          todayCheck: existingToday,
        );
        return;
      }

      // Check for saved draft
      final draft = await _repo.getDraft(profileId);
      if (draft != null) {
        final recoveredSymptoms = draft.symptomCodes.map((code) {
          if (code == 'other') {
            return CheckSymptom(
              symptomCode: 'other',
              displayName: 'Other (describe below)',
              customDescription: draft.otherSymptomText,
            );
          }
          return CheckSymptom.findByCode(code) ??
              CheckSymptom(symptomCode: code, displayName: code);
        }).toList();

        state = state.copyWith(
          isLoading: false,
          hasDraft: true,
          currentStep: draft.currentStep,
          feeling: draft.feeling,
          heartRateBpm: draft.heartRateBpm,
          systolicMmhg: draft.systolicMmhg,
          diastolicMmhg: draft.diastolicMmhg,
          temperatureCelsius: draft.temperatureCelsius,
          weightKg: draft.weightKg,
          glucoseMmolL: draft.glucoseMmolL,
          symptoms: recoveredSymptoms,
          otherSymptomText: draft.otherSymptomText,
          medicationStatus: draft.medicationStatus,
          notes: draft.notes,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load daily check: $e',
      );
    }
  }

  void setFeeling(CheckFeeling feeling, {String? profileId}) {
    state = state.copyWith(feeling: feeling, clearErrorMessage: true);
    if (profileId != null) _autoSaveDraft(profileId);
  }

  void setHeartRate(double? bpm, {String? profileId}) {
    state = state.copyWith(
      heartRateBpm: bpm,
      clearHeartRate: bpm == null,
      clearErrorMessage: true,
    );
    if (profileId != null) _autoSaveDraft(profileId);
  }

  void setBloodPressure(double? sys, double? dia, {String? profileId}) {
    state = state.copyWith(
      systolicMmhg: sys,
      clearSystolic: sys == null,
      diastolicMmhg: dia,
      clearDiastolic: dia == null,
      clearErrorMessage: true,
    );
    if (profileId != null) _autoSaveDraft(profileId);
  }

  void setTemperature(double? temp, {String? profileId}) {
    state = state.copyWith(
      temperatureCelsius: temp,
      clearTemperature: temp == null,
      clearErrorMessage: true,
    );
    if (profileId != null) _autoSaveDraft(profileId);
  }

  void setWeight(double? weight, {String? profileId}) {
    state = state.copyWith(
      weightKg: weight,
      clearWeight: weight == null,
      clearErrorMessage: true,
    );
    if (profileId != null) _autoSaveDraft(profileId);
  }

  void setGlucose(double? glucose, {String? profileId}) {
    state = state.copyWith(
      glucoseMmolL: glucose,
      clearGlucose: glucose == null,
      clearErrorMessage: true,
    );
    if (profileId != null) _autoSaveDraft(profileId);
  }

  void toggleSymptom(CheckSymptom symptom, {String? profileId}) {
    final list = List<CheckSymptom>.from(state.symptoms);
    final index = list.indexWhere((s) => s.symptomCode == symptom.symptomCode);
    if (index >= 0) {
      list.removeAt(index);
      if (symptom.symptomCode == 'other') {
        state = state.copyWith(
          symptoms: list,
          clearOtherSymptomText: true,
          clearErrorMessage: true,
        );
      } else {
        state = state.copyWith(symptoms: list, clearErrorMessage: true);
      }
    } else {
      if (symptom.symptomCode == 'other') {
        list.add(CheckSymptom(
          symptomCode: 'other',
          displayName: 'Other (describe below)',
          customDescription: state.otherSymptomText,
        ));
      } else {
        list.add(symptom);
      }
      state = state.copyWith(symptoms: list, clearErrorMessage: true);
    }
    if (profileId != null) _autoSaveDraft(profileId);
  }

  void setOtherSymptomText(String? text, {String? profileId}) {
    final trimmed = text?.trim();
    final normalized = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    final list = List<CheckSymptom>.from(state.symptoms);
    final index = list.indexWhere((s) => s.symptomCode == 'other');
    if (index >= 0) {
      list[index] = CheckSymptom(
        symptomCode: 'other',
        displayName: 'Other (describe below)',
        customDescription: normalized,
      );
    }
    state = state.copyWith(
      symptoms: list,
      otherSymptomText: normalized,
      clearOtherSymptomText: normalized == null,
      clearErrorMessage: true,
    );
    if (profileId != null) _autoSaveDraft(profileId);
  }

  void setMedicationStatus(MedicationCheckStatus status, {String? profileId}) {
    state = state.copyWith(medicationStatus: status, clearErrorMessage: true);
    if (profileId != null) _autoSaveDraft(profileId);
  }

  void setNotes(String? notes, {String? profileId}) {
    state = state.copyWith(
      notes: notes,
      clearNotes: notes == null,
      clearErrorMessage: true,
    );
    if (profileId != null) _autoSaveDraft(profileId);
  }

  /// Step navigation with validation guards
  bool nextStep(String profileId) {
    final validation = validateCurrentStep();
    if (validation != null) {
      state = state.copyWith(errorMessage: validation);
      return false;
    }

    if (state.currentStep < 4) {
      final next = state.currentStep + 1;
      state = state.copyWith(currentStep: next, clearErrorMessage: true);
      _autoSaveDraft(profileId);
      return true;
    }
    return true;
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(
        currentStep: state.currentStep - 1,
        clearErrorMessage: true,
      );
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 4) {
      state = state.copyWith(currentStep: step, clearErrorMessage: true);
    }
  }

  /// Physical plausibility & safety validation per step
  String? validateCurrentStep() {
    switch (state.currentStep) {
      case 0:
        if (state.feeling == null) {
          return 'Please select how you are feeling today.';
        }
        return null;

      case 1:
        // Heart rate is required
        if (state.heartRateBpm == null) {
          return 'Heart rate is required to complete your daily check.';
        }
        if (state.heartRateBpm! < SafetyBoundaries.minHeartRateBpm ||
            state.heartRateBpm! > SafetyBoundaries.maxHeartRateBpm) {
          return 'Heart rate must be between ${SafetyBoundaries.minHeartRateBpm.toInt()} and ${SafetyBoundaries.maxHeartRateBpm.toInt()} bpm.';
        }

        // Blood pressure plausibility (optional, but must be coherent if entered)
        if (state.systolicMmhg != null || state.diastolicMmhg != null) {
          if (state.systolicMmhg == null || state.diastolicMmhg == null) {
            return 'Both systolic and diastolic values are required for blood pressure.';
          }
          if (state.systolicMmhg! < SafetyBoundaries.minSystolicMmHg ||
              state.systolicMmhg! > SafetyBoundaries.maxSystolicMmHg) {
            return 'Systolic pressure must be between ${SafetyBoundaries.minSystolicMmHg.toInt()} and ${SafetyBoundaries.maxSystolicMmHg.toInt()} mmHg.';
          }
          if (state.diastolicMmhg! < SafetyBoundaries.minDiastolicMmHg ||
              state.diastolicMmhg! > SafetyBoundaries.maxDiastolicMmHg) {
            return 'Diastolic pressure must be between ${SafetyBoundaries.minDiastolicMmHg.toInt()} and ${SafetyBoundaries.maxDiastolicMmHg.toInt()} mmHg.';
          }
          if (state.systolicMmhg! <= state.diastolicMmhg!) {
            return 'Systolic pressure must be greater than diastolic pressure.';
          }
        }

        // Temperature plausibility
        if (state.temperatureCelsius != null) {
          if (state.temperatureCelsius! < SafetyBoundaries.minTemperatureCelsius ||
              state.temperatureCelsius! > SafetyBoundaries.maxTemperatureCelsius) {
            return 'Body temperature must be between ${SafetyBoundaries.minTemperatureCelsius}°C and ${SafetyBoundaries.maxTemperatureCelsius}°C.';
          }
        }

        // Weight plausibility
        if (state.weightKg != null) {
          if (state.weightKg! < SafetyBoundaries.minWeightKg ||
              state.weightKg! > SafetyBoundaries.maxWeightKg) {
            return 'Weight must be between ${SafetyBoundaries.minWeightKg.toInt()} and ${SafetyBoundaries.maxWeightKg.toInt()} kg.';
          }
        }

        // Glucose plausibility
        if (state.glucoseMmolL != null) {
          if (state.glucoseMmolL! < SafetyBoundaries.minGlucoseMmol ||
              state.glucoseMmolL! > SafetyBoundaries.maxGlucoseMmol) {
            return 'Blood glucose must be between ${SafetyBoundaries.minGlucoseMmol} and ${SafetyBoundaries.maxGlucoseMmol} mmol/L.';
          }
        }

        return null;

      case 2:
        // Symptoms are optional (0 symptoms is valid), but "Other"
        // requires free-text detail.
        final hasOther =
            state.symptoms.any((s) => s.symptomCode == 'other');
        if (hasOther) {
          final text = (state.otherSymptomText ?? '').trim();
          if (text.isEmpty) {
            return 'Please describe your other symptom in a few words.';
          }
        }
        return null;

      case 3:
        if (state.medicationStatus == null) {
          return 'Please select your medication adherence status.';
        }
        return null;

      case 4:
        return null;

      default:
        return null;
    }
  }

  /// Submit the full daily check
  Future<bool> submitCheck(String profileId) async {
    // Validate required fields
    if (state.feeling == null) {
      state = state.copyWith(errorMessage: 'Please select how you feel today.');
      return false;
    }
    if (state.heartRateBpm == null) {
      state = state.copyWith(errorMessage: 'Heart rate measurement is required.');
      return false;
    }
    if (state.medicationStatus == null) {
      state = state.copyWith(errorMessage: 'Please select medication status.');
      return false;
    }

    final hasOther = state.symptoms.any((s) => s.symptomCode == 'other');
    if (hasOther && (state.otherSymptomText ?? '').trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please describe your other symptom in a few words.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final symptoms = state.symptoms.map((s) {
        if (s.symptomCode == 'other') {
          return CheckSymptom(
            symptomCode: 'other',
            displayName: 'Other (describe below)',
            customDescription: (state.otherSymptomText ?? '').trim(),
          );
        }
        return s;
      }).toList();
      final check = await _repo.completeCheck(
        profileId: profileId,
        feeling: state.feeling!,
        medicationStatus: state.medicationStatus!,
        symptoms: symptoms,
        notes: state.notes,
        heartRateBpm: state.heartRateBpm!,
        systolicMmhg: state.systolicMmhg,
        diastolicMmhg: state.diastolicMmhg,
        temperatureCelsius: state.temperatureCelsius,
        weightKg: state.weightKg,
        glucoseMmolL: state.glucoseMmolL,
      );

      // Clear draft on successful completion
      await _repo.clearDraft(profileId);

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        hasExistingCheckToday: true,
        todayCheck: check,
        hasDraft: false,
      );
      return true;
    } on Failure catch (f) {
      state = state.copyWith(isLoading: false, errorMessage: f.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to record daily check: $e',
      );
      return false;
    }
  }

  /// Discard draft and reset to clean state
  Future<void> discardDraft(String profileId) async {
    await _repo.clearDraft(profileId);
    state = const DailyCheckState();
  }

  void _autoSaveDraft(String profileId) {
    final draft = state.toDraft(profileId);
    _repo.saveDraft(draft).catchError((_) {});
  }
}
