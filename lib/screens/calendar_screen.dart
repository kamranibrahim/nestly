import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/member_roles.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/sheet_form.dart';

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

  bool _matchesMemberFilter(
    String memberId,
    List<NestMember> members,
  ) {
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
                    icon: Icons.grid_view_rounded,
                    background: AppColors.surfaceMuted,
                    foreground: AppColors.ink,
                    size: 38,
                    onTap: () {},
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
                    'Task Schedule',
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
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
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
                        NestCard(
                          child: Text(
                            _isToday(_selected)
                                ? 'Nothing planned today'
                                : 'Nothing on this day',
                            style: const TextStyle(
                              color: AppColors.inkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                              member: _memberFor(members, dayEvents[i].memberId),
                              color: AppColors.softCardColors[
                                  i % AppColors.softCardColors.length],
                            ),
                            ),
                          ),
                      if (allEvents
                          .where((e) => e.startsAt.isAfter(
                                _selected.add(const Duration(days: 1)),
                              ) && _matchesMemberFilter(e.memberId, members))
                          .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        const SectionLabel('Upcoming'),
                        for (final event in allEvents
                            .where((e) => e.startsAt.isAfter(
                                  _selected.add(const Duration(days: 1)),
                              ) && _matchesMemberFilter(e.memberId, members))
                            .take(4))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _PastelEventCard(
                              event: event,
                              member: _memberFor(members, event.memberId),
                              color: AppColors.surfaceMuted,
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

  Set<int> _eventDays(List<CalendarEvent> events) {
    return events
        .where((e) =>
            e.startsAt.year == _selected.year &&
            e.startsAt.month == _selected.month)
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
        fill = d.isEven ? AppColors.mint : AppColors.accent.withValues(alpha: 0.55);
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
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
              ),
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
    final members = ref.read(membersProvider).valueOrNull ?? const [];
    var selectedMemberId = _pickDefaultMemberId(members);

    final title = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return OwnedControllers(
          count: 1,
          builder: (context, c) {
            void submit() => Navigator.pop(context, c[0].text.trim());
            return StatefulBuilder(
              builder: (context, setModal) {
                return sheetBody(
                  context: context,
                  children: [
                    sheetHandle(),
                    const SizedBox(height: 6),
                    const Text(
                      'New event',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: c[0],
                      autofocus: true,
                      decoration:
                          const InputDecoration(hintText: 'Event title'),
                      onSubmitted: (_) => submit(),
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
                      child: const Text('Add event'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
    if (title != null && title.isNotEmpty) {
      await ref.read(eventRepositoryProvider).addEvent(
            title: title,
            startsAt: _selected.add(const Duration(hours: 9)),
            memberId: selectedMemberId,
          );
      try {
        await ref.read(syncServiceProvider).syncAll();
      } catch (_) {}
    }
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
    this.showDate = false,
    this.bordered = false,
  });

  final CalendarEvent event;
  final NestMember? member;
  final Color color;
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
                onTap: () {},
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
              const Spacer(),
              if (member != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
