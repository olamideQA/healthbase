import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'components/app_button.dart';
import 'components/app_card.dart';
import 'components/app_empty_state.dart';
import 'components/app_error_state.dart';
import 'components/app_loading_state.dart';
import 'components/app_status_chip.dart';
import 'components/app_text_field.dart';

/// Interactive gallery showcasing all HealthBase design tokens and UI components.
class DesignSystemGalleryScreen extends StatefulWidget {
  const DesignSystemGalleryScreen({super.key});

  @override
  State<DesignSystemGalleryScreen> createState() =>
      _DesignSystemGalleryScreenState();
}

class _DesignSystemGalleryScreenState extends State<DesignSystemGalleryScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthBase Design System'),
      ),
      body: ListView(
        padding: AppSpacing.paddingAllLg,
        children: [
          const Text('Typography Scale', style: AppTypography.headlineLarge),
          const SizedBox(height: AppSpacing.md),
          const Text('Display Large', style: AppTypography.displayLarge),
          const Text('Display Medium', style: AppTypography.displayMedium),
          const Text('Headline Large', style: AppTypography.headlineLarge),
          const Text('Headline Medium', style: AppTypography.headlineMedium),
          const Text('Title Medium', style: AppTypography.titleMedium),
          const Text('Body Large', style: AppTypography.bodyLarge),
          const Text('Body Medium', style: AppTypography.bodyMedium),
          const Text('Label Medium', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.xl),

          const Text('Buttons (48dp Touch Targets)', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                label: 'Primary Button',
                onPressed: () {},
                icon: Icons.check,
              ),
              AppButton(
                label: 'Secondary Button',
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              AppButton(
                label: 'Outline Button',
                variant: AppButtonVariant.outline,
                onPressed: () {},
              ),
              AppButton(
                label: 'Text Button',
                variant: AppButtonVariant.text,
                onPressed: () {},
              ),
              const AppButton(
                label: 'Loading Button',
                isLoading: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          const Text('Form Inputs', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Heart Rate (BPM)',
            hintText: 'e.g. 72',
            controller: _textController,
            prefixIcon: const Icon(Icons.favorite_outline, color: AppColors.primary500),
            keyboardType: TextInputType.number,
            helperText: 'Resting pulse measured in beats per minute.',
          ),
          const SizedBox(height: AppSpacing.md),
          const AppTextField(
            label: 'Blood Pressure Systolic (mmHg)',
            hintText: 'e.g. 120',
            errorText: 'Value must be between 40 and 300 mmHg',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.xl),

          const Text('Clinical Cards', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            title: 'Heart Rate Today',
            subtitle: 'Measured 2 hours ago via manual entry',
            trailing: AppStatusChip.trend(HealthTrendStatus.stable),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: const [
                Text('72', style: AppTypography.metricLarge),
                SizedBox(width: AppSpacing.xs),
                Text('BPM', style: AppTypography.metricUnit),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          const Text('Trend & Sync Status Chips', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppStatusChip.trend(HealthTrendStatus.stable),
              AppStatusChip.trend(HealthTrendStatus.increased),
              AppStatusChip.trend(HealthTrendStatus.decreased),
              AppStatusChip.trend(HealthTrendStatus.higherThanBaseline),
              AppStatusChip.trend(HealthTrendStatus.lowerThanBaseline),
              AppStatusChip.trend(HealthTrendStatus.insufficientData),
              AppStatusChip.sync(SyncStatus.savedLocally),
              AppStatusChip.sync(SyncStatus.syncing),
              AppStatusChip.sync(SyncStatus.synced),
              AppStatusChip.sync(SyncStatus.syncFailed),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          const Text('Loading, Empty & Error States', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          const AppLoadingState(message: 'Loading clinical measurements...'),
          const Divider(height: AppSpacing.xxl),
          AppEmptyState(
            title: 'No Measurements Yet',
            message: 'Begin tracking your vitals to build your personal health history.',
            actionLabel: 'Record First Measurement',
            onAction: () {},
          ),
          const Divider(height: AppSpacing.xxl),
          AppErrorState(
            message: 'Unable to reach the server. Your data remains safely stored locally.',
            onRetry: () {},
          ),
        ],
      ),
    );
  }
}
