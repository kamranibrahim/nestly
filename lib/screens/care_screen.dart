import 'package:flutter/material.dart';
import '../widgets/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/member_roles.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/first_run_empty_card.dart';
import '../widgets/sheet_form.dart';
import '../data/sync_controller.dart';

class CareScreen extends ConsumerStatefulWidget {
  const CareScreen({super.key});

  @override
  ConsumerState<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends ConsumerState<CareScreen> {
  static const _categories = ['All', 'Elder', 'Home', 'Pet', 'Car'];
  String _filter = 'All';
  /// `due` = Due now / Upcoming; `category` = grouped by category.
  String _viewMode = 'due';

  NestMember? _memberFor(List<NestMember> members, String memberId) {
    if (memberId.isEmpty) return null;
    for (final m in members) {
      if (m.id == memberId) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(careItemsProvider);
    final profiles = ref.watch(careProfilesProvider).valueOrNull ?? const [];
    final members = ref.watch(membersProvider).valueOrNull ?? const [];
    final now = DateTime.now();
    final endToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final careMembers = members
        .where(
          (m) =>
              MemberRoles.normalize(m.role) == MemberRoles.grandparent ||
              profiles.any((p) => p.memberId == m.id),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Care'),
        actions: [
          IconButton(
            onPressed: () => _showAdd(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const NestLoadingSkeleton(itemCount: 3),
        error: (_, _) =>
            const Center(child: Text('Could not load care items.')),
        data: (all) {
          final items = _filter == 'All'
              ? all
              : all.where((i) => i.category == _filter).toList();
          final due = items
              .where((i) => !i.nextDueAt.isAfter(endToday))
              .toList();
          final upcoming = items
              .where((i) => i.nextDueAt.isAfter(endToday))
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 72),
            children: [
              const NestCard(
                child: Text(
                  'Elder profiles plus pet, home, and car upkeep. Mark done to roll the next due date — start with one schedule if the list is empty.',
                  style: TextStyle(color: AppColors.inkSecondary, height: 1.4),
                ),
              ),
              const SizedBox(height: 10),
              const SectionLabel('Elder profiles'),
              if (members.isEmpty)
                const NestCard(
                  child: Text(
                    'Add family members in Nest, then set a Grandparent role.',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                )
              else if (careMembers.isEmpty)
                const NestCard(
                  child: Text(
                    'No elder profiles yet — set Grandparent in Nest, then add meds and allergies here.',
                    style: TextStyle(color: AppColors.inkMuted, height: 1.35),
                  ),
                )
              else
                NestCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < careMembers.length; i++) ...[
                        _ProfileTile(
                          member: careMembers[i],
                          profile: _profileFor(profiles, careMembers[i].id),
                          highlighted: true,
                          onTap: () => _editProfile(context, careMembers[i]),
                        ),
                        if (i != careMembers.length - 1)
                          const Divider(height: 1, indent: 68),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SoftPill(
                      label: 'Due list',
                      selected: _viewMode == 'due',
                      onTap: () => setState(() => _viewMode = 'due'),
                    ),
                    const SizedBox(width: 6),
                    SoftPill(
                      label: 'By category',
                      selected: _viewMode == 'category',
                      onTap: () => setState(() => _viewMode = 'category'),
                    ),
                    const SizedBox(width: 10),
                    for (final cat in _categories) ...[
                      SoftPill(
                        label: cat,
                        selected: _filter == cat,
                        onTap: () => setState(() => _filter = cat),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              if (items.isEmpty)
                FirstRunEmptyCard(
                  icon: Icons.favorite_outline_rounded,
                  color: all.isEmpty ? AppColors.mint : null,
                  title: all.isEmpty
                      ? 'Add your first care schedule'
                      : 'Nothing in $_filter',
                  body: all.isEmpty
                      ? 'Pet, home, car, or elder routines — mark done to roll the next due date.'
                      : 'Try another filter, or add a $_filter care item.',
                  actionLabel: 'Add care item',
                  onAction: () => _showAdd(context),
                )
              else if (_viewMode == 'category')
                ..._categorySections(context, items, members, endToday)
              else ...[
                if (due.isNotEmpty) ...[
                  const SectionLabel('Due now'),
                  NestCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < due.length; i++) ...[
                          _CareRow(
                            item: due[i],
                            member: _memberFor(members, due[i].memberId),
                            highlight: true,
                            onDone: () => _markDone(due[i]),
                            onSnooze: () => _snooze(due[i]),
                            onSkip: () => _skip(due[i]),
                            onEdit: () => _showAdd(context, existing: due[i]),
                            onDelete: () => _delete(due[i].id),
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
                          _CareRow(
                            item: upcoming[i],
                            member: _memberFor(members, upcoming[i].memberId),
                            highlight: false,
                            onDone: () => _markDone(upcoming[i]),
                            onSnooze: () => _snooze(upcoming[i]),
                            onSkip: () => _skip(upcoming[i]),
                            onEdit: () =>
                                _showAdd(context, existing: upcoming[i]),
                            onDelete: () => _delete(upcoming[i].id),
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

  List<Widget> _categorySections(
    BuildContext context,
    List<CareItem> items,
    List<NestMember> members,
    DateTime endToday,
  ) {
    final cats = <String>[];
    for (final item in items) {
      if (!cats.contains(item.category)) cats.add(item.category);
    }
    return [
      for (final cat in cats) ...[
        SectionLabel(cat),
        NestCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ...() {
                final group = items.where((i) => i.category == cat).toList();
                return [
                  for (var i = 0; i < group.length; i++) ...[
                    _CareRow(
                      item: group[i],
                      member: _memberFor(members, group[i].memberId),
                      highlight: !group[i].nextDueAt.isAfter(endToday),
                      onDone: () => _markDone(group[i]),
                      onSnooze: () => _snooze(group[i]),
                      onSkip: () => _skip(group[i]),
                      onEdit: () => _showAdd(context, existing: group[i]),
                      onDelete: () => _delete(group[i].id),
                    ),
                    if (i != group.length - 1)
                      const Divider(height: 1, indent: 68),
                  ],
                ];
              }(),
            ],
          ),
        ),
        const SizedBox(height: 6),
      ],
    ];
  }

  Future<void> _markDone(CareItem item) async {
    await ref.read(careRepositoryProvider).markDone(item);
    await syncAfterWrite(ref, context: context);
    try {
      await ref.read(notificationServiceProvider).rescheduleReminders();
    } catch (_) {}
  }

  Future<void> _snooze(CareItem item) async {
    await ref.read(careRepositoryProvider).snooze(item);
    await syncAfterWrite(ref, context: context);
    try {
      await ref.read(notificationServiceProvider).rescheduleReminders();
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Snoozed ${item.title} by 1 day')),
    );
  }

  Future<void> _skip(CareItem item) async {
    await ref.read(careRepositoryProvider).skipCycle(item);
    await syncAfterWrite(ref, context: context);
    try {
      await ref.read(notificationServiceProvider).rescheduleReminders();
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Skipped ${item.title} this cycle')),
    );
  }

  Future<void> _delete(String id) async {
    await ref.read(careRepositoryProvider).delete(id);
    await syncAfterWrite(ref, context: context);
    try {
      await ref.read(notificationServiceProvider).rescheduleReminders();
    } catch (_) {}
  }

  CareProfile? _profileFor(List<CareProfile> profiles, String memberId) {
    for (final p in profiles) {
      if (p.memberId == memberId) return p;
    }
    return null;
  }

  Future<void> _editProfile(BuildContext context, NestMember member) async {
    final existing = await ref
        .read(careRepositoryProvider)
        .profileForMember(member.id);
    if (!context.mounted) return;

    final result =
        await showModalBottomSheet<
          ({
            String medications,
            String allergies,
            String mobilityNotes,
            String primaryDoctor,
            String notes,
          })
        >(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return _CareProfileSheet(member: member, existing: existing);
          },
        );

    if (result == null) return;
    await ref
        .read(careRepositoryProvider)
        .upsertProfile(
          memberId: member.id,
          medications: result.medications,
          allergies: result.allergies,
          mobilityNotes: result.mobilityNotes,
          primaryDoctor: result.primaryDoctor,
          notes: result.notes,
        );
    await syncAfterWrite(ref, context: context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved care profile for ${member.name}')),
      );
    }
  }

  Future<void> _showAdd(BuildContext context, {CareItem? existing}) async {
    final members =
        List<NestMember>.from(ref.read(membersProvider).valueOrNull ?? const [])
          ..sort((a, b) {
            final ag = MemberRoles.normalize(a.role) == MemberRoles.grandparent
                ? 0
                : 1;
            final bg = MemberRoles.normalize(b.role) == MemberRoles.grandparent
                ? 0
                : 1;
            return ag.compareTo(bg);
          });

    final result =
        await showModalBottomSheet<
          ({String title, String category, int cadence, String memberId})
        >(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            var category = existing?.category ?? 'Home';
            var cadence = existing?.cadenceDays ?? 7;
            var memberId = existing?.memberId ?? '';
            return OwnedControllers(
              count: 1,
              builder: (context, c) {
                if (c[0].text.isEmpty && existing != null) {
                  c[0].text = existing.title;
                }
                return StatefulBuilder(
                  builder: (context, setModal) {
                    return sheetBody(
                      context: context,
                      children: [
                        sheetHandle(),
                        const SizedBox(height: 6),
                        Text(
                          existing == null ? 'New care item' : 'Edit care item',
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
                            hintText: category == 'Elder'
                                ? 'e.g. Morning medication'
                                : 'e.g. Change HVAC filter',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final cat in const [
                              'Elder',
                              'Home',
                              'Pet',
                              'Car',
                            ])
                              ChoiceChip(
                                label: Text(cat),
                                selected: category == cat,
                                showCheckmark: false,
                                selectedColor: AppColors.primary,
                                checkmarkColor: AppColors.onDark,
                                labelStyle: TextStyle(
                                  color: category == cat
                                      ? AppColors.onDark
                                      : AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (_) => setModal(() {
                                  category = cat;
                                  if (cat == 'Elder' &&
                                      memberId.isEmpty &&
                                      members.isNotEmpty) {
                                    memberId = members.first.id;
                                  }
                                }),
                              ),
                          ],
                        ),
                        if (category == 'Elder' && members.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'For whom?',
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
                          max: 90,
                          divisions: 89,
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
                              category: category,
                              cadence: cadence,
                              memberId: category == 'Elder' ? memberId : '',
                            ));
                          },
                          child: Text(existing == null ? 'Add' : 'Save'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );

    if (result == null) return;
    if (existing == null) {
      await ref.read(careRepositoryProvider).add(
            title: result.title,
            category: result.category,
            cadenceDays: result.cadence,
            memberId: result.memberId,
          );
    } else {
      await ref.read(careRepositoryProvider).update(
            id: existing.id,
            title: result.title,
            category: result.category,
            cadenceDays: result.cadence,
            memberId: result.memberId,
            notes: existing.notes,
          );
    }
    await syncAfterWrite(ref, context: context);
    try {
      await ref.read(notificationServiceProvider).rescheduleReminders();
    } catch (_) {}
  }

}

class _CareProfileSheet extends StatefulWidget {
  const _CareProfileSheet({required this.member, required this.existing});

  final NestMember member;
  final CareProfile? existing;

  @override
  State<_CareProfileSheet> createState() => _CareProfileSheetState();
}

class _CareProfileSheetState extends State<_CareProfileSheet> {
  late final TextEditingController _medications;
  late final TextEditingController _allergies;
  late final TextEditingController _mobility;
  late final TextEditingController _doctor;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _medications = TextEditingController(text: e?.medications ?? '');
    _allergies = TextEditingController(text: e?.allergies ?? '');
    _mobility = TextEditingController(text: e?.mobilityNotes ?? '');
    _doctor = TextEditingController(text: e?.primaryDoctor ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _medications.dispose();
    _allergies.dispose();
    _mobility.dispose();
    _doctor.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return sheetBody(
      context: context,
      children: [
        sheetHandle(),
        const SizedBox(height: 6),
        Text(
          'Care profile · ${widget.member.name}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          MemberRoles.normalize(widget.member.role),
          style: const TextStyle(color: AppColors.inkMuted),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _medications,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Medications',
            hintText: 'Morning BP med, evening…',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _allergies,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Allergies',
            hintText: 'Penicillin, peanuts…',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _mobility,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Mobility & support',
            hintText: 'Walker, needs help stairs…',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _doctor,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Primary doctor',
            hintText: 'Dr. Name · clinic',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _notes,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notes',
            hintText: 'Preferences, routines…',
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () => Navigator.pop(context, (
            medications: _medications.text.trim(),
            allergies: _allergies.text.trim(),
            mobilityNotes: _mobility.text.trim(),
            primaryDoctor: _doctor.text.trim(),
            notes: _notes.text.trim(),
          )),
          child: const Text('Save profile'),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.member,
    required this.profile,
    required this.highlighted,
    required this.onTap,
  });

  final NestMember member;
  final CareProfile? profile;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meds = profile?.medications.trim() ?? '';
    final allergies = profile?.allergies.trim() ?? '';
    final doctor = profile?.primaryDoctor.trim() ?? '';
    final summary = [
      if (allergies.isNotEmpty) 'Allergies: $allergies',
      if (meds.isNotEmpty) meds,
      if (doctor.isNotEmpty) doctor,
    ].join(' · ');

    return ListTile(
      onTap: onTap,
      leading: MemberAvatar(
        initials: member.initials,
        color: Color(member.colorValue),
        size: 36,
      ),
      title: Text(
        member.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        summary.isEmpty
            ? '${MemberRoles.normalize(member.role)} · tap to add care notes'
            : summary,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: highlighted ? AppColors.inkSecondary : AppColors.inkMuted,
          fontSize: 12.5,
        ),
      ),
      trailing: Icon(
        profile == null ? Icons.add_rounded : Icons.edit_outlined,
        color: AppColors.inkMuted,
        size: 20,
      ),
    );
  }
}

class _CareRow extends StatelessWidget {
  const _CareRow({
    required this.item,
    required this.highlight,
    required this.onDone,
    required this.onSnooze,
    required this.onSkip,
    required this.onEdit,
    required this.onDelete,
    this.member,
  });

  final CareItem item;
  final bool highlight;
  final VoidCallback onDone;
  final VoidCallback onSnooze;
  final VoidCallback onSkip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final NestMember? member;

  @override
  Widget build(BuildContext context) {
    final who = member == null ? '' : ' · ${member!.name.split(' ').first}';
    return ListTile(
      leading: member == null
          ? CircleAvatar(
              radius: 18,
              backgroundColor: highlight
                  ? AppColors.mint.withValues(alpha: 0.35)
                  : AppColors.surfaceMuted,
              child: Icon(
                Icons.favorite_outline_rounded,
                size: 18,
                color: highlight ? AppColors.primary : AppColors.inkMuted,
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
        '${item.category}$who · due ${DateFormat.MMMd().format(item.nextDueAt)}'
        '${item.lastDoneAt == null ? '' : ' · last ${DateFormat.MMMd().format(item.lastDoneAt!)}'}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.inkMuted),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                case 'snooze':
                  onSnooze();
                case 'skip':
                  onSkip();
                case 'delete':
                  onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'snooze', child: Text('Snooze 1 day')),
              PopupMenuItem(value: 'skip', child: Text('Skip this cycle')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
