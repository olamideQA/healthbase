import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_button.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/medication_repository.dart';
import '../../domain/models/medication.dart';
import '../../domain/services/medication_reminder_service.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  MedicationFrequency _selectedFrequency = MedicationFrequency.daily;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  TimeOfDay? _reminderTime;
  bool _isSaving = false;

  final _reminderService = const MedicationReminderService();

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final profile = await ref.read(myProfileProvider.future);
      if (profile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile not loaded. Cannot save medication.')),
          );
        }
        return;
      }
      final reminderString = _reminderTime != null
          ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
          : null;

      await ref.read(medicationRepositoryProvider).addMedication(
            profileId: profile.id,
            name: _nameController.text,
            dosage: _dosageController.text,
            frequency: _selectedFrequency,
            startDate: _startDate,
            endDate: _endDate,
            reminderTime: reminderString,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication added to your tracker.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving medication: $e')),
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
        title: const Text('Add Medication'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingAllLg,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mandatory Clinical Dosage Boundary Banner
                Container(
                  padding: AppSpacing.paddingAllMd,
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withAlpha(20),
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(color: AppColors.primary500.withAlpha(60)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 20,
                        color: AppColors.primary600,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Important: HealthBase does not calculate or recommend medication dosage. Enter the exact instructions provided by your doctor or pharmacist.',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.neutral200 : AppColors.neutral800,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Medication Name
                Text(
                  'MEDICATION NAME',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.neutral500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Lisinopril, Metformin, Vitamin D',
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a medication name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Dosage Text (Free text entered by user)
                Text(
                  'DOSAGE INSTRUCTIONS (AS PRESCRIBED)',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.neutral500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _dosageController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 10mg with water in the morning',
                    prefixIcon: Icon(Icons.edit_note_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter dosage instructions';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Frequency Dropdown
                Text(
                  'FREQUENCY',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.neutral500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<MedicationFrequency>(
                  initialValue: _selectedFrequency,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  items: MedicationFrequency.values.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(f.displayName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedFrequency = val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Start Date & Optional End Date
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'START DATE',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.neutral500,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _startDate = picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(dateFormat.format(_startDate)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'END DATE (OPTIONAL)',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.neutral500,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
                                firstDate: _startDate,
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _endDate = picked);
                              }
                            },
                            icon: const Icon(Icons.event_busy, size: 16),
                            label: Text(_endDate == null ? 'Ongoing' : dateFormat.format(_endDate!)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Reminder Time
                Text(
                  'REMINDER TIME',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.neutral500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
                        );
                        if (picked != null) {
                          setState(() => _reminderTime = picked);
                        }
                      },
                      icon: const Icon(Icons.alarm, size: 16),
                      label: Text(
                        _reminderTime == null
                            ? 'Set reminder time'
                            : _reminderTime!.format(context),
                      ),
                    ),
                    if (_reminderTime != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _reminderTime = null),
                      ),
                    ],
                  ],
                ),

                // Platform notification status note
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _reminderService.supportMessage,
                  style: TextStyle(
                    fontSize: 11.0,
                    color: kIsWeb ? AppColors.statusIncreased : AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Notes
                Text(
                  'NOTES (OPTIONAL)',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.neutral500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Take with food, prescribe refill in 3 months',
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Save Action Button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: _isSaving ? 'Saving...' : 'Save Medication',
                    icon: Icons.check,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _saveMedication,
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
