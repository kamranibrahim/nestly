import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/family_needs.dart';
import '../data/home_tips.dart';
import '../data/repositories.dart';
import '../data/sync_controller.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../widgets/common.dart';
import '../widgets/invite_family_sheet.dart';
import '../widgets/motion.dart';
import '../widgets/shimmer.dart';
import 'care_screen.dart';
import 'emergency_screen.dart';
import 'expenses_screen.dart';
import 'meals_screen.dart';
import 'school_screen.dart';
import 'tasks_screen.dart';
import 'timeline_screen.dart';
import 'vault_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final eventsAsync = ref.watch(eventsProvider);

    final homeReady =
        membersAsync.hasValue && tasksAsync.hasValue && eventsAsync.hasValue;

    if (!homeReady) {
      return const HomeLoadingSkeleton();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final events = eventsAsync.valueOrNull ?? const [];
    final todayEvents = events.where((e) {
      final d = DateTime(e.startsAt.year, e.startsAt.month, e.startsAt.day);
      return d == today;
    }).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final openTasks = ref.watch(openTaskCountProvider).valueOrNull ?? 0;
    final openShopping = ref.watch(openShoppingCountProvider).valueOrNull ?? 0;
    final vaultCount = ref.watch(vaultCountProvider).valueOrNull ?? 0;
    final careDue = ref.watch(careDueCountProvider).valueOrNull ?? 0;
    final schoolDue = ref.watch(schoolDueCountProvider).valueOrNull ?? 0;
    final grocerySuggestions =
        ref.watch(grocerySuggestionsProvider).valueOrNull ?? const [];
    final meals = ref.watch(mealsProvider).valueOrNull ?? const [];
    final bills = ref.watch(billsProvider).valueOrNull ?? const [];
    final tasks = tasksAsync.valueOrNull ?? const [];
    final openTaskList = tasks.where((t) => !t.done).take(4).toList();
    final careItems = ref.watch(careItemsProvider).valueOrNull ?? const [];
    final endToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final careDueItems = careItems
        .where((c) => !c.nextDueAt.isAfter(endToday))
        .toList();
    final schoolItems =
        ref.watch(schoolActivitiesProvider).valueOrNull ?? const [];
    final schoolDueItems = schoolItems
        .where((s) => !s.nextAt.isAfter(endToday))
        .toList();
    final timeline = ref.watch(timelineProvider).valueOrNull ?? const [];
    final recent = timeline.take(5).toList();

    final weekAhead = today.add(const Duration(days: 7));
    final billsDueSoonList =
        bills
            .where(
              (b) =>
                  !b.paid &&
                  !b.dueAt.isBefore(today) &&
                  !b.dueAt.isAfter(weekAhead),
            )
            .toList()
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    final billsDueSoon = billsDueSoonList.length;
    MealPlan? dinnerMeal;
    for (final m in meals) {
      if (m.weekday == now.weekday && m.mealType.toLowerCase() == 'dinner') {
        dinnerMeal = m;
        break;
      }
    }
    final dinnerToday = dinnerMeal != null;
    final vaultExpiring =
        ref.watch(vaultExpiringSoonProvider).valueOrNull ?? const [];
    final needs = buildFamilyNeeds(
      openTasks: openTasks,
      openShopping: openShopping,
      unpaidBillsDueSoon: billsDueSoon,
      careDue: careDue,
      schoolDue: schoolDue,
      dinnerPlannedToday: dinnerToday,
      eventsToday: todayEvents.length,
      grocerySuggestions: grocerySuggestions.length,
      dinnerTitle: dinnerMeal?.title,
      vaultExpiringSoon: vaultExpiring.length,
    );

    final nestInfo = ref.watch(nestInfoProvider).valueOrNull;
    final nestName = nestInfo?.name ?? 'Your nest';
    final members = membersAsync.valueOrNull ?? const [];
    final greetingName = members.isNotEmpty
        ? members.first.name.split(' ').first
        : nestName;
    final aloneInNest = members.length <= 1;
    final todayLoad = openTasks + todayEvents.length;
    final emptyToday = todayLoad == 0;
    final pressure =
        openTasks + todayEvents.length + careDue + schoolDue + billsDueSoon;
    final paceLabel = pressure >= 5
        ? 'Busy'
        : pressure >= 1
        ? 'Steady'
        : 'Quiet';
    final dinnerSnapshot = dinnerMeal?.title.trim().isNotEmpty == true
        ? _shortLabel(dinnerMeal!.title.trim())
        : 'Plan dinner';
    final inviteCode = nestInfo?.inviteCode.trim() ?? '';
    final showInvite = aloneInNest && inviteCode.isNotEmpty;
    final tipDismissed =
        ref.watch(inviteTipDismissedProvider).valueOrNull ?? true;
    final soloBannerDismissed =
        ref.watch(inviteSoloBannerDismissedProvider).valueOrNull ?? true;
    final alonePastDay = nestAlonePastDay(nestInfo?.createdAt);
    final showInviteTip =
        aloneInNest && showInvite && !tipDismissed && !alonePastDay;
    final showSoloBanner =
        aloneInNest && showInvite && alonePastDay && !soloBannerDismissed;
    final sync = ref.watch(syncControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accentDeep,
          onRefresh: () => _refreshToday(context, ref),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 72),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Hello, $greetingName!',
                              style: Theme.of(context).textTheme.headlineSmall
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
                            icon: sync.isSyncing
                                ? Icons.cloud_sync_rounded
                                : sync.hasError
                                ? Icons.cloud_off_outlined
                                : Icons.cloud_outlined,
                            background: AppColors.surfaceMuted,
                            foreground: sync.hasError
                                ? AppColors.accentDeep
                                : AppColors.ink,
                            size: 38,
                            semanticLabel: sync.isSyncing
                                ? 'Syncing'
                                : sync.hasError
                                ? 'Sync failed, retry'
                                : 'Sync now',
                            onTap: () {
                              if (sync.isSyncing) return;
                              ref
                                  .read(syncControllerProvider.notifier)
                                  .syncNow(context: context);
                            },
                          ),
                          const SizedBox(width: 8),
                          CircleIconButton(
                            icon: Icons.notifications_none_rounded,
                            background: AppColors.surfaceMuted,
                            foreground: AppColors.ink,
                            size: 38,
                            semanticLabel: 'Today reminders',
                            onTap: () => _showTodayReminders(
                              context,
                              ref,
                              careDue: careDue,
                              schoolDue: schoolDue,
                              billsDueSoon: billsDueSoon,
                              openTasks: openTasks,
                            ),
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
                            onTap: () => onOpenTab(3),
                          ),
                        ],
                      ),
                      if (showSoloBanner) ...[
                        const SizedBox(height: 8),
                        NestCard(
                          color: AppColors.tilePink,
                          bordered: false,
                          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.groups_rounded,
                                color: AppColors.ink,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Still flying solo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Invite a partner with $inviteCode so Today stays shared.',
                                      style: const TextStyle(
                                        color: AppColors.inkSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        FilledButton(
                                          onPressed: () =>
                                              showInviteFamilySheet(
                                                context,
                                                inviteCode: inviteCode,
                                                nestName: nestName,
                                              ),
                                          child: const Text('Invite'),
                                        ),
                                        const SizedBox(width: 4),
                                        TextButton(
                                          onPressed: () =>
                                              dismissInviteSoloBanner(ref),
                                          child: const Text('Not now'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Dismiss',
                                onPressed: () => dismissInviteSoloBanner(ref),
                                icon: const Icon(Icons.close_rounded, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (showInviteTip) ...[
                        const SizedBox(height: 8),
                        NestCard(
                          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.favorite_outline_rounded,
                                color: AppColors.accentDeep,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Invite a partner',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Share $inviteCode so someone can join this nest.',
                                      style: const TextStyle(
                                        color: AppColors.inkSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              showInviteFamilySheet(
                                                context,
                                                inviteCode: inviteCode,
                                                nestName: nestName,
                                              ),
                                          child: const Text('Share invite'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              dismissInvitePartnerTip(ref),
                                          child: const Text('Dismiss'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Dismiss',
                                onPressed: () => dismissInvitePartnerTip(ref),
                                icon: const Icon(Icons.close_rounded, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      NestCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (emptyToday) ...[
                              Text(
                                aloneInNest
                                    ? 'Your nest is quiet — start Today'
                                    : 'Nothing on Today yet',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                aloneInNest
                                    ? 'Invite someone, or add your first task or event. No demo data — just your family.'
                                    : 'Add a task or calendar event so the nest has something to gather around.',
                                style: const TextStyle(
                                  color: AppColors.inkSecondary,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                  fontSize: 13.5,
                                ),
                              ),
                              if (showInvite) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () => showInviteFamilySheet(
                                    context,
                                    inviteCode: inviteCode,
                                    nestName: nestName,
                                  ),
                                  icon: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                  ),
                                  label: Text('Invite · $inviteCode'),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () =>
                                          TasksScreen.showTaskSheet(
                                            context,
                                            ref,
                                          ),
                                      icon: const Icon(Icons.add_task_rounded),
                                      label: const Text('Add task'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        ref
                                            .read(pendingAddProvider.notifier)
                                            .state = PendingAdd
                                            .event;
                                        onOpenTab(1);
                                      },
                                      icon: const Icon(Icons.event_rounded),
                                      label: const Text('Add event'),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
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
                                            text: '$todayLoad',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.accentDeep,
                                            ),
                                          ),
                                          const TextSpan(
                                            text: ' things for today',
                                          ),
                                        ],
                                      ),
                                    ),
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
                                    child: Text(
                                      paceLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const _HashChip('#family'),
                                  const _HashChip('#today'),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showTodayReminders(
                                        context,
                                        ref,
                                        careDue: careDue,
                                        schoolDue: schoolDue,
                                        billsDueSoon: billsDueSoon,
                                        openTasks: openTasks,
                                      ),
                                      icon: const Icon(
                                        Icons.notifications_none_rounded,
                                      ),
                                      label: const Text('Reminders'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () => onOpenTab(2),
                                      icon: const Icon(Icons.checklist_rounded),
                                      label: const Text('Open tasks'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (openTaskList.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              for (final task in openTaskList)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Dismissible(
                                    key: ValueKey('home-task-${task.id}'),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.mint,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Done',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    onDismissed: (_) =>
                                        _markTaskDone(context, ref, task),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () =>
                                          _markTaskDone(context, ref, task),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons
                                                .radio_button_unchecked_rounded,
                                            size: 20,
                                            color: AppColors.mintDeep,
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
                                          const Text(
                                            'Done',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ] else if (!emptyToday) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () =>
                                    TasksScreen.showTaskSheet(context, ref),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Add a task'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const SectionLabel('Today snapshot'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TodayMiniStat(
                            label: 'Calendar',
                            value: todayEvents.isEmpty
                                ? 'None today'
                                : '${todayEvents.length} due',
                            icon: Icons.calendar_month_rounded,
                            tone: AppColors.accent,
                            onTap: () => onOpenTab(1),
                          ),
                          _TodayMiniStat(
                            label: 'Bills',
                            value: billsDueSoon == 0
                                ? 'None due'
                                : '$billsDueSoon due',
                            icon: Icons.receipt_long_rounded,
                            tone: AppColors.tileYellow,
                            onTap: () =>
                                nestPush(context, const ExpensesScreen()),
                          ),
                          _TodayMiniStat(
                            label: 'Care',
                            value: careDue == 0 ? 'None due' : '$careDue due',
                            icon: Icons.favorite_rounded,
                            tone: AppColors.mint,
                            onTap: () => nestPush(context, const CareScreen()),
                          ),
                          _TodayMiniStat(
                            label: 'Dinner',
                            value: dinnerSnapshot,
                            icon: Icons.restaurant_rounded,
                            tone: AppColors.tileTeal,
                            onTap: () => nestPush(
                              context,
                              MealsScreen(
                                entry: dinnerSnapshot == 'Plan dinner'
                                    ? MealsEntry.addDinnerToday
                                    : MealsEntry.browse,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (todayEvents.isEmpty) ...[
                        const SizedBox(height: 12),
                        NestCard(
                          onTap: () {
                            ref.read(pendingAddProvider.notifier).state =
                                PendingAdd.event;
                            onOpenTab(1);
                          },
                          child: const Row(
                            children: [
                              Icon(
                                Icons.event_available_rounded,
                                color: AppColors.accentDeep,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No events on the calendar today — tap to add one',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.inkSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.inkMuted,
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const SectionLabel('Today for your nest'),
                      NestCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (var i = 0; i < needs.needs.length; i++) ...[
                              _NeedRow(
                                need: needs.needs[i],
                                detailOverride: _needDetailOverride(
                                  needs.needs[i].kind,
                                  firstOpenTask: openTaskList.isEmpty
                                      ? null
                                      : openTaskList.first,
                                  firstCareDue: careDueItems.isEmpty
                                      ? null
                                      : careDueItems.first,
                                  firstBillDue: billsDueSoonList.isEmpty
                                      ? null
                                      : billsDueSoonList.first,
                                  firstSchoolDue: schoolDueItems.isEmpty
                                      ? null
                                      : schoolDueItems.first,
                                ),
                                onOpen: () => _openNeed(
                                  context,
                                  onOpenTab,
                                  needs.needs[i].kind,
                                ),
                                onAction: () => _runNeedAction(
                                  context,
                                  ref,
                                  onOpenTab,
                                  needs.needs[i].kind,
                                  firstOpenTask: openTaskList.isEmpty
                                      ? null
                                      : openTaskList.first,
                                  firstCareDue: careDueItems.isEmpty
                                      ? null
                                      : careDueItems.first,
                                  firstBillDue: billsDueSoonList.isEmpty
                                      ? null
                                      : billsDueSoonList.first,
                                  firstSchoolDue: schoolDueItems.isEmpty
                                      ? null
                                      : schoolDueItems.first,
                                  dinnerMeal: dinnerMeal,
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
                        Row(
                          children: [
                            const Expanded(
                              child: SectionLabel('On the calendar'),
                            ),
                            TextButton(
                              onPressed: () {
                                final now = DateTime.now();
                                ref.read(calendarFocusProvider.notifier).state =
                                    CalendarFocus(
                                  day: DateTime(now.year, now.month, now.day),
                                );
                                onOpenTab(1);
                              },
                              child: const Text('See all'),
                            ),
                          ],
                        ),
                        for (var i = 0; i < todayEvents.take(3).length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _TodayEventCard(
                              event: todayEvents[i],
                              pastel:
                                  AppColors.softCardColors[i %
                                      AppColors.softCardColors.length],
                              onTap: () {
                                final e = todayEvents[i];
                                ref.read(calendarFocusProvider.notifier).state =
                                    CalendarFocus(
                                  day: DateTime(
                                    e.startsAt.year,
                                    e.startsAt.month,
                                    e.startsAt.day,
                                  ),
                                  eventId: e.id,
                                );
                                onOpenTab(1);
                              },
                            ),
                          ),
                      ],
                      const SizedBox(height: 2),
                      _FeatureGrid(
                        tiles: [
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
                            onTap: () => onOpenTab(3),
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
                            onTap: () =>
                                nestPush(context, const ExpensesScreen()),
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
                            onTap: () =>
                                nestPush(context, const EmergencyScreen()),
                          ),
                          FeatureTile(
                            title: 'Meals',
                            subtitle: dinnerToday ? 'Dinner set' : 'Plan week',
                            icon: Icons.restaurant_rounded,
                            color: AppColors.tileTeal,
                            onTap: () => nestPush(
                              context,
                              MealsScreen(
                                entry: dinnerToday
                                    ? MealsEntry.browse
                                    : MealsEntry.planWeek,
                              ),
                            ),
                          ),
                          FeatureTile(
                            title: 'Care',
                            subtitle: careDue == 0
                                ? 'Up to date'
                                : '$careDue due',
                            icon: Icons.pets_rounded,
                            color: AppColors.mint,
                            onTap: () => nestPush(context, const CareScreen()),
                          ),
                          FeatureTile(
                            title: 'School',
                            subtitle: schoolDue == 0
                                ? 'Activities'
                                : '$schoolDue due',
                            icon: Icons.school_rounded,
                            color: AppColors.accent,
                            onTap: () =>
                                nestPush(context, const SchoolScreen()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: SectionLabel('Recent activity'),
                          ),
                          TextButton(
                            onPressed: () => nestPush(
                              context,
                              TimelineScreen(onOpenTab: onOpenTab),
                            ),
                            child: const Text('See all'),
                          ),
                        ],
                      ),
                      NestCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        onTap: recent.isEmpty
                            ? () => nestPush(
                                context,
                                TimelineScreen(onOpenTab: onOpenTab),
                              )
                            : null,
                        child: recent.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  'Activity from your nest will show up here. Tap to open Timeline.',
                                  style: TextStyle(color: AppColors.inkMuted),
                                ),
                              )
                            : Column(
                                children: [
                                  for (var i = 0; i < recent.length; i++) ...[
                                    Appear(
                                      delay: AppMotion.stagger * i,
                                      child: _ActivityRow(
                                        event: recent[i],
                                        index: i,
                                        onOpenTab: onOpenTab,
                                      ),
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
      ),
    );
  }

  static String _shortLabel(String value, {int max = 16}) {
    final trimmed = value.trim();
    if (trimmed.length <= max) return trimmed;
    return '${trimmed.substring(0, max - 1)}…';
  }

  Future<void> _refreshToday(BuildContext context, WidgetRef ref) async {
    await syncAfterWrite(ref, context: context);
    try {
      await ref.read(notificationServiceProvider).rescheduleReminders();
    } catch (_) {}
  }

  Future<void> _markTaskDone(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    await ref.read(taskRepositoryProvider).toggleDone(task);
    await syncAfterWrite(ref, context: context);
  }

  Future<void> _showTodayReminders(
    BuildContext context,
    WidgetRef ref, {
    required int careDue,
    required int schoolDue,
    required int billsDueSoon,
    required int openTasks,
  }) async {
    final lines = <String>[
      if (openTasks > 0) '$openTasks open task${openTasks == 1 ? '' : 's'}',
      if (careDue > 0) '$careDue care item${careDue == 1 ? '' : 's'} due',
      if (schoolDue > 0)
        '$schoolDue school / pickup${schoolDue == 1 ? '' : 's'} due',
      if (billsDueSoon > 0)
        '$billsDueSoon bill${billsDueSoon == 1 ? '' : 's'} due soon',
    ];

    try {
      await syncAfterWrite(ref, context: context);
      await ref.read(notificationServiceProvider).rescheduleReminders();
    } catch (_) {}

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
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
              const Text(
                'Today’s reminders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                lines.isEmpty
                    ? 'Nothing urgent right now. Local reminders stay scheduled when items are due.'
                    : lines.map((l) => '• $l').join('\n'),
                style: const TextStyle(
                  color: AppColors.inkSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  nestPush(context, const EmergencyScreen());
                },
                child: const Text('Open emergency card'),
              ),
              const SizedBox(height: 6),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      },
    );
  }

  String? _needDetailOverride(
    FamilyNeedKind kind, {
    Task? firstOpenTask,
    CareItem? firstCareDue,
    Bill? firstBillDue,
    SchoolActivity? firstSchoolDue,
  }) {
    switch (kind) {
      case FamilyNeedKind.tasks:
        return firstOpenTask == null ? null : 'Next: ${firstOpenTask.title}';
      case FamilyNeedKind.care:
        return firstCareDue == null ? null : 'Next: ${firstCareDue.title}';
      case FamilyNeedKind.bills:
        return firstBillDue == null
            ? null
            : 'Next: ${firstBillDue.title} · \$${firstBillDue.amount.toStringAsFixed(0)}';
      case FamilyNeedKind.school:
        return firstSchoolDue == null ? null : 'Next: ${firstSchoolDue.title}';
      default:
        return null;
    }
  }

  Future<void> _runNeedAction(
    BuildContext context,
    WidgetRef ref,
    ValueChanged<int> onOpenTab,
    FamilyNeedKind kind, {
    Task? firstOpenTask,
    CareItem? firstCareDue,
    Bill? firstBillDue,
    SchoolActivity? firstSchoolDue,
    MealPlan? dinnerMeal,
  }) async {
    switch (kind) {
      case FamilyNeedKind.tasks:
        if (firstOpenTask == null) {
          onOpenTab(2);
          return;
        }
        await ref.read(taskRepositoryProvider).toggleDone(firstOpenTask);
        await syncAfterWrite(ref, context: context);
        if (context.mounted) {
          final note = firstOpenTask.recurring
              ? 'Done · next ${TaskRepository.nextDueLabel(firstOpenTask.dueLabel)}'
              : 'Done: ${firstOpenTask.title}';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(note)));
        }
      case FamilyNeedKind.care:
        if (firstCareDue == null) {
          nestPush(context, const CareScreen());
          return;
        }
        await ref.read(careRepositoryProvider).markDone(firstCareDue);
        await syncAfterWrite(ref, context: context);
        try {
          await ref.read(notificationServiceProvider).rescheduleReminders();
        } catch (_) {}
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Done: ${firstCareDue.title}')),
          );
        }
      case FamilyNeedKind.school:
        if (firstSchoolDue == null) {
          nestPush(context, const SchoolScreen());
          return;
        }
        await ref.read(schoolRepositoryProvider).markDone(firstSchoolDue);
        await syncAfterWrite(ref, context: context);
        try {
          await ref.read(notificationServiceProvider).rescheduleReminders();
        } catch (_) {}
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Done: ${firstSchoolDue.title}')),
          );
        }
      case FamilyNeedKind.bills:
        if (firstBillDue == null) {
          nestPush(context, const ExpensesScreen());
          return;
        }
        await ref.read(billRepositoryProvider).togglePaid(firstBillDue);
        await syncAfterWrite(ref, context: context);
        try {
          await ref.read(notificationServiceProvider).rescheduleReminders();
        } catch (_) {}
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Paid: ${firstBillDue.title}')),
          );
        }
      case FamilyNeedKind.meals:
        if (dinnerMeal == null || dinnerMeal.ingredients.trim().isEmpty) {
          nestPush(
            context,
            const MealsScreen(entry: MealsEntry.addDinnerToday),
          );
          return;
        }
        final added = await confirmAddMealIngredients(
          context,
          ref,
          meals: [dinnerMeal],
          label: dinnerMeal.title,
        );
        if (context.mounted && added > 0) onOpenTab(3);
      case FamilyNeedKind.shopping:
        final openCount = ref.read(openShoppingCountProvider).valueOrNull ?? 0;
        if (openCount == 0) {
          final suggestions =
              ref.read(grocerySuggestionsProvider).valueOrNull ?? const [];
          if (suggestions.isNotEmpty) {
            for (final habit in suggestions.take(5)) {
              await ref.read(shoppingRepositoryProvider).addSuggestion(habit);
            }
            await syncAfterWrite(ref, context: context);
            if (context.mounted) {
              final n = suggestions.take(5).length;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added $n restock item${n == 1 ? '' : 's'}'),
                ),
              );
            }
          }
        }
        onOpenTab(3);
      default:
        _openNeed(context, onOpenTab, kind);
    }
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
        onOpenTab(3);
      case FamilyNeedKind.bills:
      case FamilyNeedKind.calendar:
        if (kind == FamilyNeedKind.calendar) {
          onOpenTab(1);
        } else {
          nestPush(context, const ExpensesScreen());
        }
      case FamilyNeedKind.care:
        nestPush(context, const CareScreen());
      case FamilyNeedKind.school:
        nestPush(context, const SchoolScreen());
      case FamilyNeedKind.meals:
        nestPush(context, const MealsScreen(entry: MealsEntry.addDinnerToday));
      case FamilyNeedKind.vault:
        nestPush(context, const VaultScreen());
    }
  }
}

class _TodayMiniStat extends StatelessWidget {
  const _TodayMiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 36) / 2;
    return SizedBox(
      width: width,
      child: NestCard(
        onTap: onTap,
        color: tone.withValues(alpha: 0.5),
        bordered: false,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.ink),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
  const _TodayEventCard({
    required this.event,
    required this.pastel,
    required this.onTap,
  });

  final CalendarEvent event;
  final Color pastel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = event.allDay
        ? 'All day'
        : DateFormat.jm().format(event.startsAt);
    return NestCard(
      onTap: onTap,
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
          const Icon(Icons.north_east_rounded, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final left = tiles[i];
      final right = i + 1 < tiles.length ? tiles[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < tiles.length ? 6 : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: left),
                const SizedBox(width: 6),
                Expanded(child: right ?? const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _NeedRow extends StatelessWidget {
  const _NeedRow({
    required this.need,
    required this.onOpen,
    required this.onAction,
    this.detailOverride,
  });

  final FamilyNeed need;
  final VoidCallback onOpen;
  final VoidCallback onAction;
  final String? detailOverride;

  @override
  Widget build(BuildContext context) {
    final detail = detailOverride ?? need.detail;
    return ListTile(
      onTap: onOpen,
      title: Text(
        need.title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        detail,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.inkMuted,
        ),
      ),
      trailing: SoftPill(
        label: need.actionLabel,
        selected:
            need.kind == FamilyNeedKind.tasks ||
            need.kind == FamilyNeedKind.care,
        onTap: onAction,
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.event,
    required this.index,
    this.onOpenTab,
  });

  final TimelineEvent event;
  final int index;
  final ValueChanged<int>? onOpenTab;

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
    return InkWell(
      onTap: () => nestPush(context, TimelineScreen(onOpenTab: onOpenTab)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            MemberAvatar(
              initials: initials,
              color: AppColors
                  .softCardColors[index % AppColors.softCardColors.length],
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
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.inkMuted,
              size: 20,
            ),
          ],
        ),
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
