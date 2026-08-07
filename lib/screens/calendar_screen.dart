import 'package:flutter/material.dart';
import '../widgets/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/calendar_view_math.dart';
import '../data/db/app_database.dart';
import '../data/enums.dart';
import '../data/member_roles.dart';
import '../providers/providers.dart';
import '../state/calendar_ui.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../widgets/common.dart';
import '../widgets/first_run_empty_card.dart';
import '../widgets/motion.dart';
import '../widgets/sheet_form.dart';
import '../data/sync_controller.dart';
import '../l10n/l10n_ext.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  static String _pickDefaultMemberId(
    List<NestMember> members,
    CalendarMemberFilter memberFilter,
  ) {
    if (members.isEmpty) return '';
    switch (memberFilter) {
      case CalendarMemberFilter.adults:
        for (final m in members) {
          if (MemberRoles.isAdultLike(m.role)) return m.id;
        }
      case CalendarMemberFilter.kids:
        for (final m in members) {
          if (MemberRoles.isKid(m.role)) return m.id;
        }
      case CalendarMemberFilter.grandparents:
        for (final m in members) {
          if (MemberRoles.normalize(m.role) == MemberRoles.grandparent) {
            return m.id;
          }
        }
      case CalendarMemberFilter.all:
        break;
    }
    for (final m in members) {
      if (MemberRoles.isAdultLike(m.role)) return m.id;
    }
    return members.first.id;
  }

  static bool _matchesMemberFilter(
    String memberId,
    List<NestMember> members,
    CalendarMemberFilter memberFilter,
  ) {
    if (memberFilter == CalendarMemberFilter.all) return true;
    final member = members.where((m) => m.id == memberId).toList();
    if (member.isEmpty) return true;
    final role = member.first.role;
    return switch (memberFilter) {
      CalendarMemberFilter.adults => MemberRoles.isAdultLike(role),
      CalendarMemberFilter.kids => MemberRoles.isKid(role),
      CalendarMemberFilter.grandparents =>
        MemberRoles.normalize(role) == MemberRoles.grandparent,
      CalendarMemberFilter.all => true,
    };
  }

  void _consumeFocus(
    BuildContext context,
    WidgetRef ref,
    CalendarUiController controller,
    CalendarFocus focus,
  ) {
    final eventId = controller.consumeFocus(focus);
    if (eventId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final events = ref.read(eventsProvider).valueOrNull ?? const [];
      for (final e in events) {
        if (e.id == eventId) {
          _showEditEvent(context, ref, e);
          return;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final membersAsync = ref.watch(membersProvider);
    final events = eventsAsync.valueOrNull ?? const [];
    final ui = ref.watch(calendarUiProvider);
    final controller = ref.read(calendarUiProvider.notifier);
    final selected = ui.selected;
    final memberFilter = ui.memberFilter;

    ref.listen(pendingAddProvider, (prev, next) {
      if (next == PendingAdd.event) {
        ref.read(pendingAddProvider.notifier).state = PendingAdd.none;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) _showAddEvent(context, ref);
        });
      }
    });

    ref.listen(calendarFocusProvider, (prev, next) {
      if (next == null) return;
      ref.read(calendarFocusProvider.notifier).state = null;
      _consumeFocus(context, ref, controller, next);
    });

    if (controller.beginFocusDrain(ref.read(calendarFocusProvider))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.endFocusDrain();
        if (!context.mounted) return;
        final focus = ref.read(calendarFocusProvider);
        if (focus == null) return;
        ref.read(calendarFocusProvider.notifier).state = null;
        _consumeFocus(context, ref, controller, focus);
      });
    }

    final periodLabel = ui.mode == CalendarBrowseMode.month
        ? DateFormat('MMMM yyyy').format(selected)
        : '${DateFormat('MMM d').format(startOfWeekSunday(selected))} – ${DateFormat('MMM d').format(endOfWeekSaturday(selected))}';

    final membersForFilter = membersAsync.valueOrNull ?? const <NestMember>[];
    final filteredForGrid = events
        .where(
          (e) =>
              _matchesMemberFilter(e.memberId, membersForFilter, memberFilter),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
              child: _CalendarSearchHeader(
                ui: ui,
                controller: controller,
                onAdd: () => _showAddEvent(context, ref),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ui.mode == CalendarBrowseMode.month
                        ? context.l10n.calendarTitleMonth
                        : context.l10n.calendarTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CircleIconButton(
                        icon: Icons.chevron_left_rounded,
                        background: AppColors.surfaceMuted,
                        foreground: AppColors.ink,
                        size: 34,
                        onTap: () => controller.shiftBrowse(-1),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: SoftPill(
                          label: periodLabel,
                          selected: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selected,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              controller.selectDay(picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      CircleIconButton(
                        icon: Icons.chevron_right_rounded,
                        background: AppColors.surfaceMuted,
                        foreground: AppColors.ink,
                        size: 34,
                        onTap: () => controller.shiftBrowse(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in CalendarMemberFilter.pills) ...[
                          SoftPill(
                            label: filter.display(context.l10n),
                            selected: memberFilter == filter,
                            onTap: () => controller.setMemberFilter(filter),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
              child: KeyedSubtree(
                // Keep month circles and week pills from sharing AnimatedContainer
                // state (circle ↔ borderRadius tween asserts).
                key: ValueKey(ui.mode),
                child: ui.mode == CalendarBrowseMode.month
                    ? Column(
                        children: [
                          _dowRow(context.l10n),
                          const SizedBox(height: 6),
                          ..._buildMonthRows(
                            filteredForGrid,
                            selected,
                            controller,
                          ),
                        ],
                      )
                    : _buildWeekStrip(
                        context,
                        filteredForGrid,
                        selected,
                        controller,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: eventsAsync.when(
                loading: () => const NestLoadingSkeleton(itemCount: 3),
                error: (e, _) => Center(child: Text('$e')),
                data: (allEvents) {
                  final members = membersAsync.valueOrNull ?? [];
                  final q = ui.searchQuery.trim().toLowerCase();
                  bool matchesSearch(CalendarEvent e) {
                    if (q.isEmpty) return true;
                    return e.title.toLowerCase().contains(q) ||
                        (e.location ?? '').toLowerCase().contains(q);
                  }

                  final dayEvents = allEvents.where((e) {
                    return isSameCalendarDay(e.startsAt, selected) &&
                        _matchesMemberFilter(
                          e.memberId,
                          members,
                          memberFilter,
                        ) &&
                        matchesSearch(e);
                  }).toList();
                  final upcoming = allEvents
                      .where(
                        (e) =>
                            !e.startsAt.isBefore(endOfDayExclusive(selected)) &&
                            _matchesMemberFilter(
                              e.memberId,
                              members,
                              memberFilter,
                            ) &&
                            matchesSearch(e),
                      )
                      .take(4)
                      .toList();

                  return ListView(
                    padding: nestShellPageInsets(context),
                    children: [
                      if (dayEvents.isEmpty)
                        FirstRunEmptyCard(
                          icon: Icons.event_rounded,
                          color: AppColors.accent,
                          title: allEvents.isEmpty
                              ? context.l10n.emptyCalendarTitle
                              : (q.isNotEmpty
                                    ? context.l10n.emptyCalendarNoMatch
                                    : (_isToday(selected)
                                          ? context.l10n.emptyCalendarNothingToday
                                          : context.l10n.emptyCalendarNothingDay)),
                          body: allEvents.isEmpty
                              ? context.l10n.emptyCalendarBody
                              : (q.isNotEmpty
                                    ? context.l10n.emptyCalendarSearchHint
                                    : context.l10n.emptyCalendarDayHint),
                          actionLabel: q.isNotEmpty
                              ? context.l10n.emptyCalendarClearSearch
                              : context.l10n.addEvent,
                          onAction: () {
                            if (q.isNotEmpty) {
                              controller.closeSearch();
                            } else {
                              _showAddEvent(context, ref);
                            }
                          },
                        )
                      else
                        for (var i = 0; i < dayEvents.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Appear(
                              delay: AppMotion.stagger * i,
                              replayKey: dayEvents[i].id,
                              child: _PastelEventCard(
                                event: dayEvents[i],
                                member: _memberFor(
                                  members,
                                  dayEvents[i].memberId,
                                ),
                                color:
                                    AppColors.softCardColors[i %
                                        AppColors.softCardColors.length],
                                onTap: () =>
                                    _showEditEvent(context, ref, dayEvents[i]),
                                onEdit: () =>
                                    _showEditEvent(context, ref, dayEvents[i]),
                              ),
                            ),
                          ),
                      if (upcoming.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        const SectionLabel('Upcoming'),
                        for (final event in upcoming)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _PastelEventCard(
                              event: event,
                              member: _memberFor(members, event.memberId),
                              color: AppColors.surfaceMuted,
                              onTap: () => _showEditEvent(context, ref, event),
                              onEdit: () => _showEditEvent(context, ref, event),
                              showDate: true,
                              bordered: true,
                            ),
                          ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static NestMember? _memberFor(List<NestMember> members, String id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return members.isEmpty ? null : members.first;
  }

  static bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  static DateTime _dateOnly(DateTime d) => calendarDateOnly(d);

  static String _dateLabel(DateTime d) => DateFormat('EEE, MMM d').format(d);

  static String _timeLabel(DateTime d) => DateFormat.jm().format(d);

  static DateTime _mergeDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static Future<DateTime?> _pickDateFor(
    BuildContext context,
    DateTime initial,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return null;
    return DateTime(
      picked.year,
      picked.month,
      picked.day,
      initial.hour,
      initial.minute,
    );
  }

  static Future<DateTime?> _pickTimeFor(
    BuildContext context,
    DateTime initial,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (picked == null) return null;
    return _mergeDateAndTime(initial, picked);
  }

  static Set<int> _eventDays(List<CalendarEvent> events, DateTime selected) {
    return events
        .where(
          (e) =>
              e.startsAt.year == selected.year &&
              e.startsAt.month == selected.month,
        )
        .map((e) => e.startsAt.day)
        .toSet();
  }

  static Widget _dowRow(AppLocalizations l10n) {
    return Row(
      children: [
        _Dow(l10n.dowSunday),
        _Dow(l10n.dowMonday),
        _Dow(l10n.dowTuesday),
        _Dow(l10n.dowWednesday),
        _Dow(l10n.dowThursday),
        _Dow(l10n.dowFriday),
        _Dow(l10n.dowSaturday),
      ],
    );
  }

  static Widget _buildWeekStrip(
    BuildContext context,
    List<CalendarEvent> events,
    DateTime selected,
    CalendarUiController controller,
  ) {
    final days = weekDaysSunday(selected);
    final eventDayKeys = {for (final e in events) calendarDateOnly(e.startsAt)};

    return Column(
      children: [
        _dowRow(context.l10n),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final day in days)
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.selectDay(day),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.standard,
                    height: 52,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSameCalendarDay(day, selected)
                          ? AppColors.accent
                          : (_isToday(day) ? AppColors.primary : null),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: isSameCalendarDay(day, selected)
                                ? AppColors.ink
                                : (_isToday(day)
                                      ? Colors.white
                                      : AppColors.ink),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: eventDayKeys.contains(day)
                                ? (isSameCalendarDay(day, selected) ||
                                          _isToday(day)
                                      ? AppColors.ink.withValues(alpha: 0.55)
                                      : AppColors.mint)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static List<Widget> _buildMonthRows(
    List<CalendarEvent> events,
    DateTime selected,
    CalendarUiController controller,
  ) {
    final first = DateTime(selected.year, selected.month, 1);
    final daysInMonth = DateTime(selected.year, selected.month + 1, 0).day;
    final offset = first.weekday % 7;
    final eventDays = _eventDays(events, selected);
    final cells = <Widget>[];
    for (var i = 0; i < offset; i++) {
      cells.add(const Expanded(child: SizedBox(height: 38)));
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(selected.year, selected.month, d);
      final isSelected = d == selected.day;
      final today = _isToday(day);
      final hasEvent = eventDays.contains(d);
      Color? fill;
      Color textColor = AppColors.ink;
      if (isSelected) {
        fill = AppColors.accent;
        textColor = AppColors.ink;
      } else if (today) {
        fill = AppColors.primary;
        textColor = Colors.white;
      } else if (hasEvent) {
        fill = d.isEven
            ? AppColors.mint
            : AppColors.accent.withValues(alpha: 0.55);
      }
      cells.add(
        Expanded(
          child: GestureDetector(
            onTap: () => controller.selectDay(day),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              height: 38,
              alignment: Alignment.center,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$d',
                style: TextStyle(
                  fontWeight: isSelected || today || hasEvent
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }
    while (cells.length % 7 != 0) {
      cells.add(const Expanded(child: SizedBox(height: 38)));
    }
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(Row(children: cells.sublist(i, i + 7)));
    }
    return rows;
  }

  static Future<void> _showAddEvent(BuildContext context, WidgetRef ref) async {
    await _showEventSheet(context, ref);
  }

  static Future<void> _showEditEvent(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent event,
  ) async {
    await _showEventSheet(context, ref, existing: event);
  }

  static Future<void> _showEventSheet(
    BuildContext context,
    WidgetRef ref, {
    CalendarEvent? existing,
  }) async {
    final ui = ref.read(calendarUiProvider);
    final selected = ui.selected;
    final members = ref.read(membersProvider).valueOrNull ?? const [];
    var selectedMemberId =
        existing?.memberId ?? _pickDefaultMemberId(members, ui.memberFilter);
    var selectedDate =
        existing?.startsAt ?? selected.add(const Duration(hours: 9));
    var allDay = existing?.allDay ?? false;
    var startAt = existing?.startsAt ?? selected.add(const Duration(hours: 9));
    var endAt = existing?.endsAt ?? selected.add(const Duration(hours: 10));
    var deleteEvent = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return OwnedControllers(
          count: 2,
          builder: (context, c) {
            if (c[0].text.isEmpty && existing != null) {
              c[0].text = existing.title;
            }
            if (c[1].text.isEmpty &&
                (existing?.location?.isNotEmpty ?? false)) {
              c[1].text = existing!.location!;
            }

            Future<void> submit() async {
              final title = c[0].text.trim();
              final location = c[1].text.trim();
              if (title.isEmpty) return;
              Navigator.pop(context);

              if (deleteEvent && existing != null) {
                await ref
                    .read(eventRepositoryProvider)
                    .deleteEvent(existing.id);
              } else if (existing == null) {
                await ref
                    .read(eventRepositoryProvider)
                    .addEvent(
                      title: title,
                      startsAt: allDay ? _dateOnly(selectedDate) : startAt,
                      endsAt: allDay ? null : endAt,
                      allDay: allDay,
                      memberId: selectedMemberId,
                      location: location.isEmpty ? null : location,
                    );
              } else {
                await ref
                    .read(eventRepositoryProvider)
                    .updateEvent(
                      id: existing.id,
                      title: title,
                      startsAt: allDay ? _dateOnly(selectedDate) : startAt,
                      endsAt: allDay ? null : endAt,
                      allDay: allDay,
                      memberId: selectedMemberId,
                      location: location.isEmpty ? null : location,
                      category: existing.category,
                    );
              }

              await syncAfterWrite(ref, context: context);
            }

            return StatefulBuilder(
              builder: (context, setModal) {
                return sheetBody(
                  context: context,
                  children: [
                    sheetHandle(),
                    const SizedBox(height: 6),
                    Text(
                      existing == null
                          ? context.l10n.calendarNewEvent
                          : context.l10n.calendarEditEvent,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: c[0],
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: context.l10n.hintEventTitle,
                      ),
                      onSubmitted: (_) => submit(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: c[1],
                      decoration: InputDecoration(
                        hintText: context.l10n.hintLocationOptional,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.commonAllDay,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Switch(
                          value: allDay,
                          onChanged: (value) => setModal(() => allDay = value),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SoftPill(
                          label: _dateLabel(selectedDate),
                          selected: true,
                          onTap: () async {
                            final picked = await _pickDateFor(
                              context,
                              selectedDate,
                            );
                            if (picked == null) return;
                            setModal(() {
                              selectedDate = picked;
                              startAt = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                startAt.hour,
                                startAt.minute,
                              );
                              endAt = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                endAt.hour,
                                endAt.minute,
                              );
                            });
                          },
                        ),
                        if (!allDay) ...[
                          SoftPill(
                            label: 'Starts ${_timeLabel(startAt)}',
                            onTap: () async {
                              final picked = await _pickTimeFor(
                                context,
                                startAt,
                              );
                              if (picked == null) return;
                              setModal(() {
                                startAt = picked;
                                if (!endAt.isAfter(startAt)) {
                                  endAt = startAt.add(const Duration(hours: 1));
                                }
                              });
                            },
                          ),
                          SoftPill(
                            label: 'Ends ${_timeLabel(endAt)}',
                            onTap: () async {
                              final picked = await _pickTimeFor(context, endAt);
                              if (picked == null) return;
                              setModal(() {
                                endAt = picked.isAfter(startAt)
                                    ? picked
                                    : startAt.add(const Duration(hours: 1));
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                    if (members.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'For',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final m in members)
                            SoftPill(
                              label:
                                  '${m.name.split(' ').first} · ${localizedMemberRole(m.role, context.l10n)}',
                              selected: selectedMemberId == m.id,
                              onTap: () =>
                                  setModal(() => selectedMemberId = m.id),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: submit,
                      child: Text(
                        existing == null
                            ? context.l10n.scanAddEvent
                            : context.l10n.commonSaveChanges,
                      ),
                    ),
                    if (existing != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: Text(context.l10n.deleteEventTitle),
                              content: Text(context.l10n.calendarDeleteBody),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: Text(context.l10n.commonCancel),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: Text(context.l10n.commonDelete),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                          deleteEvent = true;
                          await submit();
                        },
                        child: Text(context.l10n.deleteEventAction),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _Dow extends StatelessWidget {
  const _Dow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PastelEventCard extends StatelessWidget {
  const _PastelEventCard({
    required this.event,
    required this.member,
    required this.color,
    required this.onTap,
    required this.onEdit,
    this.showDate = false,
    this.bordered = false,
  });

  final CalendarEvent event;
  final NestMember? member;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final bool showDate;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final end = event.endsAt;
    final timeLabel = event.allDay
        ? context.l10n.commonAllDay
        : end == null
        ? DateFormat.jm().format(event.startsAt)
        : '${DateFormat.jm().format(event.startsAt)} - ${DateFormat.jm().format(end)}';

    return NestCard(
      onTap: onTap,
      color: color,
      bordered: bordered,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              CircleIconButton(
                icon: Icons.north_east_rounded,
                background: Colors.white,
                foreground: AppColors.ink,
                size: 32,
                onTap: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                showDate
                    ? '${DateFormat.MMMd().format(event.startsAt)} · $timeLabel'
                    : timeLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSecondary,
                  fontSize: 13,
                ),
              ),
              if ((event.location ?? '').trim().isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    event.location!.trim(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (member != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    member!.name.split(' ').first,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarSearchHeader extends StatelessWidget {
  const _CalendarSearchHeader({
    required this.ui,
    required this.controller,
    required this.onAdd,
  });

  final CalendarUiState ui;
  final CalendarUiController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final open = ui.searchOpen;

    return SizedBox(
      height: 38,
      child: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    AnimatedOpacity(
                      duration: AppMotion.fast,
                      curve: AppMotion.standard,
                      opacity: open ? 0 : 1,
                      child: IgnorePointer(
                        ignoring: open,
                        child: Row(
                          children: [
                            const SizedBox(width: 46),
                            const Spacer(),
                            SoftPill(
                              label: 'Month',
                              selected: ui.mode == CalendarBrowseMode.month,
                              onTap: () => controller
                                  .setMode(CalendarBrowseMode.month),
                            ),
                            const SizedBox(width: 6),
                            SoftPill(
                              label: 'Week',
                              selected: ui.mode == CalendarBrowseMode.week,
                              onTap: () =>
                                  controller.setMode(CalendarBrowseMode.week),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: AppMotion.medium,
                      curve: AppMotion.standard,
                      width: open ? constraints.maxWidth : 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(open ? 14 : 19),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AnimatedSwitcher(
                        duration: AppMotion.fast,
                        switchInCurve: AppMotion.standard,
                        switchOutCurve: AppMotion.standard,
                        child: open
                            ? KeyedSubtree(
                                key: const ValueKey('field'),
                                child: OverflowBox(
                                  alignment: AlignmentDirectional.centerStart,
                                  minWidth: 0,
                                  maxWidth: constraints.maxWidth,
                                  child: SizedBox(
                                    width: constraints.maxWidth,
                                    height: 38,
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 10),
                                        const Icon(
                                          Icons.search_rounded,
                                          size: 20,
                                          color: AppColors.ink,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: TextField(
                                            controller:
                                                controller.searchController,
                                            focusNode: controller.searchFocus,
                                            onChanged:
                                                controller.setSearchQuery,
                                            textInputAction:
                                                TextInputAction.search,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.ink,
                                            ),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              hintText: l10n.searchEvents,
                                              hintStyle: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.inkMuted,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.fromLTRB(
                                                8,
                                                8,
                                                0,
                                                8,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 36,
                                          height: 36,
                                          child: IconButton(
                                            tooltip: l10n.commonClose,
                                            onPressed: controller.closeSearch,
                                            style: IconButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(36, 36),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : KeyedSubtree(
                                key: const ValueKey('icon'),
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: controller.openSearch,
                                    child: Semantics(
                                      button: true,
                                      label: l10n.commonSearch,
                                      child: const Center(
                                        child: Icon(
                                          Icons.search_rounded,
                                          size: 18,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          CircleIconButton(
            icon: Icons.add_rounded,
            size: 38,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}
