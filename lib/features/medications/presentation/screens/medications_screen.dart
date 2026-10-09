import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../../core/theme/components/app_loading_state.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/medication_repository.dart';
import 'medication_detail_screen.dart';

class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Tracker'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addMedication),
        icon: const Icon(Icons.add),
        label: const Text('Add Medication'),
        backgroundColor: AppColors.primary500,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const AppLoadingState(message: 'Loading medication tracker...'),
          error: (err, _) => Center(child: Text('Error loading profile: $err')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profile not found.'));
            }

            final medicationsAsync = ref.watch(allMedicationsStreamProvider(profile.id));

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allMedicationsStreamProvider);
              },
              child: ListView(
                padding: AppSpacing.paddingAllLg,
                children: [
                  // Mandatory Clinical Dosage Boundary Banner
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
                            'HealthBase is a record-keeping tool. It never calculates or recommends dosages. Always follow your prescribing clinician\'s instructions.',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Medications List
                  medicationsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => Center(child: Text('Error: $err')),
                    data: (medications) {
                      if (medications.isEmpty) {
                        return AppCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.medication_outlined,
                                    size: 36.0,
                                    color: AppColors.neutral400,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'No medications tracked yet',
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Log your daily prescriptions to monitor adherence and view dose history.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.neutral500,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                OutlinedButton.icon(
                                  onPressed: () => context.push(AppRoutes.addMedication),
                                  icon: const Icon(Icons.add, size: 16.0),
                                  label: const Text('Add Medication'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: medications.map((med) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: AppCard(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (ctx) => MedicationDetailScreen(medication: med),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10.0),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary500.withAlpha(25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.medication,
                                      color: AppColors.primary600,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          med.name,
                                          style: AppTypography.titleMedium.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          med.dosage,
                                          style: AppTypography.bodySmall.copyWith(
                                            color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          med.frequency.displayName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.neutral500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppColors.neutral400),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 80.0), // FAB padding
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
