import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/safety/clinical_thresholds.dart';
import '../../../../core/safety/emergency_protocols.dart';
import '../../../../core/safety/widgets/clinical_disclaimer_sheet.dart';
import '../../../../core/safety/widgets/emergency_dialog.dart';
import '../../../../core/safety/widgets/urgent_care_alert_banner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/components/app_button.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/app_text_field.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../family/data/family_repository.dart';
import '../../../profile/domain/models/health_profile.dart';
import '../../data/measurement_repository.dart';
import '../../domain/models/measurement.dart';
import '../controllers/measurement_controller.dart';

class AddMeasurementScreen extends ConsumerStatefulWidget {
  const AddMeasurementScreen({super.key, this.initialType});

  final MeasurementType? initialType;

  @override
  ConsumerState<AddMeasurementScreen> createState() => _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends ConsumerState<AddMeasurementScreen> {
  late MeasurementType _selectedType;
  MeasurementSource _selectedSource = MeasurementSource.manual;
  MeasurementProvenance _selectedProvenance = MeasurementProvenance.manuallyEntered;

  final _primaryController = TextEditingController();
  final _secondaryController = TextEditingController();
  final _tertiaryController = TextEditingController();
  final _notesController = TextEditingController();

  final DateTime _recordedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? MeasurementType.heartRate;
    _primaryController.addListener(_onInputValueChanged);
    _secondaryController.addListener(_onInputValueChanged);
  }

  @override
  void dispose() {
    _primaryController.removeListener(_onInputValueChanged);
    _secondaryController.removeListener(_onInputValueChanged);
    _primaryController.dispose();
    _secondaryController.dispose();
    _tertiaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onInputValueChanged() {
    setState(() {});
  }

  void _clearFields() {
    _primaryController.clear();
    _secondaryController.clear();
    _tertiaryController.clear();
  }

  List<String> _contextTagsForType(MeasurementType type) => switch (type) {
        MeasurementType.heartRate => const ['Resting', 'Morning', 'After Walk', 'Post-Exercise'],
        MeasurementType.bloodPressure => const ['Rested 5m', 'Sitting', 'Left Arm', 'Morning'],
        MeasurementType.weight => const ['Morning Fasting', 'Post-Workout', 'Evening'],
        MeasurementType.temperature => const ['Oral', 'Forehead', 'Morning', 'Evening'],
        MeasurementType.bloodGlucose => const ['Fasting', 'Before Meal', '2h Post-Meal', 'Bedtime'],
      };

  void _toggleNoteTag(String tag) {
    final current = _notesController.text.trim();
    final parts = current.isEmpty
        ? <String>[]
        : current.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.contains(tag)) {
      parts.remove(tag);
    } else {
      parts.add(tag);
    }
    setState(() {
      _notesController.text = parts.join(', ');
    });
  }

  void _applyLastReading(Measurement last, bool isMetric) {
    switch (_selectedType) {
      case MeasurementType.heartRate:
        if (last.heartRateBpm != null) {
          _primaryController.text = last.heartRateBpm!.toInt().toString();
        }
        break;
      case MeasurementType.bloodPressure:
        if (last.systolicMmhg != null) {
          _primaryController.text = last.systolicMmhg!.toInt().toString();
        }
        if (last.diastolicMmhg != null) {
          _secondaryController.text = last.diastolicMmhg!.toInt().toString();
        }
        if (last.pulseBpm != null) {
          _tertiaryController.text = last.pulseBpm!.toInt().toString();
        }
        break;
      case MeasurementType.weight:
        if (last.weightKg != null) {
          final v = isMetric ? last.weightKg! : UnitConverter.kgToLbs(last.weightKg!);
          _primaryController.text = v.toStringAsFixed(1);
        }
        break;
      case MeasurementType.temperature:
        if (last.temperatureCelsius != null) {
          final v = isMetric
              ? last.temperatureCelsius!
              : UnitConverter.celsiusToFahrenheit(last.temperatureCelsius!);
          _primaryController.text = v.toStringAsFixed(1);
        }
        break;
      case MeasurementType.bloodGlucose:
        if (last.glucoseMmolL != null) {
          final v = isMetric ? last.glucoseMmolL! : last.glucoseMmolL! * 18.0182;
          _primaryController.text = v.toStringAsFixed(isMetric ? 1 : 0);
        }
        break;
    }
  }

