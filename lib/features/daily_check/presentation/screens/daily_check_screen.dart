import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/safety/safety_boundaries.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_button.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/app_text_field.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/domain/models/health_profile.dart';
import '../../domain/models/daily_check.dart';
import '../controllers/daily_check_controller.dart';

class DailyCheckScreen extends ConsumerStatefulWidget {
  const DailyCheckScreen({super.key});

  @override
  ConsumerState<DailyCheckScreen> createState() => _DailyCheckScreenState();
}

class _DailyCheckScreenState extends ConsumerState<DailyCheckScreen> {
  final _heartRateController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _tempController = TextEditingController();
  final _weightController = TextEditingController();
  final _glucoseController = TextEditingController();
  final _notesController = TextEditingController();
  final _otherSymptomController = TextEditingController();

  bool _initializedFromProfile = false;

  void _syncControllersFromState() {
    final state = ref.read(dailyCheckControllerProvider);
    final profile = ref.read(myProfileProvider).valueOrNull;
    final isMetric = profile?.preferredUnits != UnitSystem.imperial;

    if (state.heartRateBpm != null) {
      _heartRateController.text = state.heartRateBpm!.toInt().toString();
    }
    if (state.systolicMmhg != null) {
      _systolicController.text = state.systolicMmhg!.toInt().toString();
    }
    if (state.diastolicMmhg != null) {
      _diastolicController.text = state.diastolicMmhg!.toInt().toString();
    }
    if (state.temperatureCelsius != null) {
      final t = isMetric
          ? state.temperatureCelsius!
          : UnitConverter.celsiusToFahrenheit(state.temperatureCelsius!);
      _tempController.text = t.toStringAsFixed(1);
    }
    if (state.weightKg != null) {
      final w = isMetric ? state.weightKg! : UnitConverter.kgToLbs(state.weightKg!);
      _weightController.text = w.toStringAsFixed(1);
    }
    if (state.glucoseMmolL != null) {
      final g = isMetric ? state.glucoseMmolL! : (state.glucoseMmolL! * 18.0182);
      _glucoseController.text = g.toStringAsFixed(1);
    }
    if (state.notes != null) {
      _notesController.text = state.notes!;
    }
    if (state.otherSymptomText != null) {
      _otherSymptomController.text = state.otherSymptomText!;
    }
  }

