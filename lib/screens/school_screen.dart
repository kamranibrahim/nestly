import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/member_roles.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/sheet_form.dart';

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
    final now = DateTime.now();
    final endToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('School & activities'),
        actions: [
          IconButton(
            onPressed: () => _showAdd(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Could not load activities.')),
        data: (all) {
          final items = _filter == 'All'
              ? all
              : all.where((i) => i.kind == _filter).toList();
          final due =
              items.where((i) => !i.nextAt.isAfter(endToday)).toList();
          final upcoming =
              items.where((i) => i.nextAt.isAfter(endToday)).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 72),
            children: [
              const NestCard(
                child: Text(
                  'School runs, sports, clubs, and pickups — mark done to roll the next date, or add a same-day pickup task.',
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
                NestCard(
                  onTap: () => _showAdd(context),
                  child: Text(
                    all.isEmpty
                        ? 'No school schedules yet. Tap to add one.'
                        : 'Nothing in $_filter. Try another filter or add one.',
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
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
                            highlight: true,
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
                            highlight: false,
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

  Future<void> _markDone(SchoolActivity item) async {
    await ref.read(schoolRepositoryProvider).markDone(item);
    try {
      await ref.read(syncServiceProvider).syncAll();
    } catch (_) {}
  }

  Future<void> _pickup(SchoolActivity item) async {
    await ref.read(schoolRepositoryProvider).createPickupTask(item);
    try {
      await ref.read(syncServiceProvider).syncAll();
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pickup task added for today')),
    );
  }

  Future<void> _delete(String id) async {
    await ref.read(schoolRepositoryProvider).delete(id);
    try {
      await ref.read(syncServiceProvider).syncAll();
    } catch (_) {}
  }

  Future<void> _showAdd(BuildContext context) async {
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
        })>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        var kind = 'School';
        var cadence = 7;
        var memberId = members.isEmpty ? '' : members.first.id;
        return OwnedControllers(
          count: 2,
          builder: (context, c) {
            return StatefulBuilder(
              builder: (context, setModal) {
                return sheetBody(
                  context: context,
                  children: [
                    sheetHandle(),
                    const SizedBox(height: 6),
                    const Text(
                      'New activity',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: c[0],
                      autofocus: true,
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
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: kind == k
                                  ? Colors.white
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
                      onChanged: (v) =>
                          setModal(() => cadence = v.round()),
                    ),
                    FilledButton(
                      onPressed: () {
                        final name = c[0].text.trim();
                        if (name.isEmpty) {
                          Navigator.pop(context);
                          return;
                        }
                        Navigator.pop(
                          context,
                          (
                            title: name,
                            kind: kind,
                            cadence: cadence,
                            location: c[1].text.trim(),
                            memberId: memberId,
                          ),
                        );
                      },
                      child: const Text('Add'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (result != null) {
      await ref.read(schoolRepositoryProvider).add(
            title: result.title,
            kind: result.kind,
            cadenceDays: result.cadence,
            location: result.location,
            memberId: result.memberId,
          );
      try {
        await ref.read(syncServiceProvider).syncAll();
      } catch (_) {}
    }
  }
}

class _SchoolRow extends StatelessWidget {
  const _SchoolRow({
    required this.item,
    required this.highlight,
    required this.onDone,
    required this.onPickup,
    required this.onDelete,
  });

  final SchoolActivity item;
  final bool highlight;
  final VoidCallback onDone;
  final VoidCallback onPickup;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final loc = item.location.trim();
    return ListTile(
      title: Text(
        item.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${item.kind}'
        '${loc.isEmpty ? '' : ' · $loc'}'
        ' · next ${DateFormat.MMMd().format(item.nextAt)}'
        '${item.lastDoneAt == null ? '' : ' · last ${DateFormat.MMMd().format(item.lastDoneAt!)}'}',
      ),
      isThreeLine: loc.isNotEmpty,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Add pickup task',
            onPressed: onPickup,
            icon: const Icon(Icons.directions_car_outlined,
                color: AppColors.inkMuted),
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
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
