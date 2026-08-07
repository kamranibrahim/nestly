import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/enums.dart';
import '../data/member_roles.dart';
import '../providers/providers.dart';
import '../state/school_ui.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/first_run_empty_card.dart';
import '../widgets/sheet_form.dart';
import '../widgets/shimmer.dart';
import '../data/sync_controller.dart';
import '../l10n/l10n_ext.dart';

class SchoolScreen extends ConsumerWidget {
  const SchoolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(schoolUiProvider);
    final uiCtrl = ref.read(schoolUiProvider.notifier);
    final itemsAsync = ref.watch(schoolActivitiesProvider);
    final members = ref.watch(membersProvider).valueOrNull ?? const [];
    final now = DateTime.now();
    final endToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.screenSchool),
        actions: [
          IconButton(
            onPressed: () => _showSheet(context, ref),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const NestLoadingSkeleton(itemCount: 3, hasTitle: true),
        error: (_, _) =>
            Center(child: Text(context.l10n.loadFailedSchool)),
        data: (all) {
          final items = ui.filter.isAll
              ? all
              : all.where((i) => i.kind == ui.filter.label).toList();
          final due = items.where((i) => !i.nextAt.isAfter(endToday)).toList();
          final upcoming = items
              .where((i) => i.nextAt.isAfter(endToday))
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 84),
            children: [
              NestCard(
                child: Text(
                  context.l10n.schoolIntro,
                  style: const TextStyle(color: AppColors.inkSecondary, height: 1.4),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final kind in SchoolKind.values) ...[
                      SoftPill(
                        label: kind.display(context.l10n),
                        selected: ui.filter == kind,
                        onTap: () => uiCtrl.setFilter(kind),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              if (items.isEmpty)
                FirstRunEmptyCard(
                  icon: Icons.school_outlined,
                  color: all.isEmpty ? AppColors.accent : null,
                  title: all.isEmpty
                      ? context.l10n.emptySchoolTitle
                      : context.l10n.schoolEmptyFilter(
                          ui.filter.display(context.l10n),
                        ),
                  body: all.isEmpty
                      ? context.l10n.emptySchoolBody
                      : context.l10n.schoolEmptyFilterHint(
                          ui.filter.display(context.l10n),
                        ),
                  actionLabel: context.l10n.schoolAddItem,
                  onAction: () => _showSheet(context, ref),
                )
              else ...[
                if (due.isNotEmpty) ...[
                  SectionLabel(context.l10n.schoolDueToday),
                  NestCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < due.length; i++) ...[
                          _SchoolRow(
                            item: due[i],
                            member: _memberFor(members, due[i].memberId),
                            highlight: true,
                            onOpen: () =>
                                _showSheet(context, ref, existing: due[i]),
                            onDone: () => _markDone(context, ref, due[i]),
                            onPickup: () => _pickup(context, ref, due[i]),
                            onCalendar: () =>
                                _toCalendar(context, ref, due[i]),
                            onSnooze: () => _snooze(context, ref, due[i]),
                            onSkip: () => _skip(context, ref, due[i]),
                            onDelete: () => _delete(context, ref, due[i].id),
                          ),
                          if (i != due.length - 1)
                            const Divider(height: 1, indent: 68),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (upcoming.isNotEmpty) ...[
                  const SectionLabel('Upcoming'),
                  NestCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < upcoming.length; i++) ...[
                          _SchoolRow(
                            item: upcoming[i],
                            member: _memberFor(members, upcoming[i].memberId),
                            highlight: false,
                            onOpen: () => _showSheet(
                              context,
                              ref,
                              existing: upcoming[i],
                            ),
                            onDone: () => _markDone(context, ref, upcoming[i]),
                            onPickup: () => _pickup(context, ref, upcoming[i]),
                            onCalendar: () =>
                                _toCalendar(context, ref, upcoming[i]),
                            onSnooze: () =>
                                _snooze(context, ref, upcoming[i]),
                            onSkip: () => _skip(context, ref, upcoming[i]),
                            onDelete: () =>
                                _delete(context, ref, upcoming[i].id),
                          ),
                          if (i != upcoming.length - 1)
                            const Divider(height: 1, indent: 68),
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
}

NestMember? _memberFor(List<NestMember> members, String memberId) {
  if (memberId.isEmpty) return null;
  for (final m in members) {
    if (m.id == memberId) return m;
  }
  return null;
}

Future<void> _markDone(
  BuildContext context,
  WidgetRef ref,
  SchoolActivity item,
) async {
  await ref.read(schoolRepositoryProvider).markDone(item);
  await syncAfterWrite(ref, context: context);
  try {
    await ref.read(notificationServiceProvider).rescheduleReminders();
  } catch (_) {}
}

Future<void> _pickup(
  BuildContext context,
  WidgetRef ref,
  SchoolActivity item,
) async {
  final assignee =
      await ref.read(schoolRepositoryProvider).createPickupTask(item);
  await syncAfterWrite(ref, context: context);
  if (!context.mounted) return;
  final who = (assignee == null || assignee.trim().isEmpty)
      ? 'today'
      : 'for ${assignee.split(' ').first}';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.snackPickupAdded(who))),
  );
}

Future<void> _toCalendar(
  BuildContext context,
  WidgetRef ref,
  SchoolActivity item,
) async {
  await ref.read(schoolRepositoryProvider).createCalendarEvent(item);
  await syncAfterWrite(ref, context: context);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        context.l10n.snackCalendarAdded(DateFormat.MMMd().format(item.nextAt)),
      ),
    ),
  );
}

Future<void> _snooze(
  BuildContext context,
  WidgetRef ref,
  SchoolActivity item,
) async {
  await ref.read(schoolRepositoryProvider).snooze(item);
  await syncAfterWrite(ref, context: context);
  try {
    await ref.read(notificationServiceProvider).rescheduleReminders();
  } catch (_) {}
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.snackSnoozed(item.title))),
  );
}

