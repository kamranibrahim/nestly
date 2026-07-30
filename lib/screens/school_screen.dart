import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/member_roles.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/first_run_empty_card.dart';
import '../widgets/sheet_form.dart';
import '../widgets/shimmer.dart';
import '../data/sync_controller.dart';

class SchoolScreen extends ConsumerStatefulWidget {
  const SchoolScreen({super.key});

  @override
  ConsumerState<SchoolScreen> createState() => _SchoolScreenState();
}

class _SchoolScreenState extends ConsumerState<SchoolScreen> {
  static const _kinds = ['All', 'School', 'Sports', 'Pickup', 'Club'];
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(schoolActivitiesProvider);
    final members = ref.watch(membersProvider).valueOrNull ?? const [];
    final now = DateTime.now();
    final endToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('School & activities'),
        actions: [
          IconButton(
            onPressed: () => _showSheet(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const NestLoadingSkeleton(itemCount: 3, hasTitle: true),
        error: (_, _) =>
            const Center(child: Text('Could not load activities.')),
        data: (all) {
          final items = _filter == 'All'
              ? all
              : all.where((i) => i.kind == _filter).toList();
          final due = items.where((i) => !i.nextAt.isAfter(endToday)).toList();
          final upcoming = items
              .where((i) => i.nextAt.isAfter(endToday))
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 72),
            children: [
              const NestCard(
                child: Text(
                  'School runs, sports, clubs, and pickups. Add one activity to get started — mark done to roll the next date, or create a same-day pickup task.',
                  style: TextStyle(color: AppColors.inkSecondary, height: 1.4),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final kind in _kinds) ...[
                      SoftPill(
                        label: kind,
                        selected: _filter == kind,
                        onTap: () => setState(() => _filter = kind),
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
                      ? 'Add your first school run'
                      : 'Nothing in $_filter',
                  body: all.isEmpty
                      ? 'Pickups, sports, and clubs — mark done to roll the next date, or turn one into a same-day pickup task.'
                      : 'Try another filter, or add a $_filter activity.',
                  actionLabel: 'Add activity',
                  onAction: () => _showSheet(context),
                )
              else ...[
                if (due.isNotEmpty) ...[
                  const SectionLabel('Due today'),
                  NestCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < due.length; i++) ...[
                          _SchoolRow(
                            item: due[i],
                            memberName: _memberName(members, due[i].memberId),
                            highlight: true,
                            onOpen: () => _showSheet(context, existing: due[i]),
                            onDone: () => _markDone(due[i]),
                            onPickup: () => _pickup(due[i]),
                            onDelete: () => _delete(due[i].id),
                          ),
                          if (i != due.length - 1)
                            const Divider(height: 1, indent: 16),
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
                            memberName: _memberName(
                              members,
                              upcoming[i].memberId,
                            ),
                            highlight: false,
                            onOpen: () =>
                                _showSheet(context, existing: upcoming[i]),
                            onDone: () => _markDone(upcoming[i]),
                            onPickup: () => _pickup(upcoming[i]),
                            onDelete: () => _delete(upcoming[i].id),
                          ),
                          if (i != upcoming.length - 1)
                            const Divider(height: 1, indent: 16),
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

  String? _memberName(List<NestMember> members, String memberId) {
    if (memberId.isEmpty) return null;
    for (final m in members) {
      if (m.id == memberId) return m.name.split(' ').first;
    }
    return null;
  }

  Future<void> _markDone(SchoolActivity item) async {
    await ref.read(schoolRepositoryProvider).markDone(item);
    await syncAfterWrite(ref, context: context);
    try {
      await ref.read(notificationServiceProvider).rescheduleReminders();
    } catch (_) {}
  }

  Future<void> _pickup(SchoolActivity item) async {
    await ref.read(schoolRepositoryProvider).createPickupTask(item);
    await syncAfterWrite(ref, context: context);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pickup task added for today')),
    );
  }

  Future<void> _delete(String id) async {
    await ref.read(schoolRepositoryProvider).delete(id);
    await syncAfterWrite(ref, context: context);
    try {
      await ref.read(notificationServiceProvider).rescheduleReminders();
    } catch (_) {}
  }

  Future<void> _showSheet(
    BuildContext context, {
    SchoolActivity? existing,
  }) async {
    final members = List<NestMember>.from(
      ref.read(membersProvider).valueOrNull ?? const [],
    )..sort((a, b) => MemberRoles.kidsFirst(a.role, b.role));

    final result =
        await showModalBottomSheet<
          ({
            String title,
            String kind,
            int cadence,
            String location,
            String memberId,
            String notes,
            DateTime nextAt,
            bool deleteItem,
          })
        >(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            var kind = existing?.kind ?? 'School';
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
                          existing == null ? 'New activity' : 'Edit activity',
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
                          decoration: const InputDecoration(
                            hintText: 'e.g. Soccer practice',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: c[1],
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Location (optional)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: c[2],
                          minLines: 2,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Notes (optional)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final k in const [
                              'School',
                              'Sports',
                              'Pickup',
                              'Club',
                            ])
                              ChoiceChip(
                                label: Text(k),
                                selected: kind == k,
                                showCheckmark: false,
                                selectedColor: AppColors.primary,
                                checkmarkColor: AppColors.onDark,
                                labelStyle: TextStyle(
                                  color: kind == k
                                      ? AppColors.onDark
                                      : AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (_) => setModal(() => kind = k),
                              ),
                          ],
                        ),
                        if (members.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Who is this for?',
                            style: TextStyle(fontWeight: FontWeight.w600),
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
                          label:
                              'Next · ${DateFormat('EEE, MMM d').format(nextAt)}',
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
                              kind: kind,
                              cadence: cadence,
                              location: c[1].text.trim(),
                              memberId: memberId,
                              notes: c[2].text.trim(),
                              nextAt: nextAt,
                              deleteItem: false,
                            ));
                          },
                          child: Text(
                            existing == null ? 'Add' : 'Save changes',
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
                            child: const Text('Delete activity'),
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
      await _delete(existing.id);
      return;
    }

    if (existing == null) {
      await ref
          .read(schoolRepositoryProvider)
          .add(
            title: result.title,
            kind: result.kind,
            cadenceDays: result.cadence,
            location: result.location,
            memberId: result.memberId,
            notes: result.notes,
            nextAt: result.nextAt,
          );
    } else {
      await ref
          .read(schoolRepositoryProvider)
          .update(
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
}

class _SchoolRow extends StatelessWidget {
  const _SchoolRow({
    required this.item,
    required this.highlight,
    required this.onOpen,
    required this.onDone,
    required this.onPickup,
    required this.onDelete,
    this.memberName,
  });

  final SchoolActivity item;
  final bool highlight;
  final VoidCallback onOpen;
  final VoidCallback onDone;
  final VoidCallback onPickup;
  final VoidCallback onDelete;
  final String? memberName;

  @override
  Widget build(BuildContext context) {
    final loc = item.location.trim();
    final notes = item.notes.trim();
    final due = _dueLabel(item.nextAt);
    return ListTile(
      onTap: onOpen,
      title: Text(
        item.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          item.kind,
          ?memberName,
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
            tooltip: 'Add pickup task',
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
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.inkMuted,
            ),
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
