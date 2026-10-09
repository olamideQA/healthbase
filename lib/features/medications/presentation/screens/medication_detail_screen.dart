import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_button.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../data/medication_repository.dart';
import '../../domain/models/medication.dart';

class MedicationDetailScreen extends ConsumerStatefulWidget {
  const MedicationDetailScreen({
    super.key,
    required this.medication,
  });

  final Medication medication;

  @override
  ConsumerState<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends ConsumerState<MedicationDetailScreen> {
  bool _isLogging = false;

  Future<void> _logDose(MedicationEventStatus status) async {
    setState(() => _isLogging = true);
    try {
      final repo = ref.read(medicationRepositoryProvider);
      await repo.recordEvent(
        profileId: widget.medication.profileId,
        medicationId: widget.medication.id,
        scheduledTime: DateTime.now(),
        status: status,
      );

      if (mounted) {
        ref.invalidate(medicationAdherenceProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dose recorded as ${status.displayName.toLowerCase()}.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording dose: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLogging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final med = widget.medication;
    final dateFormat = DateFormat('MMM d, yyyy');

    final adherenceAsync = ref.watch(medicationAdherenceProvider((
      profileId: med.profileId,
      medicationId: med.id,
    )));

    final eventsStream = ref.watch(medicationRepositoryProvider).watchEventsForMedication(
          medicationId: med.id,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(med.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove medication',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Remove Medication'),
                  content: Text('Are you sure you want to stop tracking ${med.name}?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await ref.read(medicationRepositoryProvider).deleteMedication(med.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingAllLg,
          children: [
            // 1. Medication Header Details Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: AppColors.primary500.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.medication, color: AppColors.primary600, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: AppTypography.headlineMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              med.dosage,
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.primary600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: med.isActive
                              ? AppColors.statusStable.withAlpha(25)
                              : AppColors.neutral400.withAlpha(25),
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: Text(
                          med.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: med.isActive ? AppColors.statusStable : AppColors.neutral500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Schedule', style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500)),
                      Text(med.frequency.displayName, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Start Date', style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500)),
                      Text(dateFormat.format(med.startDate), style: AppTypography.bodySmall),
                    ],
                  ),
                  if (med.reminderTime != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Reminder Time', style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500)),
                        Text(med.reminderTime!, style: AppTypography.bodySmall),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 2. Action: Log Dose Today
            Text(
              'LOG DOSE',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.neutral500,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Mark Taken',
                    icon: Icons.check_circle_outline,
                    isLoading: _isLogging,
                    onPressed: _isLogging ? null : () => _logDose(MedicationEventStatus.taken),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    label: 'Mark Missed',
                    variant: AppButtonVariant.outline,
                    icon: Icons.highlight_off,
                    isLoading: _isLogging,
                    onPressed: _isLogging ? null : () => _logDose(MedicationEventStatus.missed),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // 3. Adherence Statistics Card
            Text(
              'ADHERENCE STATISTICS',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.neutral500,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            adherenceAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading adherence stats: $err'),
              data: (stats) {
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Scheduled', '${stats.scheduledCount}', isDark),
                          Container(width: 1, height: 32, color: AppColors.neutral300),
                          _buildStatItem('Recorded Taken', '${stats.takenCount}', isDark, color: AppColors.statusStable),
                          Container(width: 1, height: 32, color: AppColors.neutral300),
                          _buildStatItem('Recorded Missed', '${stats.missedCount}', isDark, color: AppColors.statusDecreased),
                          Container(width: 1, height: 32, color: AppColors.neutral300),
                          _buildStatItem('Not Recorded', '${stats.notRecordedCount}', isDark, color: AppColors.neutral500),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recorded Adherence Rate',
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            stats.recordedAdherenceRate != null
                                ? '${stats.recordedAdherenceRate!.toStringAsFixed(1)}%'
                                : 'No doses logged yet',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: stats.recordedAdherenceRate != null && stats.recordedAdherenceRate! >= 80
                                  ? AppColors.statusStable
                                  : AppColors.primary600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Clearly distinguishes taken, missed, and unrecorded doses. HealthBase never assumes unrecorded doses were missed.',
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.neutral400 : AppColors.neutral500),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // 4. Dose History Timeline
            Text(
              'DOSE HISTORY',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.neutral500,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            StreamBuilder<List<MedicationEvent>>(
              stream: eventsStream,
              builder: (context, snapshot) {
                final events = snapshot.data ?? [];
                if (events.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text('No doses recorded yet. Use the buttons above to log taken or missed doses.'),
                  );
                }

                final timeFmt = DateFormat('MMM d, yyyy • h:mm a');

                return Column(
                  children: events.map((e) {
                    final isTaken = e.status == MedicationEventStatus.taken;
                    final color = isTaken ? AppColors.statusStable : AppColors.statusDecreased;

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                      padding: AppSpacing.paddingAllSm,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.neutral800 : AppColors.neutral50,
                        borderRadius: AppSpacing.roundedSm,
                        border: Border.all(
                          color: isDark ? AppColors.neutral700 : AppColors.neutral200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isTaken ? Icons.check_circle : Icons.highlight_off,
                            color: color,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              timeFmt.format(e.scheduledTime),
                              style: AppTypography.bodySmall,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              e.status.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? (isDark ? AppColors.neutral100 : AppColors.neutral900),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.neutral500),
        ),
      ],
    );
  }
}
