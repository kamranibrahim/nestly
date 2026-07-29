import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'about_screen.dart';
import 'privacy_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

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
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Synced with nest'),
                              ),
                            );
                          }
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
                        'Privacy',
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
