import 'package:flutter/material.dart';
import '../widgets/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/member_roles.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/sheet_form.dart';

class CareScreen extends ConsumerStatefulWidget {
  const CareScreen({super.key});

  @override
  ConsumerState<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends ConsumerState<CareScreen> {
  static const _categories = ['All', 'Elder', 'Home', 'Pet', 'Car'];
  String _filter = 'All';

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
          final due =
              items.where((i) => !i.nextDueAt.isAfter(endToday)).toList();
          final upcoming =
              items.where((i) => i.nextDueAt.isAfter(endToday)).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 72),
            children: [
              const NestCard(
                child: Text(
                  'Elder profiles, plus pet, home, and car upkeep — mark done to roll the next due date.',
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
              else
                NestCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < members.length; i++) ...[
                        _ProfileTile(
                          member: members[i],
                          profile: _profileFor(profiles, members[i].id),
                          highlighted: careMembers.any(
                            (c) => c.id == members[i].id,
                          ),
                          onTap: () => _editProfile(context, members[i]),
                        ),
                        if (i != members.length - 1)
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
                NestCard(
                  onTap: () => _showAdd(context),
                  child: Text(
                    all.isEmpty
                        ? 'No care schedules yet. Tap to add one.'
                        : 'Nothing in $_filter. Try another filter or add one.',
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                )
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
                            memberName: _memberName(members, due[i].memberId),
                            highlight: true,
                            onDone: () async {
                              await ref
                                  .read(careRepositoryProvider)
                                  .markDone(due[i]);
                              try {
                                await ref.read(syncServiceProvider).syncAll();
                              } catch (_) {}
                              try {
                                await ref
                                    .read(notificationServiceProvider)
                                    .rescheduleReminders();
                              } catch (_) {}
                            },
                            onDelete: () async {
                              await ref
                                  .read(careRepositoryProvider)
                                  .delete(due[i].id);
                              try {
                                await ref.read(syncServiceProvider).syncAll();
                              } catch (_) {}
                            },
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
                          _CareRow(
                            item: upcoming[i],
                            memberName:
                                _memberName(members, upcoming[i].memberId),
                            highlight: false,
                            onDone: () async {
                              await ref
                                  .read(careRepositoryProvider)
                                  .markDone(upcoming[i]);
                              try {
                                await ref.read(syncServiceProvider).syncAll();
                              } catch (_) {}
                              try {
                                await ref
                                    .read(notificationServiceProvider)
                                    .rescheduleReminders();
                              } catch (_) {}
                            },
                            onDelete: () async {
                              await ref
                                  .read(careRepositoryProvider)
                                  .delete(upcoming[i].id);
                              try {
                                await ref.read(syncServiceProvider).syncAll();
                              } catch (_) {}
                            },
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

  CareProfile? _profileFor(List<CareProfile> profiles, String memberId) {
    for (final p in profiles) {
      if (p.memberId == memberId) return p;
    }
    return null;
  }

  String? _memberName(List<NestMember> members, String memberId) {
    if (memberId.isEmpty) return null;
    for (final m in members) {
      if (m.id == memberId) return m.name;
    }
    return null;
  }

  Future<void> _editProfile(BuildContext context, NestMember member) async {
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
        return _CareProfileSheet(
          member: member,
          existing: existing,
        );
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
    try {
      await ref.read(syncServiceProvider).syncAll();
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved care profile for ${member.name}')),
      );
    }
  }

  Future<void> _showAdd(BuildContext context) async {
    final members = List<NestMember>.from(
      ref.read(membersProvider).valueOrNull ?? const [],
    )..sort((a, b) {
        final ag =
            MemberRoles.normalize(a.role) == MemberRoles.grandparent ? 0 : 1;
        final bg =
            MemberRoles.normalize(b.role) == MemberRoles.grandparent ? 0 : 1;
        return ag.compareTo(bg);
      });

    final result = await showModalBottomSheet<
        ({
          String title,
          String category,
          int cadence,
          String memberId,
        })>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        var category = 'Home';
        var cadence = 7;
        var memberId = '';
        return OwnedControllers(
          count: 1,
          builder: (context, c) {
            return StatefulBuilder(
              builder: (context, setModal) {
                return sheetBody(
                  context: context,
                  children: [
                    sheetHandle(),
                    const SizedBox(height: 6),
                    const Text(
                      'New care item',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: c[0],
                      autofocus: true,
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
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: category == cat
                                  ? Colors.white
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
                            category: category,
                            cadence: cadence,
                            memberId: category == 'Elder' ? memberId : '',
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
      await ref.read(careRepositoryProvider).add(
            title: result.title,
            category: result.category,
            cadenceDays: result.cadence,
            memberId: result.memberId,
          );
      try {
        await ref.read(syncServiceProvider).syncAll();
      } catch (_) {}
      try {
        await ref.read(notificationServiceProvider).rescheduleReminders();
      } catch (_) {}
    }
  }
}

class _CareProfileSheet extends StatefulWidget {
  const _CareProfileSheet({
    required this.member,
    required this.existing,
  });

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
          onPressed: () => Navigator.pop(
            context,
            (
              medications: _medications.text.trim(),
              allergies: _allergies.text.trim(),
              mobilityNotes: _mobility.text.trim(),
              primaryDoctor: _doctor.text.trim(),
              notes: _notes.text.trim(),
            ),
          ),
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
    final doctor = profile?.primaryDoctor.trim() ?? '';
    final summary = [
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
    required this.onDelete,
    this.memberName,
  });

  final CareItem item;
  final bool highlight;
  final VoidCallback onDone;
  final VoidCallback onDelete;
  final String? memberName;

  @override
  Widget build(BuildContext context) {
    final who = memberName == null || memberName!.isEmpty
        ? ''
        : ' · $memberName';
    return ListTile(
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
