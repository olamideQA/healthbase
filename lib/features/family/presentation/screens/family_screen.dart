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
import '../../data/family_repository.dart';
import '../../domain/models/family_profile.dart';
import '../widgets/join_family_dialog.dart';
import '../widgets/share_profile_dialog.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final myProfileAsync = ref.watch(myProfileProvider);
    final familyProfilesAsync = ref.watch(familyProfilesStreamProvider);
    final activeProfileId = ref.watch(activeProfileIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined),
            tooltip: 'Enter Invite Code',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => const JoinFamilyDialog(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addFamilyMember),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Family Member'),
        backgroundColor: AppColors.primary500,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: myProfileAsync.when(
          loading: () => const AppLoadingState(message: 'Loading family profiles...'),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (myProfile) {
            if (myProfile == null) {
              return const Center(child: Text('Profile not found.'));
            }

            return familyProfilesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (familyMembers) {
                // Ensure the self profile is in the list
                final allProfiles = <FamilyProfile>[
                  FamilyProfile(
                    id: myProfile.id,
                    ownerAccountId: myProfile.ownerAccountId,
                    isSelf: true,
                    displayName: myProfile.displayName ?? 'My Profile',
                    relationshipLabel: 'Self',
                    effectiveRole: AccessRole.manage,
                    isOwner: true,
                    createdAt: myProfile.createdAt,
                    updatedAt: myProfile.updatedAt,
                  ),
                  ...familyMembers.where((p) => p.id != myProfile.id),
                ];

                final activeProfile = allProfiles.firstWhere(
                  (p) => p.id == activeProfileId,
                  orElse: () => allProfiles.first,
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(familyProfilesStreamProvider);
                  },
                  child: ListView(
                    padding: AppSpacing.paddingAllLg,
                    children: [
                      // Active Tracking Context Banner
                      Container(
                        padding: AppSpacing.paddingAllMd,
                        decoration: BoxDecoration(
                          color: AppColors.primary500.withAlpha(25),
                          borderRadius: AppSpacing.roundedSm,
                          border: Border.all(color: AppColors.primary500.withAlpha(80)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.account_circle, color: AppColors.primary600, size: 28),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ACTIVE PROFILE',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.primary600,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  Text(
                                    activeProfile.displayName,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Role: ${activeProfile.isOwner ? 'Owner' : activeProfile.effectiveRole.displayName} · ${activeProfile.relationshipDisplay}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!activeProfile.isSelf)
                              TextButton(
                                onPressed: () {
                                  ref.read(activeProfileIdProvider.notifier).state = null;
                                  ref.invalidate(activeProfileProvider);
                                },
                                child: const Text('Switch to Self'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Non-biological Clinical Disclaimer Notice
                      Container(
                        padding: AppSpacing.paddingAllSm,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: AppColors.neutral500),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                RelationshipCategory.clinicalDisclaimer,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.neutral500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        'ALL FAMILY PROFILES',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.neutral500,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // List of Profiles
                      ...allProfiles.map((member) {
                        final isCurrentlyActive = member.id == activeProfile.id;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: AppCard(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: member.isSelf
                                      ? AppColors.primary500
                                      : (isDark ? AppColors.neutral700 : AppColors.neutral300),
                                  child: Text(
                                    member.displayName.isNotEmpty
                                        ? member.displayName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: member.isSelf ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              member.displayName,
                                              style: AppTypography.titleMedium.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isCurrentlyActive) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary500.withAlpha(30),
                                                borderRadius: AppSpacing.roundedSm,
                                              ),
                                              child: const Text(
                                                'ACTIVE',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${member.relationshipDisplay} · ${member.isOwner ? "Owner" : member.effectiveRole.displayName}',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Switch Button
                                if (!isCurrentlyActive)
                                  OutlinedButton(
                                    onPressed: () {
                                      ref.read(activeProfileIdProvider.notifier).state = member.id;
                                      ref.invalidate(activeProfileProvider);
                                    },
                                    child: const Text('Switch'),
                                  ),
                                // Actions Popup Menu
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onSelected: (action) async {
                                    if (action == 'share') {
                                      await showDialog<void>(
                                        context: context,
                                        builder: (_) => ShareProfileDialog(profile: member),
                                      );
                                    } else if (action == 'delete') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete Family Profile'),
                                          content: Text(
                                            'Are you sure you want to remove ${member.displayName}? This will delete their local profile data.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true && context.mounted) {
                                        await ref.read(familyRepositoryProvider).removeFamilyMember(member.id);
                                        if (member.id == activeProfileId) {
                                          ref.read(activeProfileIdProvider.notifier).state = null;
                                        }
                                        ref.invalidate(familyProfilesStreamProvider);
                                      }
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    if (member.canManage)
                                      const PopupMenuItem(
                                        value: 'share',
                                        child: Row(
                                          children: [
                                            Icon(Icons.share, size: 18),
                                            SizedBox(width: 8),
                                            Text('Share & Invite'),
                                          ],
                                        ),
                                      ),
                                    if (!member.isSelf && member.isOwner)
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete Profile', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 80.0), // FAB space
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
