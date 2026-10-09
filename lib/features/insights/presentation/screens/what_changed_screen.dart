import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/safety/safety_boundaries.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_loading_state.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/insight_repository.dart';
import '../widgets/insight_card.dart';

class WhatChangedScreen extends ConsumerWidget {
  const WhatChangedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('What Changed?'),
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
              const AppLoadingState(message: 'Analyzing longitudinal changes...'),
          error: (err, _) => Center(child: Text('Error loading profile: $err')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profile not found.'));
            }

            final insightsAsync = ref.watch(
              healthInsightsStreamProvider((
                profileId: profile.id,
                unitSystem: profile.preferredUnits,
              )),
            );

            return insightsAsync.when(
              loading: () =>
                  const AppLoadingState(message: 'Comparing against historical baselines...'),
              error: (err, _) => Center(child: Text('Error loading insights: $err')),
              data: (insights) {
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(healthInsightsStreamProvider);
                  },
                  child: ListView(
                    padding: AppSpacing.paddingAllLg,
                    children: [
                      // Introduction and Feature Subtitle
                      Text(
                        'WHAT CHANGED?',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.neutral500,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Comparing recent measurements with your historical baseline.',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.neutral300 : AppColors.neutral600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Clinical Boundaries Disclaimer Banner
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
                              Icons.verified_user_outlined,
                              size: 18,
                              color: AppColors.primary600,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                SafetyBoundaries.baselineExplanation,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Insights List
                      if (insights.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Text('No measurements available yet.'),
                          ),
                        )
                      else
                        ...insights.map((insight) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: InsightCard(insight: insight),
                          );
                        }),
                      const SizedBox(height: 80.0), // Padding for FAB
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
