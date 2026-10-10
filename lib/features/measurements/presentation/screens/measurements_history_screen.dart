import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/app_loading_state.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/domain/models/health_profile.dart';
import '../../data/measurement_repository.dart';
import '../../domain/models/measurement.dart';
import '../controllers/measurement_controller.dart';

class MeasurementsHistoryScreen extends ConsumerStatefulWidget {
  const MeasurementsHistoryScreen({super.key});

  @override
  ConsumerState<MeasurementsHistoryScreen> createState() =>
      _MeasurementsHistoryScreenState();
}

class _MeasurementsHistoryScreenState
    extends ConsumerState<MeasurementsHistoryScreen> {
  MeasurementType? _filterType;

  final _dateFormat = DateFormat('MMM d, y • h:mm a');

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync now',
            onPressed: () {
              final profile = profileAsync.value;
              if (profile != null) {
                ref
                    .read(measurementControllerProvider.notifier)
                    .sync(profile.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Syncing measurements with cloud...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/measurements/add'),
        icon: const Icon(Icons.add),
        label: const Text('Record'),
        backgroundColor: AppColors.primary500,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () =>
              const AppLoadingState(message: 'Loading measurements...'),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profile not found.'));
            }

            final units = profile.preferredUnits;
            final measurementsAsync =
                ref.watch(measurementsStreamProvider(profile.id));

            return Column(
              children: [
                // Filter bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _filterType == null,
                        onSelected: (_) => setState(() => _filterType = null),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ...MeasurementType.values.map((type) {
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: FilterChip(
                            label: Text(type.displayName),
                            selected: _filterType == type,
                            onSelected: (selected) {
                              setState(() {
                                _filterType = selected ? type : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Measurement List
                Expanded(
                  child: measurementsAsync.when(
                    loading: () => const AppLoadingState(
                        message: 'Reading encrypted local storage...'),
                    error: (err, _) => Center(child: Text('Database error: $err')),
                    data: (allMeasurements) {
                      final filtered = _filterType == null
                          ? allMeasurements
                          : allMeasurements
                              .where((m) => m.type == _filterType)
                              .toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: AppSpacing.paddingAllXl,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.monitor_heart_outlined,
                                  size: 48.0,
                                  color: AppColors.neutral400,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'No measurements recorded yet',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: isDark
                                        ? AppColors.neutral300
                                        : AppColors.neutral700,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                const Text(
                                  'Record your first vitals reading using the button below.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    color: AppColors.neutral500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          await ref
                              .read(measurementControllerProvider.notifier)
                              .sync(profile.id);
                        },
                        child: ListView.separated(
                          padding: AppSpacing.paddingAllLg,
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final measurement = filtered[index];
                            return _buildMeasurementCard(
                              context,
                              measurement,
                              units,
                              profile.id,
                              isDark,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMeasurementCard(
    BuildContext context,
    Measurement measurement,
    UnitSystem units,
    String profileId,
    bool isDark,
  ) {
    final valueText = measurement.formattedPrimaryValue(units);
    final unitLabel = measurement.unitLabel(units);
    final dateText = _dateFormat.format(measurement.recordedAt);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTypeIcon(measurement.type),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      measurement.type.displayName,
                      style: const TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.neutral500,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          valueText,
                          style: isDark
                              ? AppTypography.headlineMedium
                                  .copyWith(color: AppColors.neutral50)
                              : AppTypography.headlineMedium
                                  .copyWith(color: AppColors.neutral900),
                        ),
                        if (measurement.type == MeasurementType.heartRate ||
                            measurement.type == MeasurementType.bloodPressure) ...[
                          const SizedBox(width: 4.0),
                          Text(
                            unitLabel,
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: AppColors.neutral500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _buildSyncBadge(measurement.syncStatus),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20.0),
                color: AppColors.neutral400,
                onPressed: () => _confirmDelete(context, measurement.id, profileId),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: AppSpacing.sm),
          const SizedBox(height: AppSpacing.xs),

          // Metadata row
          Row(
            children: [
              Icon(Icons.access_time, size: 14.0, color: AppColors.neutral400),
              const SizedBox(width: 4.0),
              Text(
                dateText,
                style: const TextStyle(fontSize: 12.0, color: AppColors.neutral500),
              ),
              const Spacer(),
              // Provenance pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  measurement.provenance.displayName,
                  style: const TextStyle(fontSize: 11.0, color: AppColors.neutral600),
                ),
              ),
            ],
          ),

          if (measurement.notes != null && measurement.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '“${measurement.notes}”',
              style: const TextStyle(
                fontSize: 12.0,
                fontStyle: FontStyle.italic,
                color: AppColors.neutral500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeIcon(MeasurementType type) {
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
      child: Icon(iconData, color: color, size: 24.0),
    );
  }

  Widget _buildSyncBadge(SyncStatus status) {
    return switch (status) {
      SyncStatus.synced => const Tooltip(
          message: 'Synced with cloud',
          child: Icon(Icons.cloud_done, size: 18.0, color: AppColors.statusStable),
        ),
      SyncStatus.pendingInsert || SyncStatus.pendingUpdate => const Tooltip(
          message: 'Saved locally, pending upload',
          child: Icon(Icons.cloud_upload_outlined,
              size: 18.0, color: AppColors.statusIncreased),
        ),
      SyncStatus.pendingDelete => const Tooltip(
          message: 'Pending delete',
          child: Icon(Icons.delete_sweep_outlined,
              size: 18.0, color: AppColors.neutral400),
        ),
      SyncStatus.syncError => const Tooltip(
          message: 'Upload failed. Will retry automatically on next sync.',
          child: Icon(Icons.cloud_off, size: 18.0, color: AppColors.statusUrgent),
        ),
    };
  }

  void _confirmDelete(BuildContext context, String id, String profileId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Measurement?'),
        content: const Text(
          'This will remove the measurement from your personal history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.statusUrgent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(measurementControllerProvider.notifier)
                  .deleteMeasurement(id, profileId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
