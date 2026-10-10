import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_button.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/app_loading_state.dart';
import '../../../../core/theme/components/app_text_field.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../auth/data/auth_repository.dart';
import '../../domain/models/health_profile.dart';
import '../controllers/profile_controller.dart';

/// Screen to view and update the user's personal health profile and unit preferences.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;

  // Edit form controllers & state
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  DateTime? _dateOfBirth;
  SexType? _selectedSex;
  UnitSystem _selectedUnits = UnitSystem.metric;

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _initializeEditFields(HealthProfile profile) {
    _nameController.text = profile.displayName ?? '';
    _selectedUnits = profile.preferredUnits;
    _dateOfBirth = profile.dateOfBirth;
    _selectedSex = profile.sex;

    if (profile.heightCm != null) {
      if (_selectedUnits == UnitSystem.metric) {
        _heightController.text = profile.heightCm!.toStringAsFixed(1);
      } else {
        final inches = UnitConverter.cmToInches(profile.heightCm!);
        _heightController.text = inches.toStringAsFixed(1);
      }
    } else {
      _heightController.clear();
    }

    if (profile.weightKg != null) {
      if (_selectedUnits == UnitSystem.metric) {
        _weightController.text = profile.weightKg!.toStringAsFixed(1);
      } else {
        final lbs = UnitConverter.kgToLbs(profile.weightKg!);
        _weightController.text = lbs.toStringAsFixed(1);
      }
    } else {
      _weightController.clear();
    }
  }

  Future<void> _saveChanges() async {
    double? heightCm;
    if (_heightController.text.trim().isNotEmpty) {
      final parsed = double.tryParse(_heightController.text.trim());
      if (parsed != null) {
        heightCm = _selectedUnits == UnitSystem.metric
            ? parsed
            : parsed * 2.54;
      }
    }

    double? weightKg;
    if (_weightController.text.trim().isNotEmpty) {
      final parsed = double.tryParse(_weightController.text.trim());
      if (parsed != null) {
        weightKg = _selectedUnits == UnitSystem.metric
            ? parsed
            : UnitConverter.lbsToKg(parsed);
      }
    }

    final success = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          displayName: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
          preferredUnits: _selectedUnits,
          dateOfBirth: _dateOfBirth,
          sex: _selectedSex,
          heightCm: heightCm,
          weightKg: weightKg,
        );

    if (success && mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: AppColors.statusStable,
        ),
      );
    }
  }

  Future<void> _handleUnitToggle(UnitSystem newUnits) async {
    setState(() => _selectedUnits = newUnits);
    await ref.read(profileControllerProvider.notifier).updatePreferredUnits(newUnits);
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
      setState(() => _dateOfBirth = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final authUser = ref.watch(authRepositoryProvider).currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Profile'),
        actions: [
          if (!_isEditing && profileState.value != null)
            TextButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 18.0),
              label: const Text('Edit'),
              onPressed: () {
                _initializeEditFields(profileState.value!);
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: profileState.when(
          loading: () => const AppLoadingState(message: 'Loading profile...'),
          error: (err, _) {
            final msg = err is Failure ? err.message : err.toString();
            return Center(
              child: Padding(
                padding: AppSpacing.paddingAllLg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48.0, color: AppColors.statusUrgent),
                    const SizedBox(height: AppSpacing.md),
                    Text(msg, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Retry',
                      onPressed: () => ref.read(profileControllerProvider.notifier).loadProfile(),
                    ),
                  ],
                ),
              ),
            );
          },
          data: (profile) {
            if (profile == null) {
              return Center(
                child: Padding(
                  padding: AppSpacing.paddingAllLg,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No health profile found.'),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Complete Onboarding',
                        onPressed: () => context.go('/onboarding'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final isMetric = profile.preferredUnits == UnitSystem.metric;
            final errorMessage = profileState.hasError
                ? (profileState.error is Failure
                    ? (profileState.error as Failure).message
                    : 'Validation error.')
                : null;

            return SingleChildScrollView(
              padding: AppSpacing.paddingAllLg,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600.0),
                child: _isEditing
                    ? _buildEditView(context, isDark, profileState.isLoading, errorMessage)
                    : _buildReadView(context, profile, authUser?.email, isMetric, isDark),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReadView(
    BuildContext context,
    HealthProfile profile,
    String? email,
    bool isMetric,
    bool isDark,
  ) {
    final ageText = profile.dateOfBirth != null
        ? '${DateTime.now().year - profile.dateOfBirth!.year} years'
        : 'Not specified';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Profile Header
        Row(
          children: [
            CircleAvatar(
              radius: 32.0,
              backgroundColor: AppColors.primary100,
              child: Text(
                (profile.displayName?.isNotEmpty == true
                        ? profile.displayName![0]
                        : 'U')
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName ?? 'HealthBase User',
                    style: isDark
                        ? AppTypography.headlineLarge.copyWith(color: AppColors.neutral50)
                        : AppTypography.headlineLarge.copyWith(color: AppColors.neutral900),
                  ),
                  if (email != null) ...[
                    const SizedBox(height: 2.0),
                    Text(
                      email,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // Unit System Preference
        AppCard(
          title: 'Unit System Preference',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HealthBase stores your health data in canonical scientific units and displays it in your preferred system.',
                style: TextStyle(fontSize: 13.0, color: AppColors.neutral500),
              ),
              const SizedBox(height: AppSpacing.md),
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
                selected: {profile.preferredUnits},
                emptySelectionAllowed: false,
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) {
                    _handleUnitToggle(set.first);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Personal Baseline Vitals
        AppCard(
          title: 'Physical Baseline Attributes',
          child: Column(
            children: [
              _buildInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date of Birth',
                value: profile.dateOfBirth != null
                    ? '${profile.dateOfBirth!.year}-${profile.dateOfBirth!.month.toString().padLeft(2, '0')}-${profile.dateOfBirth!.day.toString().padLeft(2, '0')} ($ageText)'
                    : 'Not specified',
              ),
              const Divider(height: AppSpacing.xl),
              _buildInfoRow(
                icon: Icons.wc_outlined,
                label: 'Biological Sex',
                value: profile.sex?.displayName ?? 'Not specified',
              ),
              const Divider(height: AppSpacing.xl),
              _buildInfoRow(
                icon: Icons.height_outlined,
                label: 'Height',
                value: UnitConverter.formatHeight(profile.heightCm, isMetric: isMetric),
              ),
              const Divider(height: AppSpacing.xl),
              _buildInfoRow(
                icon: Icons.monitor_weight_outlined,
                label: 'Weight',
                value: UnitConverter.formatWeight(profile.weightKg, isMetric: isMetric),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Setup & Onboarding Status
        AppCard(
          title: 'Account & Safety Details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                icon: Icons.check_circle_outline,
                label: 'Onboarding Status',
                value: profile.isOnboardingCompleted
                    ? 'Completed'
                    : 'Pending completion',
              ),
              const Divider(height: AppSpacing.xl),
              _buildInfoRow(
                icon: Icons.badge_outlined,
                label: 'Profile Scope',
                value: profile.isSelf ? 'Self (Primary Account Holder)' : 'Family Member',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditView(
    BuildContext context,
    bool isDark,
    bool isLoading,
    String? errorMessage,
  ) {
    final heightUnitLabel = _selectedUnits == UnitSystem.metric ? 'cm' : 'inches';
    final weightUnitLabel = _selectedUnits == UnitSystem.metric ? 'kg' : 'lbs';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Edit Health Profile',
          style: isDark
              ? AppTypography.headlineLarge.copyWith(color: AppColors.neutral50)
              : AppTypography.headlineLarge.copyWith(color: AppColors.neutral900),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Update your personal information and plausible ranges.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(height: AppSpacing.lg),

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

        AppTextField(
          label: 'Display Name',
          controller: _nameController,
          hintText: 'e.g. Alex',
          prefixIcon: const Icon(Icons.person_outline),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Date of Birth Picker
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
                      'Date of Birth',
                      style: TextStyle(fontSize: 12.0, color: AppColors.neutral500),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      _dateOfBirth != null
                          ? '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}'
                          : 'Not specified (Tap to set)',
                      style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Sex Selector
        DropdownButtonFormField<SexType>(
          decoration: const InputDecoration(
            labelText: 'Biological Sex',
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
        const SizedBox(height: AppSpacing.lg),

        // Height Field
        AppTextField(
          label: 'Height ($heightUnitLabel)',
          hintText: _selectedUnits == UnitSystem.metric ? 'e.g. 175.0' : 'e.g. 69.0',
          controller: _heightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: const Icon(Icons.height_outlined),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Weight Field
        AppTextField(
          label: 'Weight ($weightUnitLabel)',
          hintText: _selectedUnits == UnitSystem.metric ? 'e.g. 70.0' : 'e.g. 154.5',
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: const Icon(Icons.monitor_weight_outlined),
        ),
        const SizedBox(height: AppSpacing.xl),

        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Cancel',
                variant: AppButtonVariant.secondary,
                onPressed: isLoading ? null : () => setState(() => _isEditing = false),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: 'Save Changes',
                isLoading: isLoading,
                onPressed: _saveChanges,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20.0, color: AppColors.neutral500),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.0,
            color: AppColors.neutral600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
