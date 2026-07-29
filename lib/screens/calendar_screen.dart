import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selected;

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

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.home_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_selected),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showAddEvent(context),
                    icon: const Icon(Icons.add_rounded),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
                  ..._buildMonthRows(),
                  const SizedBox(height: 8),
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
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: eventsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (events) {
                  final members = membersAsync.valueOrNull ?? [];
                  final dayEvents = events.where((e) {
                    return e.startsAt.year == _selected.year &&
                        e.startsAt.month == _selected.month &&
                        e.startsAt.day == _selected.day;
                  }).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
                    children: [
                      _DayHeader(
                        label: _isToday(_selected) ? 'Today' : null,
                        date: DateFormat('EEEE d MMMM').format(_selected),
                        highlight: true,
                        onAdd: () => _showAddEvent(context),
                      ),
                      if (dayEvents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: Text(
                              'Nothing planned',
                              style: TextStyle(
                                color: AppColors.inkMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      else
                        for (final event in dayEvents)
                          _EventBlock(
                            event: event,
                            member: _memberFor(members, event.memberId),
                          ),
                      _DayHeader(
                        label: null,
                        date: 'Upcoming',
                        highlight: false,
                        onAdd: () {},
                      ),
                      for (final event in events
                          .where((e) => e.startsAt.isAfter(
                                _selected.add(const Duration(days: 1)),
                              ))
                          .take(5))
                        _EventBlock(
                          event: event,
                          member: _memberFor(members, event.memberId),
                          showDate: true,
                        ),
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

  List<Widget> _buildMonthRows() {
    final first = DateTime(_selected.year, _selected.month, 1);
    final daysInMonth = DateTime(_selected.year, _selected.month + 1, 0).day;
    final offset = first.weekday % 7; // Sunday-start
    final cells = <Widget>[];
    for (var i = 0; i < offset; i++) {
      cells.add(const Expanded(child: SizedBox(height: 40)));
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(_selected.year, _selected.month, d);
      final selected = d == _selected.day;
      cells.add(
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selected = day),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$d',
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      );
    }
    while (cells.length % 7 != 0) {
      cells.add(const Expanded(child: SizedBox(height: 40)));
    }
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(Row(children: cells.sublist(i, i + 7)));
    }
    return rows;
  }

  Future<void> _showAddEvent(BuildContext context) async {
    final controller = TextEditingController();
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'New event',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Event title'),
                onSubmitted: (_) => Navigator.pop(context, true),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Add event'),
              ),
            ],
          ),
        );
      },
    );
    final title = controller.text.trim();
    controller.dispose();
    if (created == true && title.isNotEmpty) {
      await ref.read(eventRepositoryProvider).addEvent(
            title: title,
            startsAt: _selected.add(const Duration(hours: 9)),
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
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.label,
    required this.date,
    required this.highlight,
    required this.onAdd,
  });

  final String? label;
  final String date;
  final bool highlight;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      color: AppColors.background,
      child: Row(
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: TextStyle(
                color: highlight ? AppColors.primary : AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(' — ', style: TextStyle(color: AppColors.inkMuted)),
          ],
          Expanded(
            child: Text(
              date,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: label == null ? AppColors.ink : AppColors.inkSecondary,
              ),
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 20),
            color: AppColors.primary,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _EventBlock extends StatelessWidget {
  const _EventBlock({
    required this.event,
    required this.member,
    this.showDate = false,
  });

  final CalendarEvent event;
  final NestMember? member;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final color = Color(member?.colorValue ?? 0xFF4A78DD);
    final timeLabel = event.allDay
        ? 'All day'
        : DateFormat.jm().format(event.startsAt);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (showDate) DateFormat.MMMd().format(event.startsAt),
                      timeLabel,
                      if (event.location != null) event.location!,
                    ].join(' · '),
                    style: const TextStyle(
                      color: AppColors.inkSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (member != null)
              MemberAvatar(
                initials: member!.initials,
                color: color,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
