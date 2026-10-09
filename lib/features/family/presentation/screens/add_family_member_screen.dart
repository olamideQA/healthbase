import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_button.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../profile/domain/models/health_profile.dart';
import '../../data/family_repository.dart';
import '../../domain/models/family_profile.dart';

class AddFamilyMemberScreen extends ConsumerStatefulWidget {
  const AddFamilyMemberScreen({super.key});

  @override
  ConsumerState<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends ConsumerState<AddFamilyMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _customRelationController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _selectedRelation = 'Mum';
  bool _isCustomRelation = false;
  DateTime? _dateOfBirth;
  SexType? _selectedSex;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _customRelationController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveFamilyMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final repo = ref.read(familyRepositoryProvider);

    final finalRelation = _isCustomRelation
        ? _customRelationController.text.trim()
        : _selectedRelation;

    try {
      final height = double.tryParse(_heightController.text.trim());
      final weight = double.tryParse(_weightController.text.trim());

      await repo.createFamilyMember(
        displayName: _nameController.text.trim(),
        relationshipLabel: finalRelation.isNotEmpty ? finalRelation : null,
        dateOfBirth: _dateOfBirth,
        sex: _selectedSex,
        heightCm: height,
        weightKg: weight,
      );

      if (mounted) {
        ref.invalidate(familyProfilesStreamProvider);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_nameController.text.trim()} added to your family profiles.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding family member: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Family Member'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingAllLg,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Non-Biological Relationships Disclaimer Banner
                Container(
                  padding: AppSpacing.paddingAllMd,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(
                      color: isDark ? AppColors.neutral700 : AppColors.neutral200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.family_restroom,
                        size: 20,
                        color: AppColors.primary600,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          RelationshipCategory.clinicalDisclaimer,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Name Field
                Text(
                  'NAME OR NICKNAME *',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.neutral500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Mum, Papa Joe, Sarah',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name for this family member';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Relationship Selector
                Text(
                  'RELATIONSHIP',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.neutral500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    ...RelationshipCategory.commonOptions.map((rel) {
                      final isSelected = !_isCustomRelation && _selectedRelation == rel;
                      return ChoiceChip(
                        label: Text(rel),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedRelation = rel;
                              _isCustomRelation = false;
                            });
                          }
                        },
                      );
                    }),
                    ChoiceChip(
                      label: const Text('Custom...'),
                      selected: _isCustomRelation,
                      onSelected: (selected) {
                        setState(() {
                          _isCustomRelation = true;
                        });
                      },
                    ),
                  ],
                ),
                if (_isCustomRelation) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _customRelationController,
                    decoration: const InputDecoration(
                      hintText: 'Specify relationship (e.g. Caregiver, Godparent)',
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),

                // Optional Physical Attributes Card
                Text(
                  'OPTIONAL PROFILE DETAILS',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.neutral500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: Column(
                    children: [
                      // Date of Birth
                      Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.cake_outlined, color: AppColors.primary600),
                          title: const Text('Date of Birth'),
                          subtitle: Text(
                            _dateOfBirth != null
                                ? dateFormat.format(_dateOfBirth!)
                                : 'Not specified',
                          ),
                          trailing: const Icon(Icons.calendar_today, size: 18),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dateOfBirth ?? DateTime(1980, 1, 1),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _dateOfBirth = picked);
                            }
                          },
                        ),
                      ),
                      const Divider(),
                      // Sex Dropdown
                      Row(
                        children: [
                          const Icon(Icons.wc, color: AppColors.primary600),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<SexType>(
                                isExpanded: true,
                                value: _selectedSex,
                                hint: const Text('Biological / Administrative Sex'),
                                items: [
                                  const DropdownMenuItem<SexType>(
                                    value: null,
                                    child: Text('Prefer not to say / Unspecified'),
                                  ),
                                  ...SexType.values.map(
                                    (s) => DropdownMenuItem<SexType>(
                                      value: s,
                                      child: Text(s.displayName),
                                    ),
                                  ),
                                ],
                                onChanged: (val) => setState(() => _selectedSex = val),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Save Action
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: _isSaving ? 'Creating Profile...' : 'Save Family Profile',
                    icon: Icons.check,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _saveFamilyMember,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
