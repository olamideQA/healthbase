import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_spacing.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  text,
}

/// Standard accessible button adhering to WCAG 2.5.5 minimum 48dp target sizing.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    super.key,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    final Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const SizedBox(
            width: 18.0,
            height: 18.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: 18.0),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.0),
        ),
      ],
    );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary500,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.neutral300,
            disabledForegroundColor: AppColors.neutral500,
            elevation: 0.0,
            minimumSize: const Size(88.0, AppSpacing.minTouchTarget),
            shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          ),
          child: buttonContent,
        ),
      AppButtonVariant.secondary => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neutral100,
            foregroundColor: AppColors.neutral800,
            disabledBackgroundColor: AppColors.neutral100,
            disabledForegroundColor: AppColors.neutral400,
            elevation: 0.0,
            minimumSize: const Size(88.0, AppSpacing.minTouchTarget),
            shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          ),
          child: buttonContent,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary500,
            disabledForegroundColor: AppColors.neutral400,
            side: const BorderSide(color: AppColors.neutral300),
            minimumSize: const Size(88.0, AppSpacing.minTouchTarget),
            shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          ),
          child: buttonContent,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary500,
            disabledForegroundColor: AppColors.neutral400,
            minimumSize: const Size(64.0, AppSpacing.minTouchTarget),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          ),
          child: buttonContent,
        ),
    };

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
