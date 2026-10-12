import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/encrypted_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../family/data/family_repository.dart';
import 'controllers/auth_controller.dart';

/// Signs out with an explicit warning when records are still awaiting
/// upload — logging out wipes them from this device.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  int pending = 0;
  try {
    pending = await countPendingLocalChanges(ref.read(appDatabaseProvider));
  } catch (_) {
    pending = 0;
  }
  if (!context.mounted) return;

  Future<void> doSignOut() async {
    ref.read(activeProfileIdProvider.notifier).state = null;
    await ref.read(authControllerProvider.notifier).signOut();
    if (context.mounted) {
      context.go('/auth/login');
    }
  }

  if (pending == 0) {
    await doSignOut();
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Unsynced health records'),
      content: Text(
        'You have $pending record${pending == 1 ? '' : 's'} that have not '
        'been uploaded yet. Signing out now will permanently delete '
        'them from this device. Connect to the internet and sync first '
        'if you want to keep them.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Stay Signed In'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.statusUrgent),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Sign Out Anyway'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await doSignOut();
  }
}

/// Irreversible account deletion behind a confirmation dialog.
Future<void> confirmAccountDeletion(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Account?'),
      content: const Text(
        'This action is irreversible. All your personal data and health records will be permanently removed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.statusUrgent),
          onPressed: () async {
            Navigator.of(ctx).pop();
            final success =
                await ref.read(authControllerProvider.notifier).deleteAccount();
            if (success && context.mounted) {
              context.go('/auth/login');
            }
          },
          child: const Text('Delete Permanently'),
        ),
      ],
    ),
  );
}
