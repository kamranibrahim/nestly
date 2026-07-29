import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'emergency_screen.dart';
import 'expenses_screen.dart';
import 'shopping_screen.dart';
import 'vault_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nest = ref.watch(nestInfoProvider).valueOrNull;
    final members = ref.watch(membersProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            tooltip: 'Sync',
            onPressed: () async {
              try {
                await ref.read(syncServiceProvider).syncAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Synced with nest')),
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
            icon: const Icon(Icons.cloud_sync_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          NestCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                if (members.isEmpty)
                  ...MockData.members.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: MemberAvatar(
                        initials: m.initials,
                        color: m.color,
                        size: 40,
                      ),
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
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      nest?.name ?? MockData.familyName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      members.isEmpty
                          ? '${MockData.members.length} members'
                          : '${members.length} members',
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
          if (nest != null) ...[
            const SizedBox(height: 12),
            NestCard(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: nest.inviteCode));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invite code ${nest.inviteCode} copied'),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.vpn_key_rounded, color: AppColors.primary),
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
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              FeatureTile(
                title: 'Lists',
                icon: Icons.shopping_bag_rounded,
                color: AppColors.tileOrange,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ShoppingScreen()),
                ),
              ),
              FeatureTile(
                title: 'Expenses',
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.tileYellow,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                ),
              ),
              FeatureTile(
                title: 'Vault',
                icon: Icons.folder_rounded,
                color: AppColors.tilePurple,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VaultScreen()),
                ),
              ),
              FeatureTile(
                title: 'Emergency',
                icon: Icons.health_and_safety_rounded,
                color: AppColors.tileRed,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EmergencyScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionLabel('Family wall'),
          NestCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < MockData.timeline.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        MemberAvatar(
                          initials: MockData.memberById(
                            MockData.timeline[i].memberId,
                          ).initials,
                          color: MockData.memberById(
                            MockData.timeline[i].memberId,
                          ).color,
                          size: 34,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                MockData.timeline[i].text,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                MockData.timeline[i].time,
                                style: const TextStyle(
                                  color: AppColors.inkMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != MockData.timeline.length - 1)
                    const Divider(height: 1, indent: 58),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
