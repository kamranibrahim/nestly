import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selected = 28;

  @override
  Widget build(BuildContext context) {
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
                  const Expanded(
                    child: Text(
                      'July 2026',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search_rounded),
                    color: AppColors.primary,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                children: [
                  Row(
                    children: const [
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
                  // Simple July 2026 grid starting Wed (1st)
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
                children: [
                  _DayHeader(
                    label: 'Today',
                    date: 'Tuesday 28 July',
                    highlight: true,
                  ),
                  for (final event in MockData.todayEvents)
                    _EventBlock(event: event),
                  _DayHeader(
                    label: 'Tomorrow',
                    date: 'Wednesday 29 July',
                    highlight: true,
                  ),
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
                  ),
                  _DayHeader(
                    label: null,
                    date: 'Saturday 1 August',
                    highlight: false,
                  ),
                  _EventBlock(event: MockData.upcomingEvents[1]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMonthRows() {
    // July 2026 starts on Wednesday → offset 3
    const offset = 3;
    const daysInMonth = 31;
    final cells = <Widget>[];
    for (var i = 0; i < offset; i++) {
      cells.add(const Expanded(child: SizedBox(height: 40)));
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final selected = d == _selected;
      cells.add(
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selected = d),
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
  });

  final String? label;
  final String date;
  final bool highlight;

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
            const Text(
              ' — ',
              style: TextStyle(color: AppColors.inkMuted),
            ),
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
            onPressed: () {},
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
  const _EventBlock({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final member = MockData.memberById(event.memberId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: member.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: member.color, width: 4),
          ),
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
                      event.time,
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
            MemberAvatar(
              initials: member.initials,
              color: member.color,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
