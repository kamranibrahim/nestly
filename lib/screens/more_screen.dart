import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'about_screen.dart';
import 'care_screen.dart';
import 'emergency_screen.dart';
import 'expenses_screen.dart';
import 'meals_screen.dart';
import 'privacy_screen.dart';
import 'shopping_screen.dart';
import 'vault_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nest = ref.watch(nestInfoProvider).valueOrNull;
    final members = ref.watch(membersProvider).valueOrNull ?? [];
    final timeline = ref.watch(timelineProvider).valueOrNull ?? const [];
    final wall = timeline.take(12).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 72),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Explore',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                ),
              ],
            ),
          ),
          NestCard(
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
          if (nest != null) ...[
            const SizedBox(height: 6),
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
                  Icon(Icons.vpn_key_rounded, color: AppColors.accentDeep),
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
                  Text(
                    'Copy',
                    style: TextStyle(
                      color: AppColors.accentDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            padding: EdgeInsets.zero,
            childAspectRatio: 1.55,
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
                title: 'Meals',
                icon: Icons.restaurant_rounded,
                color: AppColors.tilePink,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MealsScreen()),
                ),
              ),
              FeatureTile(
                title: 'Care',
                icon: Icons.pets_rounded,
                color: AppColors.tileTeal,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CareScreen()),
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
          const SizedBox(height: 16),
          const SectionLabel('Family wall'),
          NestCard(
            padding: EdgeInsets.zero,
            child: wall.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'When someone completes a task or uploads a document, it shows up here.',
                      style: TextStyle(color: AppColors.inkMuted),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < wall.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              MemberAvatar(
                                initials: _initials(wall[i].memberName),
                                color: AppColors.softCardColors[
                                    i % AppColors.softCardColors.length],
                                size: 34,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      wall[i].message,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    Text(
                                      _relative(wall[i].createdAt),
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
                        if (i != wall.length - 1)
                          const Divider(height: 1, indent: 58),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 6),
          NestCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyScreen()),
            ),
            child: const Row(
              children: [
                Icon(Icons.privacy_tip_outlined, color: AppColors.accentDeep),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Privacy',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
              ],
            ),
          ),
          const SizedBox(height: 6),
          NestCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.accentDeep),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'About Nestly',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
              ],
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

  static String _initials(String name) {
    if (name.trim().isEmpty) return 'F';
    return name
        .trim()
        .split(RegExp(r'\s+'))
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();
  }

  static String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(dt);
  }
}