  String _formatLastReadingSummary(Measurement last, bool isMetric) => switch (_selectedType) {
        MeasurementType.heartRate => '${last.heartRateBpm?.toInt() ?? '--'} bpm',
        MeasurementType.bloodPressure =>
          '${last.systolicMmhg?.toInt() ?? '--'}/${last.diastolicMmhg?.toInt() ?? '--'} mmHg',
        MeasurementType.weight => last.weightKg == null
            ? '--'
            : '${(isMetric ? last.weightKg! : UnitConverter.kgToLbs(last.weightKg!)).toStringAsFixed(1)} ${isMetric ? 'kg' : 'lbs'}',
        MeasurementType.temperature => last.temperatureCelsius == null
            ? '--'
            : '${(isMetric ? last.temperatureCelsius! : UnitConverter.celsiusToFahrenheit(last.temperatureCelsius!)).toStringAsFixed(1)} ${isMetric ? '°C' : '°F'}',
        MeasurementType.bloodGlucose => last.glucoseMmolL == null
            ? '--'
            : '${(isMetric ? last.glucoseMmolL! : last.glucoseMmolL! * 18.0182).toStringAsFixed(isMetric ? 1 : 0)} ${isMetric ? 'mmol/L' : 'mg/dL'}',
      };

  void _nudgePrimary(double delta, {required bool integerField, required double defaultSeed}) {
    final current = double.tryParse(_primaryController.text.trim()) ?? defaultSeed;
    final next = (current + delta).clamp(1.0, 999.0);
    _primaryController.text =
        integerField ? next.round().toString() : next.toStringAsFixed(1);
  }

