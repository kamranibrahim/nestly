import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/mock_data.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            onPressed: () => _showAddTaskSheet(context, ref),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load tasks: $error')),
        data: (tasks) {
          final open = tasks.where((t) => !t.done).toList();
          final done = tasks.where((t) => t.done).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              NestCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
              if (open.isEmpty && done.isEmpty)
                const NestCard(
                  child: Text(
                    'No tasks yet. Tap + to add one.',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                )
              else ...[
                if (open.isNotEmpty)
                  NestCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < open.length; i++) ...[
                          _TaskRow(
                            task: open[i],
                            onToggle: () async {
                              await ref
                                  .read(taskRepositoryProvider)
                                  .toggleDone(open[i]);
                              try {
                                await ref.read(syncServiceProvider).syncAll();
                              } catch (_) {}
                            },
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
                            onToggle: () async {
                              await ref
                                  .read(taskRepositoryProvider)
                                  .toggleDone(done[i]);
                              try {
                                await ref.read(syncServiceProvider).syncAll();
                              } catch (_) {}
                            },
                          ),
                          if (i != done.length - 1)
                            const Divider(height: 1, indent: 52),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddTaskSheet(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    String assigneeId = 'dad';

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'New task',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'What needs doing?',
                    ),
                    onSubmitted: (_) => Navigator.pop(context, true),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final member in MockData.members)
                        ChoiceChip(
                          label: Text(member.name),
                          selected: assigneeId == member.id,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: assigneeId == member.id
                                ? Colors.white
                                : AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) {
                            setModalState(() => assigneeId = member.id);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Add task'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final title = controller.text.trim();
    controller.dispose();
    if (created == true && title.isNotEmpty) {
      await ref.read(taskRepositoryProvider).addTask(
            title: title,
            assigneeId: assigneeId,
          );
      try {
        await ref.read(syncServiceProvider).syncAll();
      } catch (_) {}
    }
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.onToggle});

  final Task task;
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
