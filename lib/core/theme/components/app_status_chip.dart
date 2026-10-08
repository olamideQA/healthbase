import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_spacing.dart';

enum HealthTrendStatus {
  stable,
  increased,
  decreased,
  higherThanBaseline,
  lowerThanBaseline,
  insufficientData,
}

enum SyncStatus {
  savedLocally,
  syncing,
  synced,
  syncFailed,
}

/// Status badge for non-judgmental clinical trend and sync indicators.
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    super.key,
    this.icon,
  });

  factory AppStatusChip.trend(HealthTrendStatus status) {
    switch (status) {
      case HealthTrendStatus.stable:
        return const AppStatusChip(
          label: 'Stable',
          backgroundColor: Color(0xFFE8F5E9),
          textColor: Color(0xFF2E7D32),
          icon: Icons.remove,
        );
      case HealthTrendStatus.increased:
        return const AppStatusChip(
          label: 'Increased',
          backgroundColor: Color(0xFFFEF3C7),
          textColor: Color(0xFFB45309),
          icon: Icons.trending_up,
        );
      case HealthTrendStatus.decreased:
        return const AppStatusChip(
          label: 'Decreased',
          backgroundColor: Color(0xFFE0F2FE),
          textColor: Color(0xFF0369A1),
          icon: Icons.trending_down,
        );
      case HealthTrendStatus.higherThanBaseline:
        return const AppStatusChip(
          label: 'Higher than personal baseline',
          backgroundColor: Color(0xFFFEF3C7),
          textColor: Color(0xFFB45309),
          icon: Icons.arrow_upward,
        );
      case HealthTrendStatus.lowerThanBaseline:
        return const AppStatusChip(
          label: 'Lower than personal baseline',
          backgroundColor: Color(0xFFE0F2FE),
          textColor: Color(0xFF0369A1),
          icon: Icons.arrow_downward,
        );
      case HealthTrendStatus.insufficientData:
        return const AppStatusChip(
          label: 'Not enough history yet',
          backgroundColor: AppColors.neutral200,
          textColor: AppColors.neutral600,
          icon: Icons.info_outline,
        );
    }
  }

  factory AppStatusChip.sync(SyncStatus status) {
    switch (status) {
      case SyncStatus.savedLocally:
        return const AppStatusChip(
          label: 'Saved locally',
          backgroundColor: AppColors.neutral200,
          textColor: AppColors.neutral700,
          icon: Icons.cloud_off_outlined,
        );
      case SyncStatus.syncing:
        return const AppStatusChip(
          label: 'Syncing...',
          backgroundColor: Color(0xFFEDE9FE),
          textColor: Color(0xFF6D28D9),
          icon: Icons.sync,
        );
      case SyncStatus.synced:
        return const AppStatusChip(
          label: 'Synced',
          backgroundColor: Color(0xFFE8F5E9),
          textColor: Color(0xFF2E7D32),
          icon: Icons.cloud_done_outlined,
        );
      case SyncStatus.syncFailed:
        return const AppStatusChip(
          label: 'Sync failed (offline)',
          backgroundColor: Color(0xFFFEE2E2),
          textColor: Color(0xFFB91C1C),
          icon: Icons.error_outline,
        );
    }
  }

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14.0, color: textColor),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
