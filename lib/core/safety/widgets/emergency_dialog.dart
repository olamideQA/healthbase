import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../emergency_protocols.dart';

/// Modal dialog providing immediate emergency resources and regional telephone dialers.
Future<void> showEmergencyDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const EmergencyDialog(),
  );
}

class EmergencyDialog extends StatelessWidget {
  const EmergencyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480.0),
        child: Padding(
          padding: AppSpacing.paddingAllLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emergency,
                      color: Colors.white,
                      size: 22.0,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Urgent Medical Advisory',
                          style: AppTypography.titleMedium.copyWith(
                            color: const Color(0xFF991B1B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Emergency Services Directory',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.neutral500,
                          ),
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
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'If you or someone around you is in acute distress (chest pain, shortness of breath, loss of consciousness, sudden numbness), do NOT wait or record data. Connect immediately with emergency first-responders.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.neutral700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Direct Emergency Contacts:',
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...EmergencyRegion.values.map((region) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.neutral50,
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 2.0,
                      ),
                      leading: Text(
                        region.emergencyNumber,
                        style: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      title: Text(
                        region.countryName,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        region.description,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.neutral500,
                        ),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          EmergencyProtocols.launchEmergencyCall(
                            region.emergencyNumber,
                          );
                        },
                        child: const Text('Call'),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: AppSpacing.paddingAllSm,
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  'HealthBase is a self-monitoring record tool and is not an authorized emergency response center or hospital.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.neutral600,
                    fontSize: 11.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
