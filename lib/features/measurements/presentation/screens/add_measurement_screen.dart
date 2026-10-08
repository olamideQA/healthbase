import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/components/app_button.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/app_text_field.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/domain/models/health_profile.dart';
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
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _tertiaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _clearFields() {
    _primaryController.clear();
    _secondaryController.clear();
    _tertiaryController.clear();
  }

  Future<void> _handleSubmit(String profileId, UnitSystem units) async {
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
        break;

      case MeasurementType.bloodPressure:
        systolicMmhg = double.tryParse(_primaryController.text.trim());
        diastolicMmhg = double.tryParse(_secondaryController.text.trim());
        if (_tertiaryController.text.trim().isNotEmpty) {
          pulseBpm = double.tryParse(_tertiaryController.text.trim());
        }
        break;

      case MeasurementType.weight:
        final raw = double.tryParse(_primaryController.text.trim());
        if (raw != null) {
          weightKg = isMetric ? raw : UnitConverter.lbsToKg(raw);
        }
        break;

      case MeasurementType.temperature:
        final raw = double.tryParse(_primaryController.text.trim());
        if (raw != null) {
          temperatureCelsius =
              isMetric ? raw : UnitConverter.fahrenheitToCelsius(raw);
        }
        break;

      case MeasurementType.bloodGlucose:
        final raw = double.tryParse(_primaryController.text.trim());
        if (raw != null) {
          glucoseMmolL = isMetric ? raw : raw / 18.0182;
        }
        break;
    }

    final measurement = Measurement(
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
    final profileAsync = ref.watch(myProfileProvider);
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

            return SingleChildScrollView(
              padding: AppSpacing.paddingAllLg,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Metric Type Selector
                    AppCard(
                      title: 'Measurement Type',
                      child: DropdownButtonFormField<MeasurementType>(
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
                          ],
                          if (_selectedType == MeasurementType.temperature) ...[
                            AppTextField(
                              label: 'Body Temperature (${isMetric ? '°C' : '°F'})',
                              hintText: isMetric ? 'e.g. 36.6' : 'e.g. 98.6',
                              controller: _primaryController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              prefixIcon: const Icon(Icons.thermostat_outlined),
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
