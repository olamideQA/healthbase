import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../clinical_thresholds.dart';
import '../safety_boundaries.dart';

/// Modal bottom sheet presenting the comprehensive HealthBase Clinical Boundary
/// and Medical Safety policy to the user.
Future<void> showClinicalDisclaimerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (ctx) => const ClinicalDisclaimerSheet(),
  );
}

class ClinicalDisclaimerSheet extends StatelessWidget {
  const ClinicalDisclaimerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                height: 4.0,
                width: 40.0,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: AppSpacing.paddingAllLg,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: AppColors.primary50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_outlined,
                            color: AppColors.primary600,
                            size: 24.0,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clinical & Safety Policy',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Medical Boundaries & Guideline Sources',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.neutral500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Primary Non-Diagnostic Notice
                    Container(
                      padding: AppSpacing.paddingAllMd,
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: AppSpacing.roundedSm,
                        border: Border.all(color: AppColors.neutral300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Non-Diagnostic Statement',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            SafetyBoundaries.generalDisclaimer,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.neutral700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Text(
                      'Authoritative Clinical Guidelines Cited',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'All thresholds, baseline ranges, and automated indicators in HealthBase reference recognized clinical standards rather than proprietary algorithms:',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    ...GuidelineAuthority.values.map((guideline) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Container(
                          padding: AppSpacing.paddingAllMd,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppSpacing.roundedSm,
                            border: Border.all(color: AppColors.neutral200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                guideline.authority,
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary700,
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                '${guideline.documentTitle} (${guideline.year})',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'When to Seek Clinical Care',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: AppSpacing.paddingAllMd,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: AppSpacing.roundedSm,
                        border: Border.all(color: const Color(0xFFDC2626)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Care Indicators',
                            style: AppTypography.labelLarge.copyWith(
                              color: const Color(0xFF991B1B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Call local emergency services (911 / 112 / 999) if experiencing chest pain, difficulty breathing, slurred speech, sudden numbness or severe sudden symptoms. Never postpone urgent emergency medical treatment to track measurements in HealthBase.',
                            style: AppTypography.bodySmall.copyWith(
                              color: const Color(0xFF7F1D1D),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Understood'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
