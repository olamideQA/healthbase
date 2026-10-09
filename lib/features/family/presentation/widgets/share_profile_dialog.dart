import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_button.dart';
import '../../data/family_repository.dart';
import '../../domain/models/family_profile.dart';

class ShareProfileDialog extends ConsumerStatefulWidget {
  const ShareProfileDialog({
    super.key,
    required this.profile,
  });

  final FamilyProfile profile;

  @override
  ConsumerState<ShareProfileDialog> createState() => _ShareProfileDialogState();
}

class _ShareProfileDialogState extends ConsumerState<ShareProfileDialog> {
  AccessRole _selectedRole = AccessRole.view;
  String? _generatedInviteCode;
  bool _isGenerating = false;
  String? _errorMessage;

  Future<void> _generateInvite() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(familyRepositoryProvider);
      final code = await repo.createInvite(
        profileId: widget.profile.id,
        role: _selectedRole,
      );

      if (mounted) {
        setState(() {
          _generatedInviteCode = code;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.share, color: AppColors.primary600, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Share ${widget.profile.displayName}',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explicit Permission Rule: Access is never granted automatically. Generate a secure invite code and share it with your trusted family member or caregiver.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.neutral300 : AppColors.neutral600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_generatedInviteCode == null) ...[
              Text(
                'SELECT PERMISSION LEVEL',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.neutral500,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...AccessRole.values.map((role) {
                final isSelected = _selectedRole == role;
                return InkWell(
                  onTap: () => setState(() => _selectedRole = role),
                  borderRadius: AppSpacing.roundedSm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: isSelected ? AppColors.primary600 : AppColors.neutral400,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role.displayName,
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                role.description,
                                style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ] else ...[
              Container(
                width: double.infinity,
                padding: AppSpacing.paddingAllLg,
                decoration: BoxDecoration(
                  color: AppColors.primary500.withAlpha(20),
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(color: AppColors.primary500),
                ),
                child: Column(
                  children: [
                    const Text('INVITE CODE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.xs),
                    SelectableText(
                      _generatedInviteCode!,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4.0,
                        color: AppColors.primary600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Role: ${_selectedRole.displayName}',
                      style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedInviteCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite code copied to clipboard.')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Code'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'The recipient must open HealthBase, go to Family, and enter this code to gain access. You can revoke access at any time.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_generatedInviteCode != null ? 'Done' : 'Cancel'),
        ),
        if (_generatedInviteCode == null)
          AppButton(
            label: _isGenerating ? 'Generating...' : 'Generate Code',
            isLoading: _isGenerating,
            onPressed: _isGenerating ? null : _generateInvite,
          ),
      ],
    );
  }
}
