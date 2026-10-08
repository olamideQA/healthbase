import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_button.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/app_text_field.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../profile/domain/models/health_profile.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;

  // Form State
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  UnitSystem _unitSystem = UnitSystem.metric;
  DateTime? _dateOfBirth;
  SexType? _selectedSex;

  @override
  void initState() {
    super.initState();
    // Pre-fill display name from existing profile if available
    final profile = ref.read(profileControllerProvider).value;
    if (profile?.displayName != null) {
      _nameController.text = profile!.displayName!;
    }
    if (profile?.preferredUnits != null) {
      _unitSystem = profile!.preferredUnits;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    double? heightCm;
    if (_heightController.text.trim().isNotEmpty) {
      final parsed = double.tryParse(_heightController.text.trim());
      if (parsed != null) {
        heightCm = _unitSystem == UnitSystem.metric
            ? parsed
            : parsed * 2.54; // If imperial, input is total inches
      }
    }

    double? weightKg;
    if (_weightController.text.trim().isNotEmpty) {
      final parsed = double.tryParse(_weightController.text.trim());
      if (parsed != null) {
        weightKg = _unitSystem == UnitSystem.metric
            ? parsed
            : UnitConverter.lbsToKg(parsed);
      }
    }

    final success = await ref
        .read(profileControllerProvider.notifier)
        .completeOnboarding(
          displayName: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
          preferredUnits: _unitSystem,
          dateOfBirth: _dateOfBirth,
          sex: _selectedSex,
          heightCm: heightCm,
          weightKg: weightKg,
        );

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  Future<void> _handleSkipAll() async {
    final success = await ref
        .read(profileControllerProvider.notifier)
        .skipOnboarding(preferredUnits: _unitSystem);

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _dateOfBirth ?? DateTime(now.year - 30, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your date of birth',
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final isLoading = profileState.isLoading;
    final errorMessage = profileState.hasError
        ? (profileState.error is Failure
            ? (profileState.error as Failure).message
            : 'Unable to save profile. Please check your inputs.')
        : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthBase Setup'),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: isLoading ? null : _handleSkipAll,
              child: const Text('Skip All'),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingAllLg,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step indicator
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / 3,
                    backgroundColor: isDark ? AppColors.neutral800 : AppColors.neutral200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary500),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Error banner if any
                  if (errorMessage != null) ...[
                    Container(
                      padding: AppSpacing.paddingAllMd,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: AppSpacing.roundedSm,
                        border: Border.all(color: AppColors.statusUrgent.withAlpha(80)),
                      ),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13.0),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Content based on step
                  if (_currentStep == 0) _buildStep0Welcome(isDark),
                  if (_currentStep == 1) _buildStep1UnitsAndName(isDark),
                  if (_currentStep == 2) _buildStep2Vitals(isDark, isLoading),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep0Welcome(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.health_and_safety_outlined,
          size: 56.0,
          color: AppColors.primary500,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Your Health. Your Baseline.',
          textAlign: TextAlign.center,
          style: isDark
              ? AppTypography.headlineLarge.copyWith(color: AppColors.neutral50)
              : AppTypography.headlineLarge.copyWith(color: AppColors.neutral900),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'HealthBase helps you monitor your health over time.\nIt does not diagnose medical conditions.',
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.primary500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Accurate Purpose Card
        AppCard(
          title: 'How HealthBase Works',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '1. Measure: Record your pulse, blood pressure, weight, and daily feelings.\n'
                '2. Compare: Build a personal statistical baseline based on your actual history.\n'
                '3. Understand: Identify what changed compared to your own typical ranges.\n'
                '4. Share: Export private PDF summaries for your healthcare provider.',
                style: TextStyle(fontSize: 14.0, height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Privacy Card
        AppCard(
          title: 'Privacy & Security First',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '• Your health measurements are strictly private to you.\n'
                '• Row Level Security (RLS) ensures nobody else can access your data.\n'
                '• We do not sell your data, show ads, or make automated clinical conclusions.',
                style: TextStyle(fontSize: 13.0, height: 1.5, color: AppColors.neutral600),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        AppButton(
          label: 'Continue to Setup',
          onPressed: () => setState(() => _currentStep = 1),
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStep1UnitsAndName(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Preferences & Name',
          textAlign: TextAlign.center,
          style: isDark
              ? AppTypography.headlineLarge.copyWith(color: AppColors.neutral50)
              : AppTypography.headlineLarge.copyWith(color: AppColors.neutral900),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Select your preferred measurement units.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(height: AppSpacing.xl),

        AppTextField(
          label: 'Your Name or Nickname',
          hintText: 'e.g. Alex',
          controller: _nameController,
          prefixIcon: const Icon(Icons.person_outline),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Unit system selection
        const Text(
          'Preferred Unit System',
          style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<UnitSystem>(
          segments: const [
            ButtonSegment(
              value: UnitSystem.metric,
              label: Text('Metric (kg, cm, °C)'),
              icon: Icon(Icons.straighten),
            ),
            ButtonSegment(
              value: UnitSystem.imperial,
              label: Text('Imperial (lbs, in, °F)'),
              icon: Icon(Icons.scale),
            ),
          ],
          selected: {_unitSystem},
          onSelectionChanged: (set) {
            setState(() {
              _unitSystem = set.first;
            });
          },
        ),
        const SizedBox(height: AppSpacing.xxl),

        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Back',
                variant: AppButtonVariant.secondary,
                onPressed: () => setState(() => _currentStep = 0),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: 'Continue',
                onPressed: () => setState(() => _currentStep = 2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2Vitals(bool isDark, bool isLoading) {
    final heightUnitLabel = _unitSystem == UnitSystem.metric ? 'cm' : 'inches';
    final weightUnitLabel = _unitSystem == UnitSystem.metric ? 'kg' : 'lbs';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Health Profile (Optional)',
          textAlign: TextAlign.center,
          style: isDark
              ? AppTypography.headlineLarge.copyWith(color: AppColors.neutral50)
              : AppTypography.headlineLarge.copyWith(color: AppColors.neutral900),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'These details help describe your personal baseline.\nYou can skip any or all of them now.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Date of Birth
        InkWell(
          onTap: _pickDateOfBirth,
          borderRadius: AppSpacing.roundedSm,
          child: Container(
            padding: AppSpacing.paddingAllMd,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.neutral300),
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 20.0),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date of Birth (Optional)',
                      style: TextStyle(fontSize: 12.0, color: AppColors.neutral500),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      _dateOfBirth != null
                          ? '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}'
                          : 'Not specified (Tap to select)',
                      style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Sex
        DropdownButtonFormField<SexType>(
          decoration: const InputDecoration(
            labelText: 'Sex (Optional)',
            prefixIcon: Icon(Icons.wc_outlined),
          ),
          initialValue: _selectedSex,
          items: SexType.values.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Text(s.displayName),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedSex = val),
        ),
        const SizedBox(height: AppSpacing.md),

        // Height
        AppTextField(
          label: 'Height ($heightUnitLabel) (Optional)',
          hintText: _unitSystem == UnitSystem.metric ? 'e.g. 175' : 'e.g. 69 (total inches)',
          controller: _heightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: const Icon(Icons.height_outlined),
        ),
        const SizedBox(height: AppSpacing.md),

        // Weight
        AppTextField(
          label: 'Weight ($weightUnitLabel) (Optional)',
          hintText: _unitSystem == UnitSystem.metric ? 'e.g. 70.5' : 'e.g. 155.0',
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: const Icon(Icons.monitor_weight_outlined),
        ),
        const SizedBox(height: AppSpacing.xl),

        AppButton(
          label: 'Complete Setup',
          isLoading: isLoading,
          onPressed: _handleComplete,
          isFullWidth: true,
        ),
        const SizedBox(height: AppSpacing.md),

        AppButton(
          label: 'Skip and Go to Dashboard',
          variant: AppButtonVariant.text,
          onPressed: isLoading ? null : _handleSkipAll,
          isFullWidth: true,
        ),
      ],
    );
  }
}
