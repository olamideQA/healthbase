import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_button.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/app_loading_state.dart';
import '../../../daily_check/domain/models/daily_check.dart';
import '../../../measurements/domain/models/measurement.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/domain/models/health_profile.dart';
import '../../domain/models/timeline_entry.dart';
import '../controllers/timeline_controller.dart';
import '../widgets/timeline_entry_detail_sheet.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  final ScrollController _scrollController = ScrollController();
  final _dayFormatter = DateFormat('MMM d, y');
  final _weekdayFormatter = DateFormat('EEEE');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= (maxScroll - 250)) {
      final profile = ref.read(myProfileProvider).value;
      if (profile != null) {
        ref.read(timelineControllerProvider(profile.id).notifier).loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Timeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync now',
            onPressed: () {
              final profile = profileAsync.value;
              if (profile != null) {
                ref
                    .read(timelineControllerProvider(profile.id).notifier)
                    .triggerSync();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Syncing timeline records with cloud...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addMeasurement),
        icon: const Icon(Icons.add),
        label: const Text('Record Vital'),
        backgroundColor: AppColors.primary500,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const AppLoadingState(message: 'Loading timeline...'),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profile not found.'));
            }

            final timelineState =
                ref.watch(timelineControllerProvider(profile.id));
            final controller =
                ref.read(timelineControllerProvider(profile.id).notifier);
            final units = profile.preferredUnits;

            return Column(
              children: [
                // Filter bar
                _buildFilterBar(context, profile.id, timelineState, controller),
                const Divider(height: 1),

                // Content
                Expanded(
                  child: _buildTimelineContent(
                    context,
                    profile.id,
                    timelineState,
                    controller,
                    units,
                    isDark,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    String profileId,
    TimelineState state,
    TimelineController controller,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date range chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: TimelineDateFilter.values.map((df) {
              final isSelected = state.dateFilter == df;
              final labelText = df == TimelineDateFilter.custom &&
                      state.customRange != null
                  ? '${DateFormat('M/d').format(state.customRange!.start)} - ${DateFormat('M/d').format(state.customRange!.end)}'
                  : df.displayName;

              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: FilterChip(
                  label: Text(labelText),
                  selected: isSelected,
                  onSelected: (_) async {
                    if (df == TimelineDateFilter.custom) {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                        initialDateRange: state.customRange ??
                            DateTimeRange(
                              start: DateTime.now()
                                  .subtract(const Duration(days: 14)),
                              end: DateTime.now(),
                            ),
                      );
                      if (picked != null) {
                        await controller.setDateFilter(df, picked);
                      }
                    } else {
                      await controller.setDateFilter(df);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Metric filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: TimelineMetricFilter.values.map((mf) {
              final isSelected = state.metricFilter == mf;
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: FilterChip(
                  label: Text(mf.displayName),
                  selected: isSelected,
                  onSelected: (_) => controller.setMetricFilter(mf),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineContent(
    BuildContext context,
    String profileId,
    TimelineState state,
    TimelineController controller,
    UnitSystem units,
    bool isDark,
  ) {
    if (state.isLoading) {
      return const AppLoadingState(message: 'Loading timeline records...');
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: AppSpacing.paddingAllLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.statusUrgent, size: 40.0),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Failed to load timeline',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.0, color: AppColors.neutral500),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Retry',
                onPressed: () => controller.loadInitial(),
              ),
            ],
          ),
        ),
      );
    }

    if (state.records.isEmpty) {
      final isFiltered = state.dateFilter != TimelineDateFilter.allTime ||
          state.metricFilter != TimelineMetricFilter.all;

      if (isFiltered) {
        return Center(
          child: Padding(
            padding: AppSpacing.paddingAllXl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.filter_alt_off_outlined,
                  size: 48.0,
                  color: AppColors.neutral400,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No records match this filter',
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? AppColors.neutral200 : AppColors.neutral800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Try widening your date range or selecting a different measurement filter.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.0, color: AppColors.neutral500),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Reset Filters',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    controller.setDateFilter(TimelineDateFilter.allTime);
                    controller.setMetricFilter(TimelineMetricFilter.all);
                  },
                ),
              ],
            ),
          ),
        );
      }

      // Empty timeline altogether
      return Center(
        child: Padding(
          padding: AppSpacing.paddingAllXl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timeline_outlined,
                size: 56.0,
                color: AppColors.primary500,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Your Health Timeline is Empty',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.neutral100 : AppColors.neutral900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Record daily vitals or complete your first daily check to build your chronological health timeline.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.0, color: AppColors.neutral500),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppButton(
                    label: 'Daily Check',
                    onPressed: () => context.push(AppRoutes.dailyCheck),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  AppButton(
                    label: 'Record Vital',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.push(AppRoutes.addMeasurement),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.refresh(),
      child: ListView.separated(
        controller: _scrollController,
        padding: AppSpacing.paddingAllMd,
        itemCount: state.records.length + 1, // +1 for pagination footer
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index == state.records.length) {
            return _buildPaginationFooter(state);
          }

          final record = state.records[index];
          return _buildDayRecordCard(context, record, units, isDark);
        },
      ),
    );
  }

  Widget _buildPaginationFooter(TimelineState state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: SizedBox(
            width: 24.0,
            height: 24.0,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
        ),
      );
    }

    if (!state.hasMore && state.records.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: Text(
            'Beginning of timeline records reached',
            style: TextStyle(fontSize: 12.0, color: AppColors.neutral400),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDayRecordCard(
    BuildContext context,
    TimelineDayRecord record,
    UnitSystem units,
    bool isDark,
  ) {
    final now = DateTime.now();
    final isToday = record.date.year == now.year &&
        record.date.month == now.month &&
        record.date.day == now.day;
    final isYesterday = record.date.year == now.year &&
        record.date.month == now.month &&
        record.date.day == (now.day - 1);

    final relativeLabel = isToday
        ? 'Today'
        : isYesterday
            ? 'Yesterday'
            : _weekdayFormatter.format(record.date);

    return AppCard(
      onTap: () {
        TimelineEntryDetailSheet.show(
          context,
          record: record,
          unitSystem: units,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          relativeLabel,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isToday ? AppColors.primary500 : null,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 6.0),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6.0, vertical: 1.0),
                            decoration: BoxDecoration(
                              color: AppColors.primary500.withAlpha(25),
                              borderRadius: AppSpacing.roundedSm,
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _dayFormatter.format(record.date),
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),

              // Sync badge
              _buildSyncBadge(record.syncStatus),
              const SizedBox(width: 4.0),
              const Icon(Icons.chevron_right,
                  size: 20.0, color: AppColors.neutral400),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Daily Check Pills
          if (record.dailyCheck != null) ...[
            Row(
              children: [
                _buildFeelingPill(record.dailyCheck!.feeling),
                const SizedBox(width: 6.0),
                _buildMedicationPill(record.dailyCheck!.medicationStatus),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Vitals Grid (displays whatever vitals were taken)
          _buildVitalsGrid(record, units, isDark),

          // Symptoms chips
          if (record.symptoms.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6.0,
              runSpacing: 4.0,
              children: record.symptoms.map((s) {
                final isUrgent = s.isUrgent;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
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
                            size: 11.0, color: AppColors.statusUrgent),
                        const SizedBox(width: 3.0),
                      ],
                      Text(
                        s.displayName,
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight:
                              isUrgent ? FontWeight.bold : FontWeight.normal,
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
        ],
      ),
    );
  }

  Widget _buildVitalsGrid(
    TimelineDayRecord record,
    UnitSystem units,
    bool isDark,
  ) {
    final vitals = <Widget>[];

    if (record.heartRate != null) {
      vitals.add(_buildVitalItem(
        icon: Icons.favorite,
        color: AppColors.statusUrgent,
        label: 'Heart Rate',
        value: record.heartRate!.formattedPrimaryValue(units),
        unit: record.heartRate!.unitLabel(units),
        isDark: isDark,
      ));
    }

    if (record.bloodPressure != null) {
      vitals.add(_buildVitalItem(
        icon: Icons.speed,
        color: AppColors.primary500,
        label: 'Blood Pressure',
        value: record.bloodPressure!.formattedPrimaryValue(units),
        unit: record.bloodPressure!.unitLabel(units),
        isDark: isDark,
      ));
    }

    if (record.temperature != null) {
      vitals.add(_buildVitalItem(
        icon: Icons.thermostat,
        color: AppColors.statusIncreased,
        label: 'Temperature',
        value: record.temperature!.formattedPrimaryValue(units),
        unit: record.temperature!.unitLabel(units),
        isDark: isDark,
      ));
    }

    if (record.weight != null) {
      vitals.add(_buildVitalItem(
        icon: Icons.monitor_weight,
        color: AppColors.secondary500,
        label: 'Weight',
        value: record.weight!.formattedPrimaryValue(units),
        unit: record.weight!.unitLabel(units),
        isDark: isDark,
      ));
    }

    if (record.glucose != null) {
      vitals.add(_buildVitalItem(
        icon: Icons.water_drop,
        color: AppColors.statusDecreased,
        label: 'Glucose',
        value: record.glucose!.formattedPrimaryValue(units),
        unit: record.glucose!.unitLabel(units),
        isDark: isDark,
      ));
    }

    if (vitals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          'Daily check completed • No vitals recorded',
          style: TextStyle(
            fontSize: 12.0,
            fontStyle: FontStyle.italic,
            color: AppColors.neutral500,
          ),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: vitals,
    );
  }

  Widget _buildVitalItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String unit,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.0, color: color),
        const SizedBox(width: 4.0),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.neutral100 : AppColors.neutral900,
          ),
        ),
        const SizedBox(width: 3.0),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 11.0,
            color: AppColors.neutral500,
          ),
        ),
      ],
    );
  }

  Widget _buildFeelingPill(CheckFeeling feeling) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: AppColors.primary500.withAlpha(20),
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sentiment_satisfied,
              size: 13.0, color: AppColors.primary500),
          const SizedBox(width: 4.0),
          Text(
            feeling.displayName,
            style: const TextStyle(
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
              color: AppColors.primary500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationPill(MedicationCheckStatus medicationStatus) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: AppColors.secondary500.withAlpha(20),
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.medication_outlined,
              size: 13.0, color: AppColors.secondary500),
          const SizedBox(width: 4.0),
          Text(
            medicationStatus.displayName,
            style: const TextStyle(
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncBadge(SyncStatus status) {
    return switch (status) {
      SyncStatus.synced => const Tooltip(
          message: 'Synced',
          child: Icon(Icons.cloud_done, size: 16.0, color: AppColors.statusStable),
        ),
      SyncStatus.pendingInsert ||
      SyncStatus.pendingUpdate ||
      SyncStatus.pendingDelete =>
        const Tooltip(
          message: 'Offline / Pending Sync',
          child: Icon(Icons.cloud_upload_outlined,
              size: 16.0, color: AppColors.statusIncreased),
        ),
      SyncStatus.syncError => const Tooltip(
          message: 'Sync error',
          child: Icon(Icons.cloud_off, size: 16.0, color: AppColors.statusUrgent),
        ),
    };
  }
}
