import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/safety/safety_boundaries.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../daily_check/domain/models/daily_check.dart';
import '../../../measurements/domain/models/measurement.dart';
import '../../../profile/domain/models/health_profile.dart';
import '../../domain/models/timeline_entry.dart';

class TimelineEntryDetailSheet extends StatelessWidget {
  const TimelineEntryDetailSheet({
    super.key,
    required this.record,
    required this.unitSystem,
  });

  final TimelineDayRecord record;
  final UnitSystem unitSystem;

  static void show(
    BuildContext context, {
    required TimelineDayRecord record,
    required UnitSystem unitSystem,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TimelineEntryDetailSheet(
        record: record,
        unitSystem: unitSystem,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fullDateFormat = DateFormat('EEEE, MMMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),

              // Title bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullDateFormat.format(record.date),
                            style: AppTypography.headlineMedium.copyWith(
                              color: isDark
                                  ? AppColors.neutral50
                                  : AppColors.neutral900,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Row(
                            children: [
                              _buildSyncStatusBadge(record.syncStatus),
                              const SizedBox(width: 8.0),
                              Text(
                                '${record.allDayMeasurements.length} measurements recorded',
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  color: AppColors.neutral500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: AppSpacing.lg),

              // Body content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  children: [
                    // Urgent red-flag safety alert if any symptom is urgent
                    if (record.hasUrgentSymptom) ...[
                      Container(
                        padding: AppSpacing.paddingAllMd,
                        decoration: BoxDecoration(
                          color: AppColors.statusUrgent.withAlpha(20),
                          borderRadius: AppSpacing.roundedMd,
                          border: Border.all(
                            color: AppColors.statusUrgent.withAlpha(80),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.statusUrgent,
                              size: 22.0,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Urgent Symptom Logged',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.statusUrgent,
                                      fontSize: 13.0,
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    SafetyBoundaries.emergencyWarningMessage,
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: isDark
                                          ? AppColors.neutral300
                                          : AppColors.neutral700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Daily Check Section
                    if (record.dailyCheck != null) ...[
                      _buildDailyCheckSection(
                        record.dailyCheck!,
                        isDark,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Measurements Breakdown Section
                    Text(
                      'RECORDED VITALS & MEASUREMENTS',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.neutral500,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    if (record.allDayMeasurements.isEmpty) ...[
                      AppCard(
                        child: Padding(
                          padding: AppSpacing.paddingAllMd,
                          child: Row(
                            children: const [
                              Icon(Icons.info_outline,
                                  size: 20.0, color: AppColors.neutral400),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                'No discrete vitals recorded on this day.',
                                style: TextStyle(
                                  color: AppColors.neutral500,
                                  fontSize: 13.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      ...record.allDayMeasurements.map((m) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _buildMetricIcon(m.type),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m.type.displayName,
                                            style: const TextStyle(
                                              fontSize: 13.0,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.neutral500,
                                            ),
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.baseline,
                                            textBaseline:
                                                TextBaseline.alphabetic,
                                            children: [
                                              Text(
                                                m.formattedPrimaryValue(unitSystem),
                                                style: AppTypography
                                                    .titleMedium
                                                    .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 4.0),
                                              Text(
                                                m.unitLabel(unitSystem),
                                                style: const TextStyle(
                                                  fontSize: 13.0,
                                                  color: AppColors.neutral500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      timeFormat.format(m.recordedAt),
                                      style: const TextStyle(
                                        fontSize: 12.0,
                                        color: AppColors.neutral400,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6.0),
                                const Divider(height: 8.0),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0,
                                        vertical: 2.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.neutral800
                                            : AppColors.neutral100,
                                        borderRadius: AppSpacing.roundedSm,
                                      ),
                                      child: Text(
                                        m.provenance.displayName,
                                        style: const TextStyle(
                                          fontSize: 11.0,
                                          color: AppColors.neutral600,
                                        ),
                                      ),
                                    ),
                                    if (m.notes != null &&
                                        m.notes!.isNotEmpty) ...[
                                      const SizedBox(width: 8.0),
                                      Expanded(
                                        child: Text(
                                          '“${m.notes}”',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12.0,
                                            fontStyle: FontStyle.italic,
                                            color: AppColors.neutral500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                    // Non-diagnostic footer
                    Center(
                      child: Text(
                        SafetyBoundaries.generalDisclaimer,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.0,
                          color: AppColors.neutral400,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyCheckSection(
    DailyCheck dailyCheck,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DAILY HEALTH CHECK',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.neutral500,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary500.withAlpha(25),
                      borderRadius: AppSpacing.roundedFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sentiment_satisfied,
                            size: 16.0, color: AppColors.primary500),
                        const SizedBox(width: 4.0),
                        Text(
                          dailyCheck.feeling.displayName,
                          style: const TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: AppColors.secondary500.withAlpha(25),
                      borderRadius: AppSpacing.roundedFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.medication_outlined,
                            size: 16.0, color: AppColors.secondary500),
                        const SizedBox(width: 4.0),
                        Text(
                          dailyCheck.medicationStatus.displayName,
                          style: const TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (dailyCheck.symptoms.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Reported Symptoms:',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                  ),
                ),
                const SizedBox(height: 6.0),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: dailyCheck.symptoms.map<Widget>((s) {
                    final isUrgent = s.isUrgent;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? AppColors.statusUrgent.withAlpha(25)
                            : (isDark ? AppColors.neutral800 : AppColors.neutral200),
                        borderRadius: AppSpacing.roundedSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isUrgent) ...[
                            const Icon(Icons.warning,
                                size: 12.0, color: AppColors.statusUrgent),
                            const SizedBox(width: 4.0),
                          ],
                          Text(
                            s.displayName,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: isUrgent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isUrgent
                                  ? AppColors.statusUrgent
                                  : (isDark
                                      ? AppColors.neutral200
                                      : AppColors.neutral800),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (dailyCheck.notes != null &&
                  dailyCheck.notes!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  '“${dailyCheck.notes}”',
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontStyle: FontStyle.italic,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyncStatusBadge(SyncStatus status) {
    return switch (status) {
      SyncStatus.synced => Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.cloud_done, size: 14.0, color: AppColors.statusStable),
            SizedBox(width: 3.0),
            Text(
              'Synced',
              style: TextStyle(fontSize: 11.0, color: AppColors.statusStable),
            ),
          ],
        ),
      SyncStatus.pendingInsert ||
      SyncStatus.pendingUpdate ||
      SyncStatus.pendingDelete =>
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.cloud_upload_outlined,
                size: 14.0, color: AppColors.statusIncreased),
            SizedBox(width: 3.0),
            Text(
              'Pending Sync',
              style: TextStyle(fontSize: 11.0, color: AppColors.statusIncreased),
            ),
          ],
        ),
      SyncStatus.syncError => Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.cloud_off, size: 14.0, color: AppColors.statusUrgent),
            SizedBox(width: 3.0),
            Text(
              'Sync Error',
              style: TextStyle(fontSize: 11.0, color: AppColors.statusUrgent),
            ),
          ],
        ),
    };
  }

  Widget _buildMetricIcon(MeasurementType type) {
    final iconData = switch (type) {
      MeasurementType.heartRate => Icons.favorite,
      MeasurementType.bloodPressure => Icons.speed,
      MeasurementType.temperature => Icons.thermostat,
      MeasurementType.weight => Icons.monitor_weight,
      MeasurementType.bloodGlucose => Icons.water_drop,
    };

    final color = switch (type) {
      MeasurementType.heartRate => AppColors.statusUrgent,
      MeasurementType.bloodPressure => AppColors.primary500,
      MeasurementType.temperature => AppColors.statusIncreased,
      MeasurementType.weight => AppColors.secondary500,
      MeasurementType.bloodGlucose => AppColors.statusDecreased,
    };

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20.0),
    );
  }
}
