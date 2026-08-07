import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/family_needs.dart';
import '../data/home_tips.dart';
import '../data/repositories.dart';
import '../data/sync_controller.dart';
import '../l10n/l10n_ext.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/invite_family_sheet.dart';
import '../widgets/motion.dart';
import '../widgets/shimmer.dart';
import 'care_screen.dart';
import 'emergency_screen.dart';
import 'expenses_screen.dart';
import 'locator_screen.dart';
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

    final l10n = context.l10n;
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
    final timelineCount =
        (ref.watch(timelineProvider).valueOrNull ?? const []).length;

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
    final dinnerPlanned = dinnerMeal?.title.trim().isNotEmpty == true;
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
    final nestName = nestInfo?.name ?? l10n.yourNest;
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
        ? l10n.homePaceBusy
        : pressure >= 1
        ? l10n.homePaceSteady
        : l10n.homePaceQuiet;
    final dinnerSnapshot = dinnerPlanned
        ? _shortLabel(dinnerMeal!.title.trim())
        : l10n.homePlanDinner;
    final inviteCode = nestInfo?.inviteCode.trim() ?? '';
    final showInvite = aloneInNest && inviteCode.isNotEmpty;
    final tipDismissedAsync = ref.watch(inviteTipDismissedProvider);
    final soloBannerDismissedAsync =
        ref.watch(inviteSoloBannerDismissedProvider);
    final tipDismissed = tipDismissedAsync.valueOrNull;
    final soloBannerDismissed = soloBannerDismissedAsync.valueOrNull;
    final alonePastDay = nestAlonePastDay(nestInfo?.createdAt);
    final showInviteTip = aloneInNest &&
        showInvite &&
        tipDismissed == false &&
        !alonePastDay;
    final showSoloBanner = aloneInNest &&
        showInvite &&
        alonePastDay &&
        soloBannerDismissed == false;
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
                  padding: nestShellPageInsets(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${l10n.homeHello}, $greetingName!',
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
                                ? l10n.syncing
                                : sync.hasError
                                ? l10n.syncFailedRetry
                                : l10n.syncNow,
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
                            semanticLabel: l10n.homeTodayReminders,
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
                                    Text(
                                      context.l10n.homeStillSolo,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      context.l10n.homeStillSoloBody(inviteCode),
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
                                          child: Text(context.l10n.commonInvite),
                                        ),
                                        const SizedBox(width: 4),
                                        TextButton(
                                          onPressed: () =>
                                              dismissInviteSoloBanner(ref),
                                          child: Text(context.l10n.commonNotNow),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: context.l10n.commonDismiss,
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
                                    Text(
                                      context.l10n.homeInvitePartner,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      context.l10n.homeInvitePartnerBody(inviteCode),
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
                                          child: Text(l10n.homeShareInvite),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              dismissInvitePartnerTip(ref),
                                          child: Text(l10n.commonDismiss),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.commonDismiss,
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
                                    ? context.l10n.homeQuietTitle
                                    : context.l10n.homeNothingToday,
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
                                    ? context.l10n.homeQuietBody
                                    : context.l10n.homeNothingTodayBody,
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
                                  label: Text(l10n.homeInviteChip(inviteCode)),
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
                                      label: Text(l10n.homeAddTask),
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
                                      label: Text(l10n.addEvent),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.homeThingsToday(todayLoad),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                        height: 1.3,
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
                                      label: Text(l10n.homeReminders),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () => onOpenTab(2),
                                      icon: const Icon(Icons.checklist_rounded),
                                      label: Text(l10n.homeOpenTasks),
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
                                      child: Text(
                                        l10n.commonDone,
                                        style: const TextStyle(
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
                                          Text(
                                            l10n.commonDone,
                                            style: const TextStyle(
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
                                label: Text(l10n.homeAddTask),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SectionLabel(l10n.homeTodaySnapshot),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TodayMiniStat(
                            label: l10n.tabCalendar,
                            value: todayEvents.isEmpty
                                ? l10n.homeNoneToday
                                : l10n.homeCountDue(todayEvents.length),
                            icon: Icons.calendar_month_rounded,
                            tone: AppColors.accent,
                            onTap: () => onOpenTab(1),
                          ),
                          _TodayMiniStat(
                            label: l10n.homeBills,
                            value: billsDueSoon == 0
                                ? l10n.homeNoneDue
                                : l10n.homeCountDue(billsDueSoon),
                            icon: Icons.receipt_long_rounded,
                            tone: AppColors.tileYellow,
                            onTap: () =>
                                nestPush(context, const ExpensesScreen()),
                          ),
                          _TodayMiniStat(
                            label: l10n.screenCare,
                            value: careDue == 0
                                ? l10n.homeNoneDue
                                : l10n.homeCountDue(careDue),
                            icon: Icons.favorite_rounded,
                            tone: AppColors.mint,
                            onTap: () => nestPush(context, const CareScreen()),
                          ),
                          _TodayMiniStat(
                            label: l10n.screenMeals,
                            value: dinnerSnapshot,
                            icon: Icons.restaurant_rounded,
                            tone: AppColors.tileTeal,
                            onTap: () => nestPush(
                              context,
                              MealsScreen(
                                entry: !dinnerPlanned
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
                          child: Row(
                            children: [
                              const Icon(
                                Icons.event_available_rounded,
                                color: AppColors.accentDeep,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.homeNoEventsToday,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.inkSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.inkMuted,
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SectionLabel(context.l10n.homeTodayForNest),
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
                            Expanded(
                              child: SectionLabel(context.l10n.homeOnCalendar),
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
                              child: Text(l10n.commonSeeAll),
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
                            title: l10n.tabCalendar,
                            subtitle: todayEvents.isEmpty
                                ? l10n.commonOpen
                                : l10n.homeCountToday(todayEvents.length),
                            icon: Icons.calendar_month_rounded,
                            color: AppColors.accent,
                            onTap: () => onOpenTab(1),
                          ),
                          FeatureTile(
                            title: l10n.homeLists,
                            subtitle: l10n.homeItemsCount(openShopping),
                            icon: Icons.shopping_bag_rounded,
                            color: AppColors.tileOrange,
                            onTap: () => onOpenTab(3),
                          ),
                          FeatureTile(
                            title: l10n.screenTasks,
                            subtitle: l10n.homeOpenCount(openTasks),
                            icon: Icons.checklist_rounded,
                            color: AppColors.mint,
                            onTap: () => onOpenTab(2),
                          ),
                          FeatureTile(
                            title: l10n.screenExpenses,
                            subtitle: l10n.homeThisMonth,
                            icon: Icons.account_balance_wallet_rounded,
                            color: AppColors.tileYellow,
                            onTap: () =>
                                nestPush(context, const ExpensesScreen()),
                          ),
                          FeatureTile(
                            title: l10n.screenVault,
                            subtitle: l10n.homeDocsCount(vaultCount),
                            icon: Icons.folder_rounded,
                            color: AppColors.tilePink,
                            onTap: () => nestPush(context, const VaultScreen()),
                          ),
                          FeatureTile(
                            title: l10n.screenEmergency,
                            subtitle: l10n.homeAlwaysReady,
                            icon: Icons.health_and_safety_rounded,
                            color: AppColors.tileRed,
                            onTap: () =>
                                nestPush(context, const EmergencyScreen()),
                          ),
                          FeatureTile(
                            title: l10n.screenLocator,
                            subtitle: l10n.homeLocatorSubtitle,
                            icon: Icons.location_on_rounded,
                            color: AppColors.tileBlue,
                            onTap: () =>
                                nestPush(context, const LocatorScreen()),
                          ),
                          FeatureTile(
                            title: l10n.screenMeals,
                            subtitle: dinnerToday
                                ? l10n.homeDinnerSet
                                : l10n.homePlanWeek,
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
                            title: l10n.screenCare,
                            subtitle: careDue == 0
                                ? l10n.homeUpToDate
                                : l10n.homeCountDue(careDue),
                            icon: Icons.pets_rounded,
                            color: AppColors.mint,
                            onTap: () => nestPush(context, const CareScreen()),
                          ),
                          FeatureTile(
                            title: l10n.schoolKindSchool,
                            subtitle: schoolDue == 0
                                ? l10n.homeActivities
                                : l10n.homeCountDue(schoolDue),
                            icon: Icons.school_rounded,
                            color: AppColors.accent,
                            onTap: () =>
                                nestPush(context, const SchoolScreen()),
                          ),
                          FeatureTile(
                            title: l10n.screenTimeline,
                            subtitle: timelineCount == 0
                                ? l10n.homeNestActivity
                                : l10n.homeRecentCount(timelineCount),
                            icon: Icons.history_rounded,
                            color: AppColors.tileTeal,
                            onTap: () => nestPush(
                              context,
                              TimelineScreen(onOpenTab: onOpenTab),
                            ),
                          ),
                        ],
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

    // Show the sheet immediately — sync/reschedule used to run first and felt
    // like a multi-second freeze on the Reminders / bell button.
    if (!context.mounted) return;
    final sheet = showModalBottomSheet<void>(
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
              Text(
                context.l10n.homeTodayReminders,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                lines.isEmpty
                    ? context.l10n.homeRemindersEmpty
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
                child: Text(context.l10n.homeOpenEmergency),
              ),
              const SizedBox(height: 6),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.commonGotIt),
              ),
            ],
          ),
        );
      },
    );

    unawaited(() async {
      try {
        await syncAfterWrite(ref, quiet: true);
        await ref.read(notificationServiceProvider).rescheduleReminders();
      } catch (_) {}
    }());

    await sheet;
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
          final l10n = context.l10n;
          final note = firstOpenTask.recurring
              ? 'Done · next ${TaskRepository.nextDueLabel(firstOpenTask.dueLabel)}'
              : l10n.snackDoneTitle(firstOpenTask.title);
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
            SnackBar(
              content: Text(context.l10n.snackDoneTitle(firstCareDue.title)),
            ),
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
            SnackBar(
              content: Text(context.l10n.snackDoneTitle(firstSchoolDue.title)),
            ),
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
            SnackBar(
              content: Text(context.l10n.snackPaidTitle(firstBillDue.title)),
            ),
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
                  content: Text(context.l10n.snackRestockAdded(n)),
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
    final l10n = context.l10n;
    final time = event.allDay
        ? l10n.commonAllDay
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
    final l10n = context.l10n;
    final detail = detailOverride ?? need.detailFor(l10n);
    return ListTile(
      onTap: onOpen,
      title: Text(
        need.titleFor(l10n),
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
        label: need.actionFor(l10n),
        selected:
            need.kind == FamilyNeedKind.tasks ||
            need.kind == FamilyNeedKind.care,
        onTap: onAction,
      ),
    );
  }
}
