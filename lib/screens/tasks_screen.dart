import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/member_roles.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../widgets/common.dart';
import '../widgets/first_run_empty_card.dart';
import '../widgets/motion.dart';
import '../widgets/shimmer.dart';
import '../data/sync_controller.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();

  /// Kept for FAB / pending-add callers that still reference the old name.
  static Future<void> showAddTaskSheet(BuildContext context, WidgetRef ref) {
    return showTaskSheet(context, ref);
  }

  static Future<void> showTaskSheet(
    BuildContext context,
    WidgetRef ref, {
    Task? existing,
  }) async {
    final members = List<NestMember>.from(
      ref.read(membersProvider).valueOrNull ?? const [],
    )..sort((a, b) => MemberRoles.adultLikeFirst(a.role, b.role));
    final initialAssignee = existing?.assigneeId.isNotEmpty == true
        ? existing!.assigneeId
        : (members.isNotEmpty ? members.first.id : '');

    final result =
        await showModalBottomSheet<
          ({
            String title,
            String assigneeId,
            bool recurring,
            String dueLabel,
            bool deleteTask,
          })
        >(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          builder: (context) => _TaskSheet(
            members: members,
            initialAssigneeId: initialAssignee,
            existing: existing,
          ),
        );

    if (result == null) return;

    if (result.deleteTask && existing != null) {
      await ref.read(taskRepositoryProvider).deleteTask(existing.id);
      await syncAfterWrite(ref, context: context);
      return;
    }

    if (result.title.isEmpty) return;

    if (existing == null) {
      await ref
          .read(taskRepositoryProvider)
          .addTask(
            title: result.title,
            assigneeId: result.assigneeId,
            recurring: result.recurring,
            dueLabel: result.dueLabel,
          );
    } else {
      await ref
          .read(taskRepositoryProvider)
          .updateTask(
            id: existing.id,
            title: result.title,
            assigneeId: result.assigneeId,
            recurring: result.recurring,
            dueLabel: result.dueLabel,
          );
    }
    await syncAfterWrite(ref, context: context);
  }
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  /// `null` = all members; otherwise filter by assignee id.
  String? _assigneeFilterId;

  NestMember? _memberById(List<NestMember> members, String? id) {
    if (id == null) return null;
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final members = ref.watch(membersProvider).valueOrNull ?? const [];

    ref.listen(pendingAddProvider, (prev, next) {
      if (next == PendingAdd.task) {
        ref.read(pendingAddProvider.notifier).state = PendingAdd.none;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) TasksScreen.showTaskSheet(context, ref);
        });
      }
    });

    if (_assigneeFilterId != null &&
        _memberById(members, _assigneeFilterId) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _assigneeFilterId = null);
      });
    }

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
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.add_rounded,
                    size: 38,
                    onTap: () => TasksScreen.showTaskSheet(context, ref),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasksAsync.when(
                loading: () =>
                    const NestLoadingSkeleton(itemCount: 5, hasTitle: true),
                error: (error, _) =>
                    const Center(child: Text('Could not load tasks.')),
                data: (tasks) {
                  final filtered = _assigneeFilterId == null
                      ? tasks
                      : tasks
                            .where((t) => t.assigneeId == _assigneeFilterId)
                            .toList();
                  final open = filtered.where((t) => !t.done).toList();
                  final done = filtered.where((t) => t.done).toList();
                  final filterMember = _memberById(members, _assigneeFilterId);

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
                      if (members.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              SoftPill(
                                label: 'All',
                                selected: _assigneeFilterId == null,
                                onTap: () =>
                                    setState(() => _assigneeFilterId = null),
                              ),
                              const SizedBox(width: 6),
                              for (final m in members) ...[
                                _AssigneeFilterAvatar(
                                  member: m,
                                  selected: _assigneeFilterId == m.id,
                                  onTap: () {
                                    setState(() {
                                      _assigneeFilterId =
                                          _assigneeFilterId == m.id
                                          ? null
                                          : m.id;
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      if (tasks.isEmpty)
                        FirstRunEmptyCard(
                          icon: Icons.add_task_rounded,
                          color: AppColors.mint,
                          title: 'Add your first task',
                          body:
                              'Chores, reminders, and shared to-dos live here — tap to create one for the nest.',
                          actionLabel: 'Add task',
                          onAction: () =>
                              TasksScreen.showTaskSheet(context, ref),
                        )
                      else if (open.isEmpty && done.isEmpty)
                        FirstRunEmptyCard(
                          icon: Icons.person_outline_rounded,
                          color: AppColors.mint,
                          title: filterMember == null
                              ? 'No tasks here'
                              : 'Nothing for ${filterMember.name.split(' ').first}',
                          body: filterMember == null
                              ? 'Try another filter or add a task.'
                              : 'Tap All to see everyone, or add a task for them.',
                          actionLabel: 'Add task',
                          onAction: () =>
                              TasksScreen.showTaskSheet(context, ref),
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
                                color:
                                    AppColors.softCardColors[i %
                                        AppColors.softCardColors.length],
                                onToggle: () async {
                                  await ref
                                      .read(taskRepositoryProvider)
                                      .toggleDone(open[i]);
                                  await syncAfterWrite(ref, context: context);
                                },
                                onEdit: () => TasksScreen.showTaskSheet(
                                  context,
                                  ref,
                                  existing: open[i],
                                ),
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
                                    await syncAfterWrite(ref, context: context);
                                  },
                                  onEdit: () => TasksScreen.showTaskSheet(
                                    context,
                                    ref,
                                    existing: done[i],
                                  ),
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
}

class _AssigneeFilterAvatar extends StatelessWidget {
  const _AssigneeFilterAvatar({
    required this.member,
    required this.selected,
    required this.onTap,
  });

  final NestMember member;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: selected
          ? '${member.name}, selected filter'
          : 'Filter tasks for ${member.name}',
      selected: selected,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.ink : Colors.transparent,
            width: 2,
          ),
        ),
        child: MemberAvatar(
          initials: member.initials,
          color: Color(member.colorValue),
          size: 34,
        ),
      ),
    );
  }
}

class _TaskSheet extends StatefulWidget {
  const _TaskSheet({
    required this.members,
    required this.initialAssigneeId,
    this.existing,
  });

  final List<NestMember> members;
  final String initialAssigneeId;
  final Task? existing;

  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
  late final TextEditingController _controller;
  late String _assigneeId;
  late bool _recurring;
  late String _dueLabel;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _controller = TextEditingController(text: existing?.title ?? '');
    _assigneeId = widget.initialAssigneeId;
    _recurring = existing?.recurring ?? false;
    _dueLabel = existing?.dueLabel ?? 'Today';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit({bool deleteTask = false}) {
    final title = _controller.text.trim();
    if (!deleteTask && title.isEmpty) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context, (
      title: title.isEmpty ? (widget.existing?.title ?? '') : title,
      assigneeId: _assigneeId,
      recurring: _recurring,
      dueLabel: _dueLabel,
      deleteTask: deleteTask,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
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
            Text(
              existing == null ? 'New task' : 'Edit task',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              autofocus: existing == null,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(hintText: 'What needs doing?'),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final label in const ['Today', 'Tomorrow', 'In 7 days'])
                  SoftPill(
                    label: label,
                    selected: _dueLabel == label,
                    onTap: () => setState(() => _dueLabel = label),
                  ),
              ],
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
              child: Text(existing == null ? 'Add task' : 'Save changes'),
            ),
            if (existing != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _submit(deleteTask: true),
                child: const Text('Delete task'),
              ),
            ],
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
    required this.onEdit,
    this.bordered = false,
  });

  final Task task;
  final List<NestMember> members;
  final Color color;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
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
      onTap: onEdit,
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
                icon: task.done ? Icons.undo_rounded : Icons.check_rounded,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
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
