import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/family_needs.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'care_screen.dart';
import 'emergency_screen.dart';
import 'expenses_screen.dart';
import 'meals_screen.dart';
import 'shopping_screen.dart';
import 'vault_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final events = ref.watch(eventsProvider).valueOrNull ?? const [];
    final todayEvents = events.where((e) {
      final d = DateTime(e.startsAt.year, e.startsAt.month, e.startsAt.day);
      return d == today;
    }).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final openTasks = ref.watch(openTaskCountProvider).valueOrNull ?? 0;
    final openShopping = ref.watch(openShoppingCountProvider).valueOrNull ?? 0;
    final vaultCount = ref.watch(vaultCountProvider).valueOrNull ?? 0;
    final careDue = ref.watch(careDueCountProvider).valueOrNull ?? 0;
    final meals = ref.watch(mealsProvider).valueOrNull ?? const [];
    final bills = ref.watch(billsProvider).valueOrNull ?? const [];
    final tasks = ref.watch(tasksProvider).valueOrNull ?? const [];
    final openTaskList = tasks.where((t) => !t.done).take(4).toList();
    final timeline = ref.watch(timelineProvider).valueOrNull ?? const [];
    final recent = timeline.take(5).toList();

    final weekAhead = today.add(const Duration(days: 7));
    final billsDueSoon = bills
        .where(
          (b) =>
              !b.paid &&
              !b.dueAt.isBefore(today) &&
              !b.dueAt.isAfter(weekAhead),
        )
        .length;
    final dinnerToday = meals.any(
      (m) =>
          m.weekday == now.weekday &&
          m.mealType.toLowerCase() == 'dinner',
    );
    final needs = buildFamilyNeeds(
      openTasks: openTasks,
      openShopping: openShopping,
      unpaidBillsDueSoon: billsDueSoon,
      careDue: careDue,
      dinnerPlannedToday: dinnerToday,
      eventsToday: todayEvents.length,
    );

    final nestName =
        ref.watch(nestInfoProvider).valueOrNull?.name ?? 'Your nest';
    final members = ref.watch(membersProvider).valueOrNull ?? const [];
    final greetingName = members.isNotEmpty
        ? members.first.name.split(' ').first
        : nestName;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 72),
                child: Stagger(
                  step: AppMotion.stagger,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Hello 👋, $greetingName!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                          ),
                        ),
                        if (members.isNotEmpty)
                          MemberAvatar(
                            initials: members.first.initials,
                            color: Color(members.first.colorValue),
                            size: 38,
                          ),
                        const SizedBox(width: 8),
                        CircleIconButton(
                          icon: Icons.notifications_none_rounded,
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SoftPill(
                          label: 'Open ($openTasks)',
                          selected: true,
                          onTap: () => onOpenTab(2),
                        ),
                        const SizedBox(width: 8),
                        SoftPill(
                          label: 'Shopping ($openShopping)',
                          onTap: () => nestPush(context, const ShoppingScreen()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    NestCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                      height: 1.3,
                                    ),
                                    children: [
                                      const TextSpan(text: 'You have '),
                                      TextSpan(
                                        text: '${openTasks + todayEvents.length}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.accentDeep,
                                        ),
                                      ),
                                      const TextSpan(text: ' things for today'),
                                    ],
                                  ),
                                ),
                              ),
                              CircleIconButton(
                                icon: Icons.ios_share_rounded,
                                background: AppColors.mint,
                                foreground: AppColors.ink,
                                size: 34,
                                onTap: () => onOpenTab(2),
                              ),
                              const SizedBox(width: 8),
                              CircleIconButton(
                                icon: Icons.add_rounded,
                                size: 34,
                                onTap: () => onOpenTab(2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'High',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              _HashChip('#family'),
                              _HashChip('#nest'),
                              _HashChip('#today'),
                            ],
                          ),
                          if (openTaskList.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            for (final task in openTaskList)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.mintDeep,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        task.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SectionLabel('Today for your nest'),
                    NestCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < needs.needs.length; i++) ...[
                            _NeedRow(
                              need: needs.needs[i],
                              onTap: () => _openNeed(
                                context,
                                onOpenTab,
                                needs.needs[i].kind,
                              ),
                            ),
                            if (i != needs.needs.length - 1)
                              const Divider(height: 1, indent: 16),
                          ],
                        ],
                      ),
                    ),
                    if (todayEvents.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const SectionLabel('On the calendar'),
                      for (var i = 0; i < todayEvents.take(3).length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _TodayEventCard(
                            event: todayEvents[i],
                            pastel: AppColors.softCardColors[
                                i % AppColors.softCardColors.length],
                          ),
                        ),
                    ],
                    const SizedBox(height: 2),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1.55,
                      children: [
                        FeatureTile(
                          title: 'Calendar',
                          subtitle: todayEvents.isEmpty
                              ? 'Open'
                              : '${todayEvents.length} today',
                          icon: Icons.calendar_month_rounded,
                          color: AppColors.accent,
                          onTap: () => onOpenTab(1),
                        ),
                        FeatureTile(
                          title: 'Lists',
                          subtitle: '$openShopping items',
                          icon: Icons.shopping_bag_rounded,
                          color: AppColors.tileOrange,
                          onTap: () => nestPush(context, const ShoppingScreen()),
                        ),
                        FeatureTile(
                          title: 'Tasks',
                          subtitle: '$openTasks open',
                          icon: Icons.checklist_rounded,
                          color: AppColors.mint,
                          onTap: () => onOpenTab(2),
                        ),
                        FeatureTile(
                          title: 'Expenses',
                          subtitle: 'This month',
                          icon: Icons.account_balance_wallet_rounded,
                          color: AppColors.tileYellow,
                          onTap: () => nestPush(context, const ExpensesScreen()),
                        ),
                        FeatureTile(
                          title: 'Vault',
                          subtitle: '$vaultCount docs',
                          icon: Icons.folder_rounded,
                          color: AppColors.tilePink,
                          onTap: () => nestPush(context, const VaultScreen()),
                        ),
                        FeatureTile(
                          title: 'Emergency',
                          subtitle: 'Always ready',
                          icon: Icons.health_and_safety_rounded,
                          color: AppColors.tileRed,
                          onTap: () => nestPush(context, const EmergencyScreen()),
                        ),
                        FeatureTile(
                          title: 'Meals',
                          subtitle: dinnerToday ? 'Dinner set' : 'Plan week',
                          icon: Icons.restaurant_rounded,
                          color: AppColors.tileTeal,
                          onTap: () => nestPush(context, const MealsScreen()),
                        ),
                        FeatureTile(
                          title: 'Care',
                          subtitle:
                              careDue == 0 ? 'Up to date' : '$careDue due',
                          icon: Icons.pets_rounded,
                          color: AppColors.mint,
                          onTap: () => nestPush(context, const CareScreen()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const SectionLabel('Recent activity'),
                    NestCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: recent.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'Activity from your nest will show up here.',
                                style: TextStyle(color: AppColors.inkMuted),
                              ),
                            )
                          : Column(
                              children: [
                                for (var i = 0; i < recent.length; i++) ...[
                                  Appear(
                                    delay: AppMotion.stagger * i,
                                    child: _ActivityRow(event: recent[i], index: i),
                                  ),
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

  void _openNeed(
    BuildContext context,
    ValueChanged<int> onOpenTab,
    FamilyNeedKind kind,
  ) {
    switch (kind) {
      case FamilyNeedKind.tasks:
        onOpenTab(2);
      case FamilyNeedKind.shopping:
        nestPush(context, const ShoppingScreen());
      case FamilyNeedKind.bills:
      case FamilyNeedKind.calendar:
        if (kind == FamilyNeedKind.calendar) {
          onOpenTab(1);
        } else {
          nestPush(context, const ExpensesScreen());
        }
      case FamilyNeedKind.care:
        nestPush(context, const CareScreen());
      case FamilyNeedKind.meals:
        nestPush(context, const MealsScreen());
    }
  }
}

class _HashChip extends StatelessWidget {
  const _HashChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: AppColors.inkSecondary,
        ),
      ),
    );
  }
}

class _TodayEventCard extends StatelessWidget {
  const _TodayEventCard({required this.event, required this.pastel});

  final CalendarEvent event;
  final Color pastel;

  @override
  Widget build(BuildContext context) {
    final time = event.allDay
        ? 'All day'
        : DateFormat.jm().format(event.startsAt);
    return NestCard(
      color: pastel,
      bordered: false,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('d').format(event.startsAt),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  DateFormat('E').format(event.startsAt),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.inkSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_horiz_rounded, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}

class _NeedRow extends StatelessWidget {
  const _NeedRow({required this.need, required this.onTap});

  final FamilyNeed need;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        need.title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(
        need.detail,
        style: const TextStyle(color: AppColors.inkMuted, fontSize: 12.5),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event, required this.index});

  final TimelineEvent event;
  final int index;

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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          MemberAvatar(
            initials: initials,
            color: AppColors.softCardColors[
                index % AppColors.softCardColors.length],
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
