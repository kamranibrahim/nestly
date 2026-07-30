import 'package:flutter/material.dart';
import '../widgets/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/member_roles.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../widgets/common.dart';
import '../widgets/first_run_empty_card.dart';
import '../widgets/motion.dart';
import '../widgets/sheet_form.dart';
import '../data/sync_controller.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selected;
  String _memberFilter = 'All';

  String _pickDefaultMemberId(List<NestMember> members) {
    if (members.isEmpty) return '';
    // Prefer matching the active filter; otherwise fall back to adult-like.
    if (_memberFilter == 'Adults') {
      for (final m in members) {
        if (MemberRoles.isAdultLike(m.role)) return m.id;
      }
    } else if (_memberFilter == 'Kids') {
      for (final m in members) {
        if (MemberRoles.isKid(m.role)) return m.id;
      }
    } else if (_memberFilter == 'Grandparents') {
      for (final m in members) {
        if (MemberRoles.normalize(m.role) == MemberRoles.grandparent) {
          return m.id;
        }
      }
    }
    for (final m in members) {
      if (MemberRoles.isAdultLike(m.role)) return m.id;
    }
    return members.first.id;
  }

  bool _matchesMemberFilter(String memberId, List<NestMember> members) {
    if (_memberFilter == 'All') return true;
    final member = members.where((m) => m.id == memberId).toList();
    if (member.isEmpty) return true;
    final role = member.first.role;
    switch (_memberFilter) {
      case 'Adults':
        return MemberRoles.isAdultLike(role);
      case 'Kids':
        return MemberRoles.isKid(role);
      case 'Grandparents':
        return MemberRoles.normalize(role) == MemberRoles.grandparent;
      default:
        return true;
    }
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final membersAsync = ref.watch(membersProvider);
    final events = eventsAsync.valueOrNull ?? const [];

    ref.listen(pendingAddProvider, (prev, next) {
      if (next == PendingAdd.event) {
        ref.read(pendingAddProvider.notifier).state = PendingAdd.none;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showAddEvent(context);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.today_rounded,
                    background: AppColors.surfaceMuted,
                    foreground: AppColors.ink,
                    size: 38,
                    onTap: () {
                      final now = DateTime.now();
                      setState(() {
                        _selected = DateTime(now.year, now.month, now.day);
                      });
                    },
                  ),
                  const Spacer(),
                  CircleIconButton(
                    icon: Icons.notifications_none_rounded,
                    background: AppColors.surfaceMuted,
                    foreground: AppColors.ink,
                    size: 38,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  CircleIconButton(
                    icon: Icons.add_rounded,
                    size: 38,
                    onTap: () => _showAddEvent(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family calendar',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SoftPill(
                        label: DateFormat('dd.MM.yyyy').format(_selected),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selected,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() {
                              _selected = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                              );
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      CircleIconButton(
                        icon: Icons.edit_rounded,
                        size: 34,
                        onTap: () => _showAddEvent(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in const [
                          'All',
                          'Adults',
                          'Kids',
                          'Grandparents',
                        ]) ...[
                          SoftPill(
                            label: filter,
                            selected: _memberFilter == filter,
                            onTap: () => setState(() => _memberFilter = filter),
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
              child: Column(
                children: [
                  const Row(
                    children: [
                      _Dow('S'),
                      _Dow('M'),
                      _Dow('T'),
                      _Dow('W'),
                      _Dow('T'),
                      _Dow('F'),
                      _Dow('S'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ..._buildMonthRows(events),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: eventsAsync.when(
                loading: () => const NestLoadingSkeleton(itemCount: 3),
                error: (e, _) => Center(child: Text('$e')),
                data: (allEvents) {
                  final members = membersAsync.valueOrNull ?? [];
                  final dayEvents = allEvents.where((e) {
                    return e.startsAt.year == _selected.year &&
                        e.startsAt.month == _selected.month &&
                        e.startsAt.day == _selected.day &&
                        _matchesMemberFilter(e.memberId, members);
                  }).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 72),
                    children: [
                      if (dayEvents.isEmpty)
                        FirstRunEmptyCard(
                          icon: Icons.event_rounded,
                          color: AppColors.accent,
                          title: allEvents.isEmpty
                              ? 'Add your first family event'
                              : (_isToday(_selected)
                                    ? 'Nothing planned today'
                                    : 'Nothing on this day'),
                          body: allEvents.isEmpty
                              ? 'School runs, dinners, and appointments land here — no demo data, just yours.'
                              : 'Tap to schedule something for this day.',
                          actionLabel: 'Add event',
                          onAction: () => _showAddEvent(context),
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
                                    _showEditEvent(context, dayEvents[i]),
                                onEdit: () =>
                                    _showEditEvent(context, dayEvents[i]),
                              ),
                            ),
                          ),
                      if (allEvents
                          .where(
                            (e) =>
                                e.startsAt.isAfter(
                                  _selected.add(const Duration(days: 1)),
                                ) &&
                                _matchesMemberFilter(e.memberId, members),
                          )
                          .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        const SectionLabel('Upcoming'),
                        for (final event
                            in allEvents
                                .where(
                                  (e) =>
                                      e.startsAt.isAfter(
                                        _selected.add(const Duration(days: 1)),
                                      ) &&
                                      _matchesMemberFilter(e.memberId, members),
                                )
                                .take(4))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _PastelEventCard(
                              event: event,
                              member: _memberFor(members, event.memberId),
                              color: AppColors.surfaceMuted,
                              onTap: () => _showEditEvent(context, event),
                              onEdit: () => _showEditEvent(context, event),
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

  NestMember? _memberFor(List<NestMember> members, String id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return members.isEmpty ? null : members.first;
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _dateLabel(DateTime d) => DateFormat('EEE, MMM d').format(d);

  String _timeLabel(DateTime d) => DateFormat.jm().format(d);

  DateTime _mergeDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<DateTime?> _pickDateFor(BuildContext context, DateTime initial) async {
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

  Future<DateTime?> _pickTimeFor(BuildContext context, DateTime initial) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (picked == null) return null;
    return _mergeDateAndTime(initial, picked);
  }

  Set<int> _eventDays(List<CalendarEvent> events) {
    return events
        .where(
          (e) =>
              e.startsAt.year == _selected.year &&
              e.startsAt.month == _selected.month,
        )
        .map((e) => e.startsAt.day)
        .toSet();
  }

  List<Widget> _buildMonthRows(List<CalendarEvent> events) {
    final first = DateTime(_selected.year, _selected.month, 1);
    final daysInMonth = DateTime(_selected.year, _selected.month + 1, 0).day;
    final offset = first.weekday % 7;
    final eventDays = _eventDays(events);
    final cells = <Widget>[];
    for (var i = 0; i < offset; i++) {
      cells.add(const Expanded(child: SizedBox(height: 38)));
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(_selected.year, _selected.month, d);
      final selected = d == _selected.day;
      final today = _isToday(day);
      final hasEvent = eventDays.contains(d);
      Color? fill;
      Color textColor = AppColors.ink;
      if (selected) {
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
            onTap: () => setState(() => _selected = day),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              height: 38,
              alignment: Alignment.center,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
              child: Text(
                '$d',
                style: TextStyle(
                  fontWeight: selected || today || hasEvent
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

  Future<void> _showAddEvent(BuildContext context) async {
    await _showEventSheet(context);
  }

  Future<void> _showEditEvent(BuildContext context, CalendarEvent event) async {
    await _showEventSheet(context, existing: event);
  }

  Future<void> _showEventSheet(
    BuildContext context, {
    CalendarEvent? existing,
  }) async {
    final members = ref.read(membersProvider).valueOrNull ?? const [];
    var selectedMemberId = existing?.memberId ?? _pickDefaultMemberId(members);
    var selectedDate =
        existing?.startsAt ?? _selected.add(const Duration(hours: 9));
    var allDay = existing?.allDay ?? false;
    var startAt = existing?.startsAt ?? _selected.add(const Duration(hours: 9));
    var endAt = existing?.endsAt ?? _selected.add(const Duration(hours: 10));
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
                      existing == null ? 'New event' : 'Edit event',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: c[0],
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Event title',
                      ),
                      onSubmitted: (_) => submit(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: c[1],
                      decoration: const InputDecoration(
                        hintText: 'Location (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'All day',
                            style: TextStyle(fontWeight: FontWeight.w700),
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
                                  '${m.name.split(' ').first} · ${MemberRoles.normalize(m.role)}',
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
                        existing == null ? 'Add event' : 'Save changes',
                      ),
                    ),
                    if (existing != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete event?'),
                              content: const Text(
                                'This removes it from the shared calendar.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                          deleteEvent = true;
                          await submit();
                        },
                        child: const Text('Delete event'),
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
        ? 'All day'
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
