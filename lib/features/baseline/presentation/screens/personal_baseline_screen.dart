import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/safety/safety_boundaries.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/components/app_loading_state.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/baseline_repository.dart';
import '../../domain/models/personal_baseline.dart';
import '../widgets/personal_baseline_metric_card.dart';

final selectedBaselineWindowProvider =
    StateProvider.autoDispose<BaselineWindow>((ref) => BaselineWindow.days30);

class PersonalBaselineScreen extends ConsumerWidget {
  const PersonalBaselineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final selectedWindow = ref.watch(selectedBaselineWindowProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Baseline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View timeline history',
            onPressed: () => context.push(AppRoutes.timeline),
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
          loading: () =>
              const AppLoadingState(message: 'Calculating baseline...'),
          error: (err, _) => Center(child: Text('Error loading profile: $err')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profile not found.'));
            }

            final baselineAsync = ref.watch(
              personalBaselineStreamProvider((
                profileId: profile.id,
                window: selectedWindow,
              )),
            );

            final units = profile.preferredUnits;

            return ListView(
              padding: AppSpacing.paddingAllLg,
              children: [
                // Window selector
                Center(
                  child: SegmentedButton<BaselineWindow>(
                    segments: BaselineWindow.values.map((w) {
                      return ButtonSegment<BaselineWindow>(
                        value: w,
                        label: Text(w.displayName),
                      );
                    }).toList(),
                    selected: {selectedWindow},
                    onSelectionChanged: (newSelection) {
                      ref.read(selectedBaselineWindowProvider.notifier).state =
                          newSelection.first;
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Clinical Safety Isolation Notice
                Container(
                  padding: AppSpacing.paddingAllMd,
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withAlpha(15),
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(
                      color: AppColors.primary500.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.primary500,
                        size: 20.0,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ABOUT YOUR PERSONAL RANGE',
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              SafetyBoundaries.baselineExplanation,
                              style: TextStyle(
                                fontSize: 12.0,
                                height: 1.4,
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
                const SizedBox(height: AppSpacing.lg),

                // Metric baseline cards
                baselineAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Text('Calculation error: $err'),
                  ),
                  data: (summary) {
                    return Column(
                      children: summary.allBaselines.map((baseline) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: PersonalBaselineMetricCard(
                            baseline: baseline,
                            unitSystem: units,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.md),
                // Footer general disclaimer
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
                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
        ),
      ),
    );
  }
}