  Measurement? _buildMeasurementFromInputs(String profileId, UnitSystem units) {
    final isMetric = units == UnitSystem.metric;
    double? heartRateBpm;
    double? systolicMmhg;
    double? diastolicMmhg;
    double? pulseBpm;
    double? temperatureCelsius;
    double? weightKg;
    double? glucoseMmolL;

    switch (_selectedType) {
      case MeasurementType.heartRate:
        heartRateBpm = double.tryParse(_primaryController.text.trim());
        if (heartRateBpm == null) return null;
        break;

      case MeasurementType.bloodPressure:
        systolicMmhg = double.tryParse(_primaryController.text.trim());
        diastolicMmhg = double.tryParse(_secondaryController.text.trim());
        if (_tertiaryController.text.trim().isNotEmpty) {
          pulseBpm = double.tryParse(_tertiaryController.text.trim());
        }
        if (systolicMmhg == null || diastolicMmhg == null) return null;
        break;

      case MeasurementType.weight:
        final raw = double.tryParse(_primaryController.text.trim());
        if (raw == null) return null;
        weightKg = isMetric ? raw : UnitConverter.lbsToKg(raw);
        break;

      case MeasurementType.temperature:
        final raw = double.tryParse(_primaryController.text.trim());
        if (raw == null) return null;
        temperatureCelsius =
            isMetric ? raw : UnitConverter.fahrenheitToCelsius(raw);
        break;

      case MeasurementType.bloodGlucose:
        final raw = double.tryParse(_primaryController.text.trim());
        if (raw == null) return null;
        glucoseMmolL = isMetric ? raw : raw / 18.0182;
        break;
    }

    return Measurement(
      id: '',
      profileId: profileId,
      type: _selectedType,
      heartRateBpm: heartRateBpm,
      systolicMmhg: systolicMmhg,
      diastolicMmhg: diastolicMmhg,
      pulseBpm: pulseBpm,
      temperatureCelsius: temperatureCelsius,
      weightKg: weightKg,
      glucoseMmolL: glucoseMmolL,
      source: _selectedSource,
      provenance: _selectedProvenance,
      recordedAt: _recordedAt,
      recordedUtcOffset: DateTime.now().timeZoneOffset.inMinutes,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _handleSubmit(String profileId, UnitSystem units) async {
    final measurement = _buildMeasurementFromInputs(profileId, units);
    if (measurement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid numeric measurement.'),
          backgroundColor: AppColors.statusUrgent,
        ),
      );
      return;
    }

    // Physical plausibility guard
    if (!ClinicalThresholds.isPhysicallyPlausible(measurement)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The entered values fall outside physically plausible boundaries. For blood pressure, systolic must exceed diastolic.',
          ),
          backgroundColor: AppColors.statusUrgent,
        ),
      );
      return;
    }

    // Emergency protocol evaluation
    final emergencyAlert = EmergencyProtocols.evaluateMeasurement(measurement);
    if (emergencyAlert != null && emergencyAlert.isImmediateEmergency) {
      final shouldSave = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.statusUrgent),
              SizedBox(width: 8),
              Expanded(child: Text('Clinical Safety Notice')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                emergencyAlert.headline,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF991B1B),
                ),
              ),
              const SizedBox(height: 8),
              Text(emergencyAlert.guidance),
              const SizedBox(height: 12),
              const Text(
                'HealthBase is a monitoring tool and not an emergency service. Do not delay urgent medical care.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Region-aware directory (US 911, UK 999, EU 112, AU 000)
                // instead of a hardcoded number.
                showEmergencyDialog(ctx);
              },
              child: const Text(
                'Emergency Numbers',
                style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save Record Anyway'),
            ),
          ],
        ),
      );

      if (shouldSave != true) return;
    }

    final success = await ref
        .read(measurementControllerProvider.notifier)
        .recordMeasurement(measurement);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedType.displayName} saved locally.'),
          backgroundColor: AppColors.statusStable,
        ),
      );
      if (context.canPop()) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final state = ref.watch(measurementControllerProvider);
    final isLoading = state.isLoading;
    final errorMessage = state.hasError
        ? (state.error is Failure
            ? (state.error as Failure).message
            : 'Unable to save measurement.')
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Measurement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Clinical & Safety Guidelines',
            onPressed: () => showClinicalDisclaimerSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Profile error: $err')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profile not found.'));
            }

            final units = profile.preferredUnits;
            final isMetric = units == UnitSystem.metric;
            final previewMeasurement = _buildMeasurementFromInputs(profile.id, units);
            final liveAlert = previewMeasurement != null
                ? EmergencyProtocols.evaluateMeasurement(previewMeasurement)
                : null;

            final recentAsync = ref.watch(measurementsStreamProvider(profile.id));
            final lastForType = recentAsync.valueOrNull
                ?.where((m) => m.type == _selectedType)
                .firstOrNull;
            final contextTags = _contextTagsForType(_selectedType);
            final activeNotes = _notesController.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toSet();

            return SingleChildScrollView(
              padding: AppSpacing.paddingAllLg,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Metric Type Selector (1-Tap Pills + Dropdown)
                    AppCard(
                      title: 'Measurement Type',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: MeasurementType.values.map((t) {
                              final selected = t == _selectedType;
                              return ChoiceChip(
                                label: Text(t.displayName),
                                selected: selected,
                                onSelected: (val) {
                                  if (val && t != _selectedType) {
                                    setState(() {
                                      _selectedType = t;
                                      _clearFields();
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<MeasurementType>(
                            key: ValueKey('dropdown-${_selectedType.name}'),
                            initialValue: _selectedType,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.favorite_outline),
                            ),
                            items: MeasurementType.values.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(t.displayName),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedType = val;
                                  _clearFields();
                                });
                              }
                            },
                          ),
                        ],
                      ),
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
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 13.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Input Form for selected type
                    AppCard(
                      title: 'Measurement Value',
                      trailing: lastForType != null
                          ? ActionChip(
                              avatar: const Icon(Icons.history, size: 16),
                              label: Text(
                                'Use last: ${_formatLastReadingSummary(lastForType, isMetric)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () => _applyLastReading(lastForType, isMetric),
                            )
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedType == MeasurementType.heartRate) ...[
                            AppTextField(
                              label: 'Heart Rate (bpm)',
                              hintText: 'e.g. 72',
                              controller: _primaryController,
                              keyboardType: TextInputType.number,
                              prefixIcon: const Icon(Icons.favorite, color: AppColors.statusUrgent),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.xs,
                              children: [
                                ActionChip(
                                  label: const Text('-5'),
                                  onPressed: () => _nudgePrimary(-5, integerField: true, defaultSeed: 72),
                                ),
                                ActionChip(
                                  label: const Text('-1'),
                                  onPressed: () => _nudgePrimary(-1, integerField: true, defaultSeed: 72),
                                ),
                                ActionChip(
                                  label: const Text('+1'),
                                  onPressed: () => _nudgePrimary(1, integerField: true, defaultSeed: 72),
                                ),
                                ActionChip(
                                  label: const Text('+5'),
                                  onPressed: () => _nudgePrimary(5, integerField: true, defaultSeed: 72),
                                ),
                              ],
                            ),
                          ],
                          if (_selectedType == MeasurementType.bloodPressure) ...[
                            AppTextField(
                              label: 'Systolic Pressure (mmHg)',
                              hintText: 'e.g. 120',
                              controller: _primaryController,
                              keyboardType: TextInputType.number,
                              prefixIcon: const Icon(Icons.speed),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              label: 'Diastolic Pressure (mmHg)',
                              hintText: 'e.g. 80',
                              controller: _secondaryController,
                              keyboardType: TextInputType.number,
                              prefixIcon: const Icon(Icons.speed_outlined),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              label: 'Pulse (bpm) (Optional)',
                              hintText: 'e.g. 70',
                              controller: _tertiaryController,
                              keyboardType: TextInputType.number,
                              prefixIcon: const Icon(Icons.favorite_border),
                            ),
                          ],
                          if (_selectedType == MeasurementType.weight) ...[
                            AppTextField(
                              label: 'Weight (${isMetric ? 'kg' : 'lbs'})',
                              hintText: isMetric ? 'e.g. 70.5' : 'e.g. 155.0',
                              controller: _primaryController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              prefixIcon: const Icon(Icons.monitor_weight_outlined),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.xs,
                              children: [
                                ActionChip(
                                  label: const Text('-0.5'),
                                  onPressed: () => _nudgePrimary(
                                    -0.5,
                                    integerField: false,
                                    defaultSeed: isMetric ? 70.0 : 154.0,
                                  ),
                                ),
                                ActionChip(
                                  label: const Text('-0.1'),
                                  onPressed: () => _nudgePrimary(
                                    -0.1,
                                    integerField: false,
                                    defaultSeed: isMetric ? 70.0 : 154.0,
                                  ),
                                ),
                                ActionChip(
                                  label: const Text('+0.1'),
                                  onPressed: () => _nudgePrimary(
                                    0.1,
                                    integerField: false,
                                    defaultSeed: isMetric ? 70.0 : 154.0,
                                  ),
                                ),
                                ActionChip(
                                  label: const Text('+0.5'),
                                  onPressed: () => _nudgePrimary(
                                    0.5,
                                    integerField: false,
                                    defaultSeed: isMetric ? 70.0 : 154.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_selectedType == MeasurementType.temperature) ...[
                            AppTextField(
                              label: 'Body Temperature (${isMetric ? '°C' : '°F'})',
                              hintText: isMetric ? 'e.g. 36.6' : 'e.g. 98.6',
                              controller: _primaryController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              prefixIcon: const Icon(Icons.thermostat_outlined),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.xs,
                              children: [
                                ActionChip(
                                  label: const Text('-0.2'),
                                  onPressed: () => _nudgePrimary(
                                    -0.2,
                                    integerField: false,
                                    defaultSeed: isMetric ? 36.6 : 98.6,
                                  ),
                                ),
                                ActionChip(
                                  label: const Text('+0.2'),
                                  onPressed: () => _nudgePrimary(
                                    0.2,
                                    integerField: false,
                                    defaultSeed: isMetric ? 36.6 : 98.6,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_selectedType == MeasurementType.bloodGlucose) ...[
                            AppTextField(
                              label: 'Blood Glucose (${isMetric ? 'mmol/L' : 'mg/dL'})',
                              hintText: isMetric ? 'e.g. 5.4' : 'e.g. 97',
                              controller: _primaryController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              prefixIcon: const Icon(Icons.water_drop_outlined),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Real-time clinical alert if entered value is in critical range
                    if (liveAlert != null) ...[
                      UrgentCareAlertBanner(alert: liveAlert),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Context, Source & Provenance
                    AppCard(
                      title: 'Provenance & Source',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<MeasurementSource>(
                            initialValue: _selectedSource,
                            decoration: const InputDecoration(labelText: 'Data Source'),
                            items: MeasurementSource.values.map((s) {
                              return DropdownMenuItem(value: s, child: Text(s.displayName));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSource = val);
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<MeasurementProvenance>(
                            initialValue: _selectedProvenance,
                            decoration: const InputDecoration(labelText: 'Measurement Provenance'),
                            items: MeasurementProvenance.values.map((p) {
                              return DropdownMenuItem(value: p, child: Text(p.displayName));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedProvenance = val);
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'Quick Context Tags',
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.neutral600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: contextTags.map((tag) {
                              final isSelected = activeNotes.contains(tag);
                              return FilterChip(
                                label: Text(tag, style: const TextStyle(fontSize: 12)),
                                selected: isSelected,
                                onSelected: (_) => _toggleNoteTag(tag),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Notes (Optional)',
                            hintText: 'e.g. Measured right after morning walk',
                            controller: _notesController,
                            maxLines: 2,
                            prefixIcon: const Icon(Icons.notes_outlined),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    AppButton(
                      label: 'Save Measurement',
                      isLoading: isLoading,
                      onPressed: () => _handleSubmit(profile.id, units),
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
