import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/member_roles.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'about_screen.dart';
import 'privacy_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  Future<void> _editRole(
    BuildContext context,
    WidgetRef ref,
    NestMember member,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        final current = MemberRoles.normalize(member.role);
        final bottom = MediaQuery.viewPaddingOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Role for ${member.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Used for assignees, school activities, and family context.',
                style: TextStyle(color: AppColors.inkSecondary),
              ),
              const SizedBox(height: 12),
              for (final role in MemberRoles.all)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    role,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: role == current
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, role),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || selected == MemberRoles.normalize(member.role)) {
      return;
    }
    await ref.read(memberRepositoryProvider).updateRole(member.id, selected);
    try {
      await ref.read(syncServiceProvider).syncAll();
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.name} is now $selected')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nest = ref.watch(nestInfoProvider).valueOrNull;
    final members = ref.watch(membersProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 72),
          children: [
            Appear(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Nest',
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                      ),
                    ),
                    CircleIconButton(
                      icon: Icons.cloud_sync_outlined,
                      background: AppColors.surfaceMuted,
                      foreground: AppColors.ink,
                      size: 38,
                      onTap: () async {
                        try {
                          await ref.read(syncServiceProvider).syncAll();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Sync failed: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            Appear(
              delay: const Duration(milliseconds: 40),
              child: NestCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (members.isEmpty)
                      const Expanded(
                        child: Text(
                          'Invite family with your code below',
                          style: TextStyle(color: AppColors.inkMuted),
                        ),
                      )
                    else
                      ...members.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: MemberAvatar(
                            initials: m.initials,
                            color: Color(m.colorValue),
                            size: 40,
                          ),
                        ),
                      ),
                    if (members.isNotEmpty) const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          nest?.name ?? 'Your nest',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          members.isEmpty
                              ? 'No members yet'
                              : '${members.length} member${members.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (members.isNotEmpty) ...[
              const SizedBox(height: 12),
              const SectionLabel('Family roles'),
              Appear(
                delay: const Duration(milliseconds: 55),
                child: NestCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < members.length; i++) ...[
                        ListTile(
                          onTap: () => _editRole(context, ref, members[i]),
                          leading: MemberAvatar(
                            initials: members[i].initials,
                            color: Color(members[i].colorValue),
                            size: 36,
                          ),
                          title: Text(
                            members[i].name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            MemberRoles.normalize(members[i].role),
                            style: const TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12.5,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.inkMuted,
                            size: 20,
                          ),
                        ),
                        if (i != members.length - 1)
                          const Divider(height: 1, indent: 68),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            if (nest != null) ...[
              const SizedBox(height: 6),
              Appear(
                delay: const Duration(milliseconds: 70),
                child: NestCard(
                  onTap: () async {
                    await Clipboard.setData(
                      ClipboardData(text: nest.inviteCode),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Invite code ${nest.inviteCode} copied'),
                        ),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.vpn_key_rounded,
                        color: AppColors.accentDeep,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Invite code',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.inkMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              nest.inviteCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Copy',
                        style: TextStyle(
                          color: AppColors.accentDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const SectionLabel('Settings'),
            Appear(
              delay: const Duration(milliseconds: 100),
              child: NestCard(
                onTap: () => nestPush(context, const PrivacyScreen()),
                child: const Row(
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: AppColors.accentDeep,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Privacy & data',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.inkMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Appear(
              delay: const Duration(milliseconds: 120),
              child: NestCard(
                onTap: () => nestPush(context, const AboutScreen()),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.accentDeep,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'About Nestly',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.inkMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nestly is free for families — no paywall.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
