import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'emergency_screen.dart';
import 'expenses_screen.dart';
import 'shopping_screen.dart';
import 'vault_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateLabel = DateFormat('EEE d MMM').format(now);
    final events = ref.watch(eventsProvider).valueOrNull ?? const [];
    final todayEvents = events.where((e) {
      final d = DateTime(e.startsAt.year, e.startsAt.month, e.startsAt.day);
      return d == today;
    }).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final next = todayEvents.isEmpty
        ? null
        : todayEvents.firstWhere(
            (e) => !e.startsAt.isBefore(now),
            orElse: () => todayEvents.first,
          );
    final openTasks = ref.watch(openTaskCountProvider).valueOrNull ?? 0;
    final openShopping = ref.watch(openShoppingCountProvider).valueOrNull ?? 0;
    final vaultCount = ref.watch(vaultCountProvider).valueOrNull ?? 0;
    final timeline = ref.watch(timelineProvider).valueOrNull ?? const [];
    final recent = timeline.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FamilyHeader(),
                    const SizedBox(height: 14),
                    NestCard(
                      onTap: () => onOpenTab(1),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${now.day}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  next == null
                                      ? 'Nothing planned today'
                                      : '${next.allDay ? 'All day' : DateFormat.jm().format(next.startsAt)} · ${next.title}',
                                  style: const TextStyle(
                                    color: AppColors.inkSecondary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  todayEvents.isEmpty
                                      ? 'Tap to add an event'
                                      : '${todayEvents.length} event${todayEvents.length == 1 ? '' : 's'} today',
                                  style: const TextStyle(
                                    color: AppColors.inkMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.inkMuted,
                          ),
                        ],
                      ),
                    ),
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
                          title: 'Calendar',
                          subtitle: todayEvents.isEmpty
                              ? 'Open'
                              : '${todayEvents.length} today',
                          icon: Icons.calendar_month_rounded,
                          color: AppColors.tileBlue,
                          onTap: () => onOpenTab(1),
                        ),
                        FeatureTile(
                          title: 'Lists',
                          subtitle: '$openShopping items',
                          icon: Icons.shopping_bag_rounded,
                          color: AppColors.tileOrange,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ShoppingScreen(),
                            ),
                          ),
                        ),
                        FeatureTile(
                          title: 'Tasks',
                          subtitle: '$openTasks open',
                          icon: Icons.checklist_rounded,
                          color: AppColors.tileGreen,
                          onTap: () => onOpenTab(2),
                        ),
                        FeatureTile(
                          title: 'Expenses',
                          subtitle: 'This month',
                          icon: Icons.account_balance_wallet_rounded,
                          color: AppColors.tileYellow,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ExpensesScreen(),
                            ),
                          ),
                        ),
                        FeatureTile(
                          title: 'Vault',
                          subtitle: '$vaultCount docs',
                          icon: Icons.folder_rounded,
                          color: AppColors.tilePurple,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const VaultScreen(),
                            ),
                          ),
                        ),
                        FeatureTile(
                          title: 'Emergency',
                          subtitle: 'Always ready',
                          icon: Icons.health_and_safety_rounded,
                          color: AppColors.tileRed,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EmergencyScreen(),
                            ),
                          ),
                        ),
                        FeatureTile(
                          title: 'Timeline',
                          subtitle: 'Family activity',
                          icon: Icons.forum_rounded,
                          color: AppColors.tilePink,
                          onTap: () => onOpenTab(4),
                        ),
                        FeatureTile(
                          title: 'Shopping',
                          subtitle: '$openShopping left',
                          icon: Icons.storefront_rounded,
                          color: AppColors.tileTeal,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ShoppingScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const SectionLabel('Recent activity'),
                    NestCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: recent.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'Activity from your nest will show up here.',
                                style: TextStyle(color: AppColors.inkMuted),
                              ),
                            )
                          : Column(
                              children: [
                                for (var i = 0; i < recent.length; i++) ...[
                                  _ActivityRow(event: recent[i]),
                                  if (i != recent.length - 1)
                                    const Divider(
                                      height: 1,
                                      color: AppColors.divider,
                                    ),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nestName =
        ref.watch(nestInfoProvider).valueOrNull?.name ?? 'Your nest';
    final members = ref.watch(membersProvider).valueOrNull ?? const [];

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nestName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Family organizer',
                style: TextStyle(
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (members.isNotEmpty)
          SizedBox(
            width: 28.0 * (members.length - 1).clamp(0, 8) + 36,
            height: 36,
            child: Stack(
              children: [
                for (var i = 0; i < members.length; i++)
                  Positioned(
                    left: i * 26.0,
                    child: MemberAvatar(
                      initials: members[i].initials,
                      color: Color(members[i].colorValue),
                      size: 36,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(width: 8),
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
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final initials = event.memberName.trim().isEmpty
        ? 'F'
        : event.memberName
            .trim()
            .split(RegExp(r'\s+'))
            .map((p) => p[0])
            .take(2)
            .join()
            .toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          MemberAvatar(
            initials: initials,
            color: AppColors.primary,
            size: 34,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  _relative(event.createdAt),
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(dt);
  }
}
