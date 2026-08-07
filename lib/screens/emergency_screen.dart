import 'package:flutter/material.dart';
import '../widgets/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../data/db/app_database.dart';
import '../data/enums.dart';
import '../data/member_roles.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/sheet_form.dart';
import 'care_screen.dart';
import '../data/sync_controller.dart';
import '../l10n/l10n_ext.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(emergencyProvider);
    final profiles = ref.watch(careProfilesProvider).valueOrNull ?? const [];
    final members = ref.watch(membersProvider).valueOrNull ?? const [];
    final nestName =
        ref.watch(nestInfoProvider).valueOrNull?.name ?? context.l10n.ourNest;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.screenEmergency),
        actions: [
          IconButton(
            tooltip: context.l10n.emergencyShareCard,
            onPressed: () => _shareCard(
              context,
              nestName: nestName,
              entries: entries.valueOrNull ?? const [],
              profiles: profiles,
              members: members,
            ),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          IconButton(
            tooltip: context.l10n.emergencyCopyCard,
            onPressed: () => _copyCard(
              context,
              nestName: nestName,
              entries: entries.valueOrNull ?? const [],
              profiles: profiles,
              members: members,
            ),
            icon: const Icon(Icons.copy_rounded),
          ),
          IconButton(
            onPressed: () => _addEntry(context, ref),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 28),
        children: [
          NestCard(
            color: AppColors.dangerSoft,
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: AppColors.danger),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.emergencyOfflineNote,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (profiles.isNotEmpty) ...[
            const SizedBox(height: 10),
            SectionLabel(context.l10n.emergencyCareProfiles),
            NestCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < profiles.length; i++) ...[
                    _CareSnapshotTile(
                      profile: profiles[i],
                      member: _memberFor(members, profiles[i].memberId),
                      onOpen: () => nestPush(context, const CareScreen()),
                    ),
                    if (i != profiles.length - 1)
                      const Divider(height: 1, indent: 68),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          const SectionLabel('Contacts & notes'),
          entries.when(
            loading: () => const NestLoadingSkeleton(itemCount: 3),
            error: (e, _) => Text('$e'),
            data: (items) {
              if (items.isEmpty) {
                return NestCard(
                  onTap: () => _addEntry(context, ref),
                  child: Text(
                    context.l10n.emergencyAddHint,
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                );
              }
              return NestCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      ListTile(
                        onTap: () => _onEntryTap(context, items[i]),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.dangerSoft,
                          child: Icon(
                            _iconFor(items[i].iconName),
                            color: AppColors.danger,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          items[i].label,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.inkMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          items[i].value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                            fontSize: 14.5,
                          ),
                        ),
                        trailing: _looksLikePhone(items[i].value)
                            ? const Icon(
                                Icons.copy_rounded,
                                size: 18,
                                color: AppColors.inkMuted,
                              )
                            : null,
                      ),
                      if (i != items.length - 1)
                        const Divider(height: 1, indent: 72),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  NestMember? _memberFor(List<NestMember> members, String memberId) {
    for (final m in members) {
      if (m.id == memberId) return m;
    }
    return null;
  }

  static bool _looksLikePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 7;
  }

  Future<void> _onEntryTap(BuildContext context, EmergencyEntry entry) async {
    if (_looksLikePhone(entry.value)) {
      await Clipboard.setData(ClipboardData(text: entry.value.trim()));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.emergencyCopiedEntry(entry.label))),
        );
      }
      return;
    }
    await Clipboard.setData(ClipboardData(text: entry.value.trim()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.emergencyCopied)),
      );
    }
  }

  Future<void> _shareCard(
    BuildContext context, {
    required String nestName,
    required List<EmergencyEntry> entries,
    required List<CareProfile> profiles,
    required List<NestMember> members,
  }) async {
    final text = _cardText(
      l10n: context.l10n,
      nestName: nestName,
      entries: entries,
      profiles: profiles,
      members: members,
    );
    if (text == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.emergencyNeedData)),
      );
      return;
    }

    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: '$nestName emergency card',
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<void> _copyCard(
    BuildContext context, {
    required String nestName,
    required List<EmergencyEntry> entries,
    required List<CareProfile> profiles,
    required List<NestMember> members,
  }) async {
    final text = _cardText(
      l10n: context.l10n,
      nestName: nestName,
      entries: entries,
      profiles: profiles,
      members: members,
    );
    if (text == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.emergencyNeedDataCopy)),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.emergencyCardCopied)),
    );
  }

  String? _cardText({
    required AppLocalizations l10n,
    required String nestName,
    required List<EmergencyEntry> entries,
    required List<CareProfile> profiles,
    required List<NestMember> members,
  }) {
    if (profiles.isEmpty && entries.isEmpty) return null;

    final buf = StringBuffer('${l10n.emergencyCardTitle(nestName)}\n');
    if (profiles.isNotEmpty) {
      buf.writeln('\nCare profiles');
      for (final p in profiles) {
        final name = _memberFor(members, p.memberId)?.name ?? 'Member';
        buf.writeln('• $name');
        if (p.allergies.trim().isNotEmpty) {
          buf.writeln('  Allergies: ${p.allergies.trim()}');
        }
        if (p.medications.trim().isNotEmpty) {
          buf.writeln('  Meds: ${p.medications.trim()}');
        }
        if (p.primaryDoctor.trim().isNotEmpty) {
          buf.writeln('  Doctor: ${p.primaryDoctor.trim()}');
        }
        if (p.mobilityNotes.trim().isNotEmpty) {
          buf.writeln('  Mobility: ${p.mobilityNotes.trim()}');
        }
      }
    }
    if (entries.isNotEmpty) {
      buf.writeln('\nContacts & notes');
      for (final e in entries) {
        buf.writeln('• ${e.label}: ${e.value}');
      }
    }
    buf.writeln(
      '\nShared from Casaio — keep offline on family devices. Update in the app when details change.',
    );
    return buf.toString();
  }

  IconData _iconFor(String name) {
    return switch (EmergencyIcon.parse(name)) {
      EmergencyIcon.phone => Icons.phone_in_talk_outlined,
      EmergencyIcon.doctor => Icons.medical_services_outlined,
      EmergencyIcon.hospital => Icons.local_hospital_outlined,
      EmergencyIcon.warning => Icons.warning_amber_rounded,
      EmergencyIcon.blood => Icons.bloodtype_outlined,
      EmergencyIcon.shield => Icons.health_and_safety_outlined,
      EmergencyIcon.info => Icons.info_outline_rounded,
    };
  }

  Future<void> _addEntry(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<({String label, String value})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return OwnedControllers(
          count: 2,
          builder: (context, c) {
            return sheetBody(
              context: context,
              children: [
                sheetHandle(),
                const SizedBox(height: 6),
                Text(
                  context.l10n.emergencyInfo,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: c[0],
                  decoration: InputDecoration(labelText: context.l10n.emergencyLabel),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: c[1],
                  decoration: InputDecoration(labelText: context.l10n.emergencyDetails),
                ),
                const SizedBox(height: 6),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    (label: c[0].text.trim(), value: c[1].text.trim()),
                  ),
                  child: Text(context.l10n.saveOffline),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != null &&
        result.label.isNotEmpty &&
        result.value.isNotEmpty) {
      await ref.read(emergencyRepositoryProvider).upsert(
            label: result.label,
            value: result.value,
          );
      await syncAfterWrite(ref, context: context);
    }
  }
}

class _CareSnapshotTile extends StatelessWidget {
  const _CareSnapshotTile({
    required this.profile,
    required this.member,
    required this.onOpen,
  });

  final CareProfile profile;
  final NestMember? member;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final name = member?.name ?? context.l10n.familyMember;
    final allergies = profile.allergies.trim();
    final meds = profile.medications.trim();
    final lines = <String>[
      if (allergies.isNotEmpty) 'Allergies: $allergies',
      if (meds.isNotEmpty) 'Meds: $meds',
      if (profile.primaryDoctor.trim().isNotEmpty)
        'Doctor: ${profile.primaryDoctor.trim()}',
    ];

    return ListTile(
      onTap: onOpen,
      leading: member == null
          ? const CircleAvatar(
              backgroundColor: AppColors.dangerSoft,
              child: Icon(Icons.favorite_outline, color: AppColors.danger),
            )
          : MemberAvatar(
              initials: member!.initials,
              color: Color(member!.colorValue),
              size: 36,
            ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        lines.isEmpty
            ? '${MemberRoles.normalize(member?.role ?? '')} · tap to edit in Care'
            : lines.join('\n'),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12.5, height: 1.35),
      ),
      isThreeLine: lines.length > 1,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
    );
  }
}