Future<void> _skip(
  BuildContext context,
  WidgetRef ref,
  SchoolActivity item,
) async {
  await ref.read(schoolRepositoryProvider).skipCycle(item);
  await syncAfterWrite(ref, context: context);
  try {
    await ref.read(notificationServiceProvider).rescheduleReminders();
  } catch (_) {}
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.snackSkipped(item.title))),
  );
}

Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
  await ref.read(schoolRepositoryProvider).delete(id);
  await syncAfterWrite(ref, context: context);
  try {
    await ref.read(notificationServiceProvider).rescheduleReminders();
  } catch (_) {}
}

Future<void> _showSheet(
  BuildContext context,
  WidgetRef ref, {
  SchoolActivity? existing,
}) async {
  final members = List<NestMember>.from(
    ref.read(membersProvider).valueOrNull ?? const [],
  )..sort((a, b) => MemberRoles.kidsFirst(a.role, b.role));

  final result = await showModalBottomSheet<
      ({
        String title,
        String kind,
        int cadence,
        String location,
        String memberId,
        String notes,
        DateTime nextAt,
        bool deleteItem,
      })>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      var kind = SchoolKind.parse(existing?.kind ?? SchoolKind.school.label);
      var cadence = existing?.cadenceDays ?? 7;
      var memberId = existing?.memberId.isNotEmpty == true
          ? existing!.memberId
          : (members.isEmpty ? '' : members.first.id);
      var nextAt =
          existing?.nextAt ?? DateTime.now().add(Duration(days: cadence));
      return OwnedControllers(
        count: 3,
        builder: (context, c) {
          if (c[0].text.isEmpty && existing != null) {
            c[0].text = existing.title;
          }
          if (c[1].text.isEmpty && existing != null) {
            c[1].text = existing.location;
          }
          if (c[2].text.isEmpty && existing != null) {
            c[2].text = existing.notes;
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
                        ? context.l10n.schoolNewActivity
                        : context.l10n.schoolEditActivity,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: c[0],
                    autofocus: existing == null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: context.l10n.hintSchoolTitle,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: c[1],
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: context.l10n.hintLocationOptional,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: c[2],
                    minLines: 2,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: context.l10n.hintNotesOptional,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final k in SchoolKind.stored)
                        ChoiceChip(
                          label: Text(k.display(context.l10n)),
                          selected: kind == k,
                          showCheckmark: false,
                          selectedColor: AppColors.primary,
                          checkmarkColor: AppColors.onDark,
                          labelStyle: TextStyle(
                            color:
                                kind == k ? AppColors.onDark : AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setModal(() => kind = k),
                        ),
                    ],
                  ),
                  if (members.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.schoolWhoFor,
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
                            selected: memberId == m.id,
                            onTap: () => setModal(() => memberId = m.id),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  SoftPill(
                    label: 'Next · ${DateFormat('EEE, MMM d').format(nextAt)}',
                    selected: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: nextAt,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked == null) return;
                      setModal(() {
                        nextAt = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Every $cadence day${cadence == 1 ? '' : 's'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: cadence.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    label: '$cadence days',
                    onChanged: (v) => setModal(() => cadence = v.round()),
                  ),
                  FilledButton(
                    onPressed: () {
                      final name = c[0].text.trim();
                      if (name.isEmpty) {
                        Navigator.pop(context);
                        return;
                      }
                      Navigator.pop(context, (
                        title: name,
                        kind: kind.label,
                        cadence: cadence,
                        location: c[1].text.trim(),
                        memberId: memberId,
                        notes: c[2].text.trim(),
                        nextAt: nextAt,
                        deleteItem: false,
                      ));
                    },
                    child: Text(
                      existing == null
                          ? context.l10n.commonAdd
                          : context.l10n.commonSaveChanges,
                    ),
                  ),
                  if (existing != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context, (
                        title: existing.title,
                        kind: existing.kind,
                        cadence: existing.cadenceDays,
                        location: existing.location,
                        memberId: existing.memberId,
                        notes: existing.notes,
                        nextAt: existing.nextAt,
                        deleteItem: true,
                      )),
                      child: Text(context.l10n.deleteActivity),
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

  if (result == null) return;

  if (result.deleteItem && existing != null) {
    await _delete(context, ref, existing.id);
    return;
  }

  if (existing == null) {
    await ref.read(schoolRepositoryProvider).add(
          title: result.title,
          kind: result.kind,
          cadenceDays: result.cadence,
          location: result.location,
          memberId: result.memberId,
          notes: result.notes,
          nextAt: result.nextAt,
        );
  } else {
    await ref.read(schoolRepositoryProvider).update(
          id: existing.id,
          title: result.title,
          kind: result.kind,
          cadenceDays: result.cadence,
          location: result.location,
          memberId: result.memberId,
          notes: result.notes,
          nextAt: result.nextAt,
        );
  }
  await syncAfterWrite(ref, context: context);
  try {
    await ref.read(notificationServiceProvider).rescheduleReminders();
  } catch (_) {}
}

class _SchoolRow extends StatelessWidget {
  const _SchoolRow({
    required this.item,
    required this.highlight,
    required this.onOpen,
    required this.onDone,
    required this.onPickup,
    required this.onCalendar,
    required this.onSnooze,
    required this.onSkip,
    required this.onDelete,
    this.member,
  });

  final SchoolActivity item;
  final bool highlight;
  final VoidCallback onOpen;
  final VoidCallback onDone;
  final VoidCallback onPickup;
  final VoidCallback onCalendar;
  final VoidCallback onSnooze;
  final VoidCallback onSkip;
  final VoidCallback onDelete;
  final NestMember? member;

  @override
  Widget build(BuildContext context) {
    final loc = item.location.trim();
    final notes = item.notes.trim();
    final due = _dueLabel(item.nextAt);
    final who = member == null ? null : member!.name.split(' ').first;
    return ListTile(
      onTap: onOpen,
      leading: member == null
          ? CircleAvatar(
              radius: 18,
              backgroundColor: highlight
                  ? AppColors.accent.withValues(alpha: 0.25)
                  : AppColors.surfaceMuted,
              child: Icon(
                Icons.school_outlined,
                size: 18,
                color: highlight ? AppColors.accent : AppColors.inkMuted,
              ),
            )
          : MemberAvatar(
              initials: member!.initials,
              color: Color(member!.colorValue),
              size: 36,
            ),
      title: Text(
        item.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          item.kind,
          ?who,
          if (loc.isNotEmpty) loc,
          due,
          if (item.lastDoneAt != null)
            'last ${DateFormat.MMMd().format(item.lastDoneAt!)}',
          if (notes.isNotEmpty) notes,
        ].join(' · '),
      ),
      isThreeLine: loc.isNotEmpty || notes.isNotEmpty,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: context.l10n.addPickupTask,
            onPressed: onPickup,
            icon: const Icon(
              Icons.directions_car_outlined,
              color: AppColors.inkMuted,
            ),
          ),
          TextButton(
            onPressed: onDone,
            child: Text(
              'Done',
              style: TextStyle(
                color: highlight ? AppColors.primary : AppColors.inkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          PopupMenuButton<SchoolItemAction>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.inkMuted),
            onSelected: (value) {
              switch (value) {
                case SchoolItemAction.calendar:
                  onCalendar();
                case SchoolItemAction.snooze:
                  onSnooze();
                case SchoolItemAction.skip:
                  onSkip();
                case SchoolItemAction.delete:
                  onDelete();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SchoolItemAction.calendar,
                child: Text(context.l10n.createCalendarEvent),
              ),
              PopupMenuItem(
                value: SchoolItemAction.snooze,
                child: Text(context.l10n.snooze1Day),
              ),
              PopupMenuItem(
                value: SchoolItemAction.skip,
                child: Text(context.l10n.skipCycle),
              ),
              PopupMenuItem(
                value: SchoolItemAction.delete,
                child: Text(context.l10n.commonDelete),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dueLabel(DateTime nextAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(nextAt.year, nextAt.month, nextAt.day);
    final days = day.difference(today).inDays;
    if (days < 0) {
      return 'overdue · ${DateFormat.MMMd().format(nextAt)}';
    }
    if (days == 0) return 'due today';
    if (days == 1) return 'due tomorrow';
    if (days < 7) return 'due in $days days';
    return 'next ${DateFormat.MMMd().format(nextAt)}';
  }
}
