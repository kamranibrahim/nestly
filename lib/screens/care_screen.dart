import 'package:flutter/material.dart';
import '../widgets/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/enums.dart';
import '../data/member_roles.dart';
import '../providers/providers.dart';
import '../state/care_ui.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/first_run_empty_card.dart';
import '../widgets/sheet_form.dart';
import '../data/sync_controller.dart';
import '../l10n/l10n_ext.dart';

class CareScreen extends ConsumerWidget {
  const CareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(careUiProvider);
    final uiCtrl = ref.read(careUiProvider.notifier);
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
        title: Text(context.l10n.screenCare),
        actions: [
          IconButton(
            onPressed: () => _showAdd(context, ref),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const NestLoadingSkeleton(itemCount: 3),
        error: (_, _) =>
            Center(child: Text(context.l10n.loadFailedCare)),
        data: (all) {
          final items = ui.filter.isAll
              ? all
              : all.where((i) => i.category == ui.filter.label).toList();
          final due = items
              .where((i) => !i.nextDueAt.isAfter(endToday))
              .toList();
          final upcoming = items
              .where((i) => i.nextDueAt.isAfter(endToday))
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 84),
            children: [
              NestCard(
                child: Text(
                  context.l10n.careIntro,
                  style: const TextStyle(color: AppColors.inkSecondary, height: 1.4),
                ),
              ),
              const SizedBox(height: 10),
              SectionLabel(context.l10n.careElderProfiles),
              if (members.isEmpty)
                NestCard(
                  child: Text(
                    context.l10n.careAddMembersHint,
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                )
              else if (careMembers.isEmpty)
                NestCard(
                  child: Text(
                    context.l10n.careNoElders,
                    style: const TextStyle(color: AppColors.inkMuted, height: 1.35),
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
                          onTap: () =>
                              _editProfile(context, ref, careMembers[i]),
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
                      label: CareViewMode.due.display(context.l10n),
                      selected: ui.viewMode == CareViewMode.due,
                      onTap: () => uiCtrl.setViewMode(CareViewMode.due),
                    ),
                    const SizedBox(width: 6),
                    SoftPill(
                      label: CareViewMode.category.display(context.l10n),
                      selected: ui.viewMode == CareViewMode.category,
                      onTap: () => uiCtrl.setViewMode(CareViewMode.category),
                    ),
                    const SizedBox(width: 10),
                    for (final cat in CareCategory.values) ...[
                      SoftPill(
                        label: cat.display(context.l10n),
                        selected: ui.filter == cat,
                        onTap: () => uiCtrl.setFilter(cat),
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
                      ? context.l10n.emptyCareTitle
                      : context.l10n.careEmptyFilter(
                          ui.filter.display(context.l10n),
                        ),
                  body: all.isEmpty
                      ? context.l10n.emptyCareBody
                      : context.l10n.careEmptyFilterHint(
                          ui.filter.display(context.l10n),
                        ),
                  actionLabel: context.l10n.careAddItem,
                  onAction: () => _showAdd(context, ref),
                )
              else if (ui.viewMode == CareViewMode.category)
                ..._categorySections(context, ref, items, members, endToday)
              else ...[
                if (due.isNotEmpty) ...[
                  SectionLabel(context.l10n.careDueNow),
                  NestCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < due.length; i++) ...[
                          _CareRow(
                            item: due[i],
                            member: _memberFor(members, due[i].memberId),
                            highlight: true,
                            onDone: () => _markDone(context, ref, due[i]),
                            onSnooze: () => _snooze(context, ref, due[i]),
                            onSkip: () => _skip(context, ref, due[i]),
                            onEdit: () =>
                                _showAdd(context, ref, existing: due[i]),
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
                          _CareRow(
                            item: upcoming[i],
                            member: _memberFor(members, upcoming[i].memberId),
                            highlight: false,
                            onDone: () => _markDone(context, ref, upcoming[i]),
                            onSnooze: () =>
                                _snooze(context, ref, upcoming[i]),
                            onSkip: () => _skip(context, ref, upcoming[i]),
                            onEdit: () => _showAdd(
                              context,
                              ref,
                              existing: upcoming[i],
                            ),
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

List<Widget> _categorySections(
  BuildContext context,
  WidgetRef ref,
  List<CareItem> items,
  List<NestMember> members,
  DateTime endToday,
) {
  final l10n = context.l10n;
  final cats = <String>[];
  for (final item in items) {
    if (!cats.contains(item.category)) cats.add(item.category);
  }
  return [
    for (final cat in cats) ...[
      SectionLabel(
        CareCategory.parse(cat).display(l10n),
      ),
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
                    onDone: () => _markDone(context, ref, group[i]),
                    onSnooze: () => _snooze(context, ref, group[i]),
                    onSkip: () => _skip(context, ref, group[i]),
                    onEdit: () =>
                        _showAdd(context, ref, existing: group[i]),
                    onDelete: () => _delete(context, ref, group[i].id),
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

Future<void> _markDone(
  BuildContext context,
  WidgetRef ref,
  CareItem item,
) async {
  await ref.read(careRepositoryProvider).markDone(item);
  await syncAfterWrite(ref, context: context);
  try {
    await ref.read(notificationServiceProvider).rescheduleReminders();
  } catch (_) {}
}

Future<void> _snooze(
  BuildContext context,
  WidgetRef ref,
  CareItem item,
) async {
  await ref.read(careRepositoryProvider).snooze(item);
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
  CareItem item,
) async {
  await ref.read(careRepositoryProvider).skipCycle(item);
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

Future<void> _editProfile(
  BuildContext context,
  WidgetRef ref,
  NestMember member,
) async {
  final existing =
      await ref.read(careRepositoryProvider).profileForMember(member.id);
  if (!context.mounted) return;

  final result = await showModalBottomSheet<
      ({
        String medications,
        String allergies,
        String mobilityNotes,
        String primaryDoctor,
        String notes,
      })>(
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
  await ref.read(careRepositoryProvider).upsertProfile(
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
      SnackBar(content: Text(context.l10n.snackCareProfileSaved(member.name))),
    );
  }
}

Future<void> _showAdd(
  BuildContext context,
  WidgetRef ref, {
  CareItem? existing,
}) async {
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

  final result = await showModalBottomSheet<
      ({String title, String category, int cadence, String memberId})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      var category = CareCategory.parse(
        existing?.category ?? CareCategory.home.label,
      );
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
                    existing == null
                        ? context.l10n.careNewItem
                        : context.l10n.careEditItem,
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
                      hintText: category == CareCategory.elder
                          ? 'e.g. Morning medication'
                          : 'e.g. Change HVAC filter',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final cat in CareCategory.stored)
                        ChoiceChip(
                          label: Text(cat.display(context.l10n)),
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
                            if (cat == CareCategory.elder &&
                                memberId.isEmpty &&
                                members.isNotEmpty) {
                              memberId = members.first.id;
                            }
                          }),
                        ),
                    ],
                  ),
                  if (category == CareCategory.elder && members.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.careForWhom,
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
                        category: category.label,
                        cadence: cadence,
                        memberId: category == CareCategory.elder ? memberId : '',
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
          context.l10n.careProfileTitle(widget.member.name),
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
          decoration: InputDecoration(
            labelText: context.l10n.careMeds,
            hintText: context.l10n.careMedsHint,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _allergies,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: context.l10n.careAllergies,
            hintText: context.l10n.careAllergiesHint,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _mobility,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: context.l10n.careMobility,
            hintText: context.l10n.careMobilityHint,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _doctor,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: context.l10n.careDoctor,
            hintText: context.l10n.careDoctorHint,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _notes,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: context.l10n.commonNotes,
            hintText: context.l10n.careNotesHint,
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
          child: Text(context.l10n.saveProfile),
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
          PopupMenuButton<CareItemAction>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.inkMuted),
            onSelected: (value) {
              switch (value) {
                case CareItemAction.edit:
                  onEdit();
                case CareItemAction.snooze:
                  onSnooze();
                case CareItemAction.skip:
                  onSkip();
                case CareItemAction.delete:
                  onDelete();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: CareItemAction.edit,
                child: Text(context.l10n.commonEdit),
              ),
              PopupMenuItem(
                value: CareItemAction.snooze,
                child: Text(context.l10n.snooze1Day),
              ),
              PopupMenuItem(
                value: CareItemAction.skip,
                child: Text(context.l10n.skipCycle),
              ),
              PopupMenuItem(
                value: CareItemAction.delete,
                child: Text(context.l10n.commonDelete),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
