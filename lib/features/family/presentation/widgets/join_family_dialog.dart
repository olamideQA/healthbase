import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_button.dart';
import '../../data/family_repository.dart';

class JoinFamilyDialog extends ConsumerStatefulWidget {
  const JoinFamilyDialog({super.key});

  @override
  ConsumerState<JoinFamilyDialog> createState() => _JoinFamilyDialogState();
}

class _JoinFamilyDialogState extends ConsumerState<JoinFamilyDialog> {
  final _codeController = TextEditingController();
  bool _isJoining = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinFamily() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 8) {
      setState(() => _errorMessage = 'Invite code must be exactly 8 characters.');
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(familyRepositoryProvider);
      final res = await repo.acceptInvite(code);

      if (mounted) {
        ref.invalidate(familyProfilesStreamProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully gained access to ${res['display_name'] ?? 'profile'}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.vpn_key_outlined, color: AppColors.primary600, size: 22),
          SizedBox(width: AppSpacing.sm),
          Text('Enter Invite Code'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter the 8-character code shared by your family member to accept and gain access to their health record.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 8,
            decoration: InputDecoration(
              hintText: 'e.g. A1B2C3D4',
              errorText: _errorMessage,
              prefixIcon: const Icon(Icons.key),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: _isJoining ? 'Joining...' : 'Accept Invite',
          isLoading: _isJoining,
          onPressed: _isJoining ? null : _joinFamily,
        ),
      ],
    );
  }
}
