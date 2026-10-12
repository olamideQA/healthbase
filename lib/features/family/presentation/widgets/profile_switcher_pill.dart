import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/domain/models/health_profile.dart';
import '../../data/family_repository.dart';

/// Header pill showing whose records are on screen; tap to switch profile.
class ProfileSwitcherPill extends ConsumerWidget {
  const ProfileSwitcherPill({
    required this.selfProfile,
    required this.currentProfile,
    super.key,
  });

  final HealthProfile selfProfile;
  final HealthProfile currentProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelf = currentProfile.id == selfProfile.id;
    final name = currentProfile.displayName ?? (isSelf ? 'Me' : 'Family member');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final accent = isSelf ? AppColors.primary500 : AppColors.statusSyncing;

    return Semantics(
      button: true,
      label: 'Viewing records for $name. Tap to switch profile.',
      child: Material(
        color: accent.withAlpha(22),
        shape: StadiumBorder(side: BorderSide(color: accent.withAlpha(90))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => showProfileSwitcherSheet(context, selfProfile),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: accent,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    isSelf ? 'Personal Profile' : name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lists self + family profiles; selecting one switches every data screen.
Future<void> showProfileSwitcherSheet(BuildContext context, HealthProfile selfProfile) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return Consumer(
        builder: (ctx, ref, _) {
          final activeId = ref.watch(activeProfileIdProvider) ?? selfProfile.id;
          final familyAsync = ref.watch(familyProfilesStreamProvider);

          void select(String? id) {
            ref.read(activeProfileIdProvider.notifier).state =
                (id == null || id == selfProfile.id) ? null : id;
            ref.invalidate(activeProfileProvider);
            Navigator.of(ctx).pop();
          }

          Widget profileTile({
            required String id,
            required String name,
            required String subtitle,
            required bool isSelf,
          }) {
            final selected = id == activeId;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isSelf ? AppColors.primary100 : AppColors.statusSyncing.withAlpha(30),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelf ? AppColors.primary700 : AppColors.statusSyncing,
                  ),
                ),
              ),
              title: Text(name),
              subtitle: Text(subtitle),
              trailing: selected
                  ? const Icon(Icons.check_circle, color: AppColors.primary500)
                  : null,
              selected: selected,
              onTap: () => select(id),
            );
          }

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text('Whose records?', style: AppTypography.headlineMedium),
                ),
                const SizedBox(height: AppSpacing.sm),
                profileTile(
                  id: selfProfile.id,
                  name: selfProfile.displayName ?? 'My profile',
                  subtitle: 'Me · Account holder',
                  isSelf: true,
                ),
                ...familyAsync.when(
                  loading: () => const [
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  error: (_, _) => const [
                    ListTile(
                      leading: Icon(Icons.cloud_off_outlined),
                      title: Text('Family profiles unavailable offline'),
                    ),
                  ],
                  data: (members) => [
                    for (final m in members.where((m) => m.id != selfProfile.id))
                      profileTile(
                        id: m.id,
                        name: m.displayName,
                        subtitle:
                            '${m.relationshipDisplay} · ${m.isOwner ? 'Owner' : m.effectiveRole.displayName}',
                        isSelf: false,
                      ),
                  ],
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.group_add_outlined),
                  title: const Text('Manage family profiles'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push(AppRoutes.family);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          );
        },
      );
    },
  );
}