  @override
  void dispose() {
    _heartRateController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _glucoseController.dispose();
    _notesController.dispose();
    _otherSymptomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final checkState = ref.watch(dailyCheckControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AsyncValue<HealthProfile?>>(myProfileProvider, (_, next) {
      final profile = next.valueOrNull;
      if (profile != null && !_initializedFromProfile) {
        _initializedFromProfile = true;
        ref.read(dailyCheckControllerProvider.notifier).loadInitial(profile.id).then((_) {
          if (mounted) _syncControllersFromState();
        });
      }
    });

    final currentProfile = profileAsync.valueOrNull;
    if (currentProfile != null && !_initializedFromProfile) {
      _initializedFromProfile = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(dailyCheckControllerProvider.notifier).loadInitial(currentProfile.id).then((_) {
          if (mounted) _syncControllersFromState();
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Health Check'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading profile: $e')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profile not found.'));
            }

            if (checkState.hasExistingCheckToday && checkState.todayCheck != null) {
              return _buildCompletedTodayView(context, checkState.todayCheck!, isDark);
            }

            return _buildStepperView(context, profile, checkState, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildCompletedTodayView(
    BuildContext context,
    DailyCheck check,
    bool isDark,
  ) {
    return ListView(
      padding: AppSpacing.paddingAllLg,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF2E7D32),
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          "Today's Health Check Complete",
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Recorded on ${check.checkDate.year}-${check.checkDate.month.toString().padLeft(2, '0')}-${check.checkDate.day.toString().padLeft(2, '0')}',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(height: AppSpacing.xl),

        AppCard(
          title: 'Recorded Summary',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow('Overall Feeling', check.feeling.displayName),
              const Divider(height: AppSpacing.lg),
              _buildSummaryRow(
                'Medication Status',
                check.medicationStatus.displayName,
              ),
              const Divider(height: AppSpacing.lg),
              _buildSummaryRow(
                'Symptoms Reported',
                check.symptoms.isEmpty
                    ? 'None reported'
                    : check.symptoms
                        .map((s) => s.symptomCode == 'other' &&
                                (s.customDescription ?? '').isNotEmpty
                            ? 'Other: ${s.customDescription}'
                            : s.displayName)
                        .join(', '),
              ),
              if (check.notes != null && check.notes!.isNotEmpty) ...[
                const Divider(height: AppSpacing.lg),
                _buildSummaryRow('Notes', check.notes!),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        if (check.hasUrgentSymptoms)
          Container(
            padding: AppSpacing.paddingAllMd,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.statusUrgent),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.statusUrgent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    SafetyBoundaries.emergencyWarningMessage,
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF991B1B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xl),

        AppButton(
          label: 'View Measurements History',
          icon: Icons.history,
          onPressed: () => context.push('/measurements'),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Back to Dashboard',
          variant: AppButtonVariant.secondary,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperView(
    BuildContext context,
    HealthProfile profile,
    DailyCheckState checkState,
    bool isDark,
  ) {
    final notifier = ref.read(dailyCheckControllerProvider.notifier);
    final isMetric = profile.preferredUnits != UnitSystem.imperial;

    return Column(
      children: [
        // Stepper Progress Header
        _buildStepperHeader(checkState.currentStep),

        if (checkState.hasDraft)
          Container(
            color: AppColors.primary100.withAlpha(60),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.restore, size: 18, color: AppColors.primary700),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Restored in-progress draft from earlier today.',
                    style: TextStyle(fontSize: 12.0, color: AppColors.neutral900),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    notifier.discardDraft(profile.id);
                    _clearControllers();
                  },
                  child: const Text('Start Over', style: TextStyle(fontSize: 12.0)),
                ),
              ],
            ),
          ),

        // Error message banner
        if (checkState.errorMessage != null)
          Container(
            color: const Color(0xFFFEE2E2),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              checkState.errorMessage!,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Step Content
        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingAllLg,
            child: switch (checkState.currentStep) {
              0 => _buildStepFeeling(notifier, checkState, profile.id),
              1 => _buildStepVitals(notifier, checkState, isMetric, profile.id),
              2 => _buildStepSymptoms(notifier, checkState, profile.id),
              3 => _buildStepMedication(notifier, checkState, profile.id),
              4 => _buildStepSummary(notifier, checkState, isMetric, profile.id),
              _ => const SizedBox.shrink(),
            },
          ),
        ),

        // Bottom Navigation Bar
        _buildBottomNav(notifier, checkState, profile.id),
      ],
    );
  }

  void _clearControllers() {
    _heartRateController.clear();
    _systolicController.clear();
    _diastolicController.clear();
    _tempController.clear();
    _weightController.clear();
    _glucoseController.clear();
    _notesController.clear();
    _otherSymptomController.clear();
  }

  Widget _buildStepperHeader(int currentStep) {
    final steps = ['Feeling', 'Vitals', 'Symptoms', 'Meds', 'Review'];
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isActive = index == currentStep;
          final isPast = index < currentStep;
          return Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppColors.primary600
                      : (isPast ? const Color(0xFF2E7D32) : AppColors.neutral200),
                ),
                child: Center(
                  child: isPast
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : AppColors.neutral600,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                steps[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? AppColors.primary700 : AppColors.neutral600,
                ),
              ),
              if (index < steps.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(Icons.chevron_right, size: 14, color: AppColors.neutral300),
                ),
            ],
          );
        }),
      ),
    );
  }

  // STEP 0: Feeling
  Widget _buildStepFeeling(
    DailyCheckController notifier,
    DailyCheckState state,
    String profileId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How are you feeling today?', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Select the option that best reflects your current overall wellness.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(height: AppSpacing.xl),

        _feelingCard(
          notifier: notifier,
          state: state,
          feeling: CheckFeeling.good,
          icon: Icons.sentiment_very_satisfied_rounded,
          color: const Color(0xFF16A34A),
          profileId: profileId,
        ),
        const SizedBox(height: AppSpacing.md),
        _feelingCard(
          notifier: notifier,
          state: state,
          feeling: CheckFeeling.okay,
          icon: Icons.sentiment_satisfied_rounded,
          color: AppColors.primary600,
          profileId: profileId,
        ),
        const SizedBox(height: AppSpacing.md),
        _feelingCard(
          notifier: notifier,
          state: state,
          feeling: CheckFeeling.notGreat,
          icon: Icons.sentiment_neutral_rounded,
          color: const Color(0xFFD97706),
          profileId: profileId,
        ),
        const SizedBox(height: AppSpacing.md),
        _feelingCard(
          notifier: notifier,
          state: state,
          feeling: CheckFeeling.unwell,
          icon: Icons.sentiment_very_dissatisfied_rounded,
          color: AppColors.statusUrgent,
          profileId: profileId,
        ),
      ],
    );
  }

  Widget _feelingCard({
    required DailyCheckController notifier,
    required DailyCheckState state,
    required CheckFeeling feeling,
    required IconData icon,
    required Color color,
    required String profileId,
  }) {
    final isSelected = state.feeling == feeling;
    return InkWell(
      onTap: () => notifier.setFeeling(feeling, profileId: profileId),
      borderRadius: AppSpacing.roundedMd,
      child: Container(
        padding: AppSpacing.paddingAllMd,
        decoration: BoxDecoration(
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(
            color: isSelected ? color : AppColors.neutral300,
            width: isSelected ? 2.0 : 1.0,
          ),
          color: isSelected ? color.withAlpha(20) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feeling.displayName,
                    style: AppTypography.titleMedium.copyWith(
                      color: isSelected ? color : null,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    feeling.description,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  // STEP 1: Vitals
  Widget _buildStepVitals(
    DailyCheckController notifier,
    DailyCheckState state,
    bool isMetric,
    String profileId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Vitals", style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Heart rate is required to complete your check-in. Other vitals are optional.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Heart rate (required)
        AppTextField(
          controller: _heartRateController,
          label: 'Heart Rate (bpm) * Required',
          hintText: 'e.g. 72',
          keyboardType: TextInputType.number,
          onChanged: (val) {
            final parsed = double.tryParse(val.trim());
            notifier.setHeartRate(parsed, profileId: profileId);
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Blood pressure (optional)
        Text(
          'Blood Pressure (Optional)',
          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _systolicController,
                label: 'Systolic (mmHg)',
                hintText: 'e.g. 120',
                keyboardType: TextInputType.number,
                onChanged: (_) => _updateBp(notifier, profileId),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                controller: _diastolicController,
                label: 'Diastolic (mmHg)',
                hintText: 'e.g. 80',
                keyboardType: TextInputType.number,
                onChanged: (_) => _updateBp(notifier, profileId),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Temperature (optional)
        AppTextField(
          controller: _tempController,
          label: isMetric ? 'Body Temperature (°C)' : 'Body Temperature (°F)',
          hintText: isMetric ? 'e.g. 36.6' : 'e.g. 98.6',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (val) {
            final raw = double.tryParse(val.trim());
            if (raw == null) {
              notifier.setTemperature(null, profileId: profileId);
            } else {
              final celsius =
                  isMetric ? raw : UnitConverter.fahrenheitToCelsius(raw);
              notifier.setTemperature(celsius, profileId: profileId);
            }
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Weight (optional)
        AppTextField(
          controller: _weightController,
          label: isMetric ? 'Weight (kg)' : 'Weight (lbs)',
          hintText: isMetric ? 'e.g. 70.0' : 'e.g. 154.0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (val) {
            final raw = double.tryParse(val.trim());
            if (raw == null) {
              notifier.setWeight(null, profileId: profileId);
            } else {
              final kg = isMetric ? raw : UnitConverter.lbsToKg(raw);
              notifier.setWeight(kg, profileId: profileId);
            }
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Glucose (optional)
        AppTextField(
          controller: _glucoseController,
          label: isMetric ? 'Blood Glucose (mmol/L)' : 'Blood Glucose (mg/dL)',
          hintText: isMetric ? 'e.g. 5.5' : 'e.g. 100.0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (val) {
            final raw = double.tryParse(val.trim());
            if (raw == null) {
              notifier.setGlucose(null, profileId: profileId);
            } else {
              final mmol = isMetric ? raw : (raw / 18.0182);
              notifier.setGlucose(mmol, profileId: profileId);
            }
          },
        ),
      ],
    );
  }

  void _updateBp(DailyCheckController notifier, String profileId) {
    final sys = double.tryParse(_systolicController.text.trim());
    final dia = double.tryParse(_diastolicController.text.trim());
    notifier.setBloodPressure(sys, dia, profileId: profileId);
  }

  // STEP 2: Symptoms
  Widget _buildStepSymptoms(
    DailyCheckController notifier,
    DailyCheckState state,
    String profileId,
  ) {
    final urgentList =
        CheckSymptom.catalogue.where((s) => s.isUrgent).toList();
    final standardList =
        CheckSymptom.catalogue.where((s) => !s.isUrgent).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Any symptoms today?', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Select any symptoms you are currently experiencing. Skip if none apply.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(height: AppSpacing.lg),

        if (state.hasUrgentSymptoms) ...[
          Container(
            padding: AppSpacing.paddingAllMd,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.statusUrgent),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.statusUrgent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    SafetyBoundaries.emergencyWarningMessage,
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF991B1B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        Text(
          'Emergency Red-Flag Symptoms',
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.statusUrgent,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...urgentList.map((sym) => _symptomTile(notifier, state, sym, profileId, isUrgent: true)),

        const SizedBox(height: AppSpacing.lg),
        Text(
          'Common Symptoms',
          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...standardList.map((sym) => _symptomTile(notifier, state, sym, profileId)),
        if (state.symptoms.any((s) => s.symptomCode == 'other')) ...[
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _otherSymptomController,
            label: 'Describe your other symptom * Required',
            hintText: 'e.g. Mild ear pressure since morning',
            maxLines: 2,
            onChanged: (val) =>
                notifier.setOtherSymptomText(val, profileId: profileId),
          ),
        ],
      ],
    );
  }

  Widget _symptomTile(
    DailyCheckController notifier,
    DailyCheckState state,
    CheckSymptom sym,
    String profileId, {
    bool isUrgent = false,
  }) {
    final isSelected = state.symptoms.any((s) => s.symptomCode == sym.symptomCode);

    return CheckboxListTile(
      value: isSelected,
      onChanged: (_) => notifier.toggleSymptom(sym, profileId: profileId),
      title: Text(
        sym.displayName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isUrgent ? const Color(0xFFB91C1C) : null,
        ),
      ),
      secondary: isUrgent
          ? const Icon(Icons.emergency, color: AppColors.statusUrgent, size: 20)
          : null,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: isUrgent ? AppColors.statusUrgent : AppColors.primary600,
    );
  }

  // STEP 3: Medication & Notes
  Widget _buildStepMedication(
    DailyCheckController notifier,
    DailyCheckState state,
    String profileId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Medications & Notes', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Did you take all your prescribed and scheduled medications today?',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(height: AppSpacing.xl),

        _medicationTile(
          notifier: notifier,
          state: state,
          status: MedicationCheckStatus.yes,
          profileId: profileId,
        ),
        const SizedBox(height: AppSpacing.sm),
        _medicationTile(
          notifier: notifier,
          state: state,
          status: MedicationCheckStatus.some,
          profileId: profileId,
        ),
        const SizedBox(height: AppSpacing.sm),
        _medicationTile(
          notifier: notifier,
          state: state,
          status: MedicationCheckStatus.no,
          profileId: profileId,
        ),
        const SizedBox(height: AppSpacing.sm),
        _medicationTile(
          notifier: notifier,
          state: state,
          status: MedicationCheckStatus.noneScheduled,
          profileId: profileId,
        ),
        const SizedBox(height: AppSpacing.xl),

        AppTextField(
          controller: _notesController,
          label: 'Notes or Observations (Optional)',
          hintText: 'e.g. Slept 8 hours, slight mild stiffness',
          maxLines: 3,
          onChanged: (val) =>
              notifier.setNotes(val.trim().isEmpty ? null : val.trim(), profileId: profileId),
        ),
      ],
    );
  }

  Widget _medicationTile({
    required DailyCheckController notifier,
    required DailyCheckState state,
    required MedicationCheckStatus status,
    required String profileId,
  }) {
    final isSelected = state.medicationStatus == status;
    return InkWell(
      onTap: () => notifier.setMedicationStatus(status, profileId: profileId),
      borderRadius: AppSpacing.roundedMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(
            color: isSelected ? AppColors.primary600 : AppColors.neutral300,
            width: isSelected ? 2.0 : 1.0,
          ),
          color: isSelected ? AppColors.primary100.withAlpha(40) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary600 : AppColors.neutral500,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                status.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary700 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 4: Summary Review
  Widget _buildStepSummary(
    DailyCheckController notifier,
    DailyCheckState state,
    bool isMetric,
    String profileId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review Your Daily Check', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Please verify your entries before submitting.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(height: AppSpacing.lg),

        if (state.hasUrgentSymptoms) ...[
          Container(
            padding: AppSpacing.paddingAllMd,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.statusUrgent),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.statusUrgent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    SafetyBoundaries.emergencyWarningMessage,
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF991B1B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        AppCard(
          title: 'Daily Check Overview',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow(
                'Feeling',
                state.feeling?.displayName ?? 'Not specified',
              ),
              const Divider(height: AppSpacing.md),
              _buildSummaryRow(
                'Heart Rate',
                state.heartRateBpm != null
                    ? '${state.heartRateBpm!.toInt()} bpm'
                    : 'Not entered',
              ),
              if (state.systolicMmhg != null && state.diastolicMmhg != null) ...[
                const Divider(height: AppSpacing.md),
                _buildSummaryRow(
                  'Blood Pressure',
                  '${state.systolicMmhg!.toInt()} / ${state.diastolicMmhg!.toInt()} mmHg',
                ),
              ],
              if (state.temperatureCelsius != null) ...[
                const Divider(height: AppSpacing.md),
                _buildSummaryRow(
                  'Temperature',
                  isMetric
                      ? '${state.temperatureCelsius!.toStringAsFixed(1)} °C'
                      : '${UnitConverter.celsiusToFahrenheit(state.temperatureCelsius!).toStringAsFixed(1)} °F',
                ),
              ],
              if (state.weightKg != null) ...[
                const Divider(height: AppSpacing.md),
                _buildSummaryRow(
                  'Weight',
                  isMetric
                      ? '${state.weightKg!.toStringAsFixed(1)} kg'
                      : '${UnitConverter.kgToLbs(state.weightKg!).toStringAsFixed(1)} lbs',
                ),
              ],
              if (state.glucoseMmolL != null) ...[
                const Divider(height: AppSpacing.md),
                _buildSummaryRow(
                  'Glucose',
                  isMetric
                      ? '${state.glucoseMmolL!.toStringAsFixed(1)} mmol/L'
                      : '${(state.glucoseMmolL! * 18.0182).toStringAsFixed(1)} mg/dL',
                ),
              ],
              const Divider(height: AppSpacing.md),
              _buildSummaryRow(
                'Medications',
                state.medicationStatus?.displayName ?? 'Not specified',
              ),
              const Divider(height: AppSpacing.md),
              _buildSummaryRow(
                'Symptoms',
                state.symptoms.isEmpty
                    ? 'None reported'
                    : state.symptoms
                        .map((s) => s.symptomCode == 'other'
                            ? 'Other: ${(state.otherSymptomText ?? s.customDescription ?? '').trim().isEmpty ? '(description required)' : (state.otherSymptomText ?? s.customDescription ?? '').trim()}'
                            : s.displayName)
                        .join(', '),
              ),
              if (state.notes != null && state.notes!.isNotEmpty) ...[
                const Divider(height: AppSpacing.md),
                _buildSummaryRow('Notes', state.notes!),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Non-diagnostic clinical disclaimer
        Container(
          padding: AppSpacing.paddingAllMd,
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: AppSpacing.roundedSm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.neutral600),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  SafetyBoundaries.generalDisclaimer,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.neutral600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // BOTTOM NAVIGATION
  Widget _buildBottomNav(
    DailyCheckController notifier,
    DailyCheckState state,
    String profileId,
  ) {
    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          if (state.currentStep > 0)
            Expanded(
              child: AppButton(
                label: 'Previous',
                variant: AppButtonVariant.secondary,
                onPressed: state.isLoading ? null : () => notifier.previousStep(),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: state.currentStep < 4
                ? AppButton(
                    label: 'Next',
                    onPressed: state.isLoading ? null : () => notifier.nextStep(profileId),
                  )
                : AppButton(
                    label: 'Submit Daily Check',
                    isLoading: state.isLoading,
                    onPressed: state.isLoading
                        ? null
                        : () async {
                            final success = await notifier.submitCheck(profileId);
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Daily Check completed successfully!'),
                                  backgroundColor: Color(0xFF2E7D32),
                                ),
                              );
                            }
                          },
                  ),
          ),
        ],
      ),
    );
  }
}
