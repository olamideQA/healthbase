import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../emergency_protocols.dart';
import 'emergency_dialog.dart';

/// Clinical urgency alert banner presented prominently when red-flag symptoms
/// or critical vitals readings are detected.
class UrgentCareAlertBanner extends StatelessWidget {
  const UrgentCareAlertBanner({
    super.key,
    required this.alert,
    this.onDismiss,
    this.compact = false,
  });

  final UrgentMedicalAlert alert;
  final VoidCallback? onDismiss;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // Light urgent red
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: const Color(0xFFDC2626), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1ADC2626),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: compact ? AppSpacing.paddingAllMd : AppSpacing.paddingAllLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  color: Colors.white,
                  size: 20.0,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.headline,
                      style: AppTypography.titleSmall.copyWith(
                        color: const Color(0xFF991B1B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      alert.subheading,
                      style: AppTypography.bodySmall.copyWith(
                        color: const Color(0xFFB91C1C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18.0),
                  color: const Color(0xFF991B1B),
                  onPressed: onDismiss,
                  tooltip: 'Dismiss warning',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            alert.guidance,
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFF7F1D1D),
              height: 1.4,
            ),
          ),
          if (alert.guidelineCitation != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Reference: ${alert.guidelineCitation}',
              style: AppTypography.caption.copyWith(
                color: const Color(0xFF991B1B),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.roundedSm,
                  ),
                ),
                icon: const Icon(Icons.phone_in_talk, size: 16.0),
                label: const Text(
                  'Emergency Care Info (911 / 112)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0),
                ),
                onPressed: () => showEmergencyDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
