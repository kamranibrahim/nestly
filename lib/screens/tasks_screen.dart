import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/member_roles.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

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
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tasks',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.add_rounded,
                    size: 38,
                    onTap: () => showAddTaskSheet(context, ref),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasksAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => const Center(
                  child: Text('Could not load tasks. Pull to retry.'),
                ),
                data: (tasks) {
                  final open = tasks.where((t) => !t.done).toList();
                  final done = tasks.where((t) => t.done).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 72),
                    children: [
                      Appear(
                        child: Row(
                        children: [
                          SoftPill(
                            label: 'Open (${open.length})',
                            selected: true,
                          ),
                          const SizedBox(width: 8),
                          SoftPill(label: 'Done (${done.length})'),
                        ],
                      ),
                      ),
                      const SizedBox(height: 6),
                      if (members.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              for (final m in members.take(5))
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: MemberAvatar(
                                    initials: m.initials,
                                    color: Color(m.colorValue),
                                    size: 34,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (open.isEmpty && done.isEmpty)
                        NestCard(
                          color: AppColors.mint,
                          bordered: false,
                          child: const Text(
                            'No tasks yet. Tap + to add one for your nest.',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        )
                      else ...[
                        for (var i = 0; i < open.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Appear(
                              delay: AppMotion.stagger * i.clamp(0, 8),
                              replayKey: open[i].id,
                              child: _PastelTaskCard(
                                task: open[i],
                                members: members,
                                color: AppColors.softCardColors[
                                    i % AppColors.softCardColors.length],
                                onToggle: () async {
                                  await ref
                                      .read(taskRepositoryProvider)
                                      .toggleDone(open[i]);
                                  try {
                                    await ref
                                        .read(syncServiceProvider)
                                        .syncAll();
                                  } catch (_) {}
                                },
                              ),
                            ),
                          ),
                        if (done.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          const SectionLabel('Completed'),
                          for (var i = 0; i < done.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Appear(
                                delay: AppMotion.stagger * i.clamp(0, 6),
                                replayKey: done[i].id,
                                child: _PastelTaskCard(
                                  task: done[i],
                                  members: members,
                                  color: AppColors.surfaceMuted,
                                  bordered: true,
                                  onToggle: () async {
                                    await ref
                                        .read(taskRepositoryProvider)
                                        .toggleDone(done[i]);
                                    try {
                                      await ref
                                          .read(syncServiceProvider)
                                          .syncAll();
                                    } catch (_) {}
                                  },
                                ),
                              ),
                            ),
                        ],
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

  static Future<void> showAddTaskSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final members = List<NestMember>.from(
      ref.read(membersProvider).valueOrNull ?? const [],
    )..sort((a, b) => MemberRoles.adultLikeFirst(a.role, b.role));
    final initialAssignee = members.isNotEmpty ? members.first.id : '';

    final result = await showModalBottomSheet<
        ({String title, String assigneeId, bool recurring})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
            recurring: result.recurring,
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
  bool _recurring = false;

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
    Navigator.pop(
      context,
      (title: title, assigneeId: _assigneeId, recurring: _recurring),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomInset + 12),
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
            const SizedBox(height: 6),
            const Text(
              'New task',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
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
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final member in widget.members)
                    SoftPill(
                      label:
                          '${member.name.split(' ').first} · ${MemberRoles.normalize(member.role)}',
                      selected: _assigneeId == member.id,
                      onTap: () => setState(() => _assigneeId = member.id),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Repeats',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Stays open and rolls the due label when done',
                style: TextStyle(fontSize: 12.5),
              ),
              value: _recurring,
              onChanged: (v) => setState(() => _recurring = v),
            ),
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

class _PastelTaskCard extends StatelessWidget {
  const _PastelTaskCard({
    required this.task,
    required this.members,
    required this.color,
    required this.onToggle,
    this.bordered = false,
  });

  final Task task;
  final List<NestMember> members;
  final Color color;
  final VoidCallback onToggle;
  final bool bordered;

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

    return NestCard(
      onTap: onToggle,
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
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: -0.3,
                    decoration: task.done ? TextDecoration.lineThrough : null,
                    color: task.done ? AppColors.inkMuted : AppColors.ink,
                  ),
                ),
              ),
              CircleIconButton(
                icon: task.done
                    ? Icons.check_rounded
                    : Icons.north_east_rounded,
                background: Colors.white,
                foreground: AppColors.ink,
                size: 32,
                onTap: onToggle,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '$name · ${task.dueLabel}${task.recurring ? ' · repeats' : ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (!task.done)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    task.recurring ? 'Repeats' : 'Open',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
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
