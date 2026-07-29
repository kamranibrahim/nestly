import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late List<HouseholdTask> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = List.of(MockData.tasks);
  }

  @override
  Widget build(BuildContext context) {
    final open = _tasks.where((t) => !t.done).toList();
    final done = _tasks.where((t) => t.done).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          NestCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                ...MockData.members.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: MemberAvatar(
                      initials: m.initials,
                      color: m.color,
                      size: 32,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${open.length} open',
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NestCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < open.length; i++) ...[
                  _TaskRow(
                    task: open[i],
                    onToggle: () => _toggle(open[i]),
                  ),
                  if (i != open.length - 1)
                    const Divider(height: 1, indent: 52),
                ],
              ],
            ),
          ),
          if (done.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionLabel('Completed'),
            NestCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < done.length; i++) ...[
                    _TaskRow(
                      task: done[i],
                      onToggle: () => _toggle(done[i]),
                    ),
                    if (i != done.length - 1)
                      const Divider(height: 1, indent: 52),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _toggle(HouseholdTask task) {
    final index = _tasks.indexOf(task);
    setState(() {
      _tasks[index] = HouseholdTask(
        title: task.title,
        assigneeId: task.assigneeId,
        dueLabel: task.dueLabel,
        done: !task.done,
        recurring: task.recurring,
      );
    });
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.onToggle});

  final HouseholdTask task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final member = MockData.memberById(task.assigneeId);
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(
              task.done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: task.done ? AppColors.primary : AppColors.inkMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration:
                          task.done ? TextDecoration.lineThrough : null,
                      color: task.done ? AppColors.inkMuted : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${member.name} · ${task.dueLabel}',
                    style: const TextStyle(
                      color: AppColors.inkMuted,
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
