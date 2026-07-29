import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final members = ref.watch(membersProvider).valueOrNull ?? const [];

    ref.listen(pendingAddProvider, (prev, next) {
      if (next == PendingAdd.task) {
        ref.read(pendingAddProvider.notifier).state = PendingAdd.none;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) showAddTaskSheet(context, ref);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            onPressed: () => showAddTaskSheet(context, ref),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            const Center(child: Text('Could not load tasks. Pull to retry.')),
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
                    if (members.isEmpty)
                      const Text(
                        'Your nest',
                        style: TextStyle(
                          color: AppColors.inkMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      ...members.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: MemberAvatar(
                            initials: m.initials,
                            color: Color(m.colorValue),
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
                            members: members,
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
                            members: members,
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

  static Future<void> showAddTaskSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final members = ref.read(membersProvider).valueOrNull ?? const [];
    final initialAssignee =
        members.isNotEmpty ? members.first.id : '';

    final result = await showModalBottomSheet<({String title, String assigneeId})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddTaskSheet(
        members: members,
        initialAssigneeId: initialAssignee,
      ),
    );

    if (result != null && result.title.isNotEmpty) {
      await ref.read(taskRepositoryProvider).addTask(
            title: result.title,
            assigneeId: result.assigneeId,
          );
      try {
        await ref.read(syncServiceProvider).syncAll();
      } catch (_) {}
    }
  }
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet({
    required this.members,
    required this.initialAssigneeId,
  });

  final List<NestMember> members;
  final String initialAssigneeId;

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  late final TextEditingController _controller;
  late String _assigneeId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _assigneeId = widget.initialAssigneeId;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context, (title: title, assigneeId: _assigneeId));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      child: SingleChildScrollView(
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
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'What needs doing?',
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (widget.members.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final member in widget.members)
                    ChoiceChip(
                      label: Text(member.name),
                      selected: _assigneeId == member.id,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _assigneeId == member.id
                            ? Colors.white
                            : AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() => _assigneeId = member.id);
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              child: const Text('Add task'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.members,
    required this.onToggle,
  });

  final Task task;
  final List<NestMember> members;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    NestMember? member;
    for (final m in members) {
      if (m.id == task.assigneeId) {
        member = m;
        break;
      }
    }
    final name = member?.name ?? 'Unassigned';
    final initials = member?.initials ?? '?';
    final color = Color(member?.colorValue ?? 0xFF4A78DD);

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
                    '$name · ${task.dueLabel}',
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
              initials: initials,
              color: color,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
