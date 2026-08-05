import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../data/db/app_database.dart';
import '../data/member_roles.dart';
import '../data/showcase_seed.dart';
import '../data/sync_controller.dart';
import '../data/telemetry.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/invite_family_sheet.dart';
import '../widgets/motion.dart';
import 'about_screen.dart';
import 'auth/reset_password_screen.dart';
import 'locator_screen.dart';
import 'privacy_screen.dart';
import 'timeline_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key, this.onOpenTab});

  final ValueChanged<int>? onOpenTab;

  Future<void> _loadShowcase(BuildContext context, WidgetRef ref) async {
    final nest = await ref.read(nestInfoProvider.future);
    final user = FirebaseAuth.instance.currentUser;
    if (nest == null || user == null) return;
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load showcase data?'),
        content: const Text(
          'Replaces nest content with polished App Store sample data '
          '(family, calendar, tasks, shopping, vault, and more), then syncs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Load'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Loading showcase data…')),
    );

    try {
      await ShowcaseSeedService(
        ref.read(databaseProvider),
      ).seed(nestId: nest.id, ownerMemberId: user.uid);
      if (!context.mounted) return;
      await syncAfterWrite(ref, context: context);
      ref.invalidate(nestInfoProvider);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Showcase data ready — open Home to review'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not load showcase: $e')),
      );
    }
  }

  Future<void> _editRole(
    BuildContext context,
    WidgetRef ref,
    NestMember member,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        final current = MemberRoles.normalize(member.role);
        final bottom = MediaQuery.viewPaddingOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Role for ${member.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Used for assignees, school activities, and family context.',
                style: TextStyle(color: AppColors.inkSecondary),
              ),
              const SizedBox(height: 12),
              for (final role in MemberRoles.all)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    role,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: role == current
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () => Navigator.pop(context, role),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || selected == MemberRoles.normalize(member.role)) {
      return;
    }
    await ref.read(memberRepositoryProvider).updateRole(member.id, selected);
    if (!context.mounted) return;
    await syncAfterWrite(ref, context: context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.name} is now $selected')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nest = ref.watch(nestInfoProvider).valueOrNull;
    final members = ref.watch(membersProvider).valueOrNull ?? [];
    final sync = ref.watch(syncControllerProvider);
    final tomorrowPreviewEnabled =
        ref.watch(tomorrowPreviewEnabledProvider).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: nestShellPageInsets(context),
          children: [
            Appear(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nest',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sync.isSyncing
                                ? 'Syncing…'
                                : sync.hasError
                                ? 'Sync needed · Retry'
                                : (sync.lastNote != null &&
                                      sync.lastNote!.isNotEmpty)
                                ? sync.lastNote!
                                : 'Last synced · ${formatLastSynced(sync.lastSyncAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sync.hasError
                                  ? AppColors.accentDeep
                                  : AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircleIconButton(
                      icon: sync.isSyncing
                          ? Icons.cloud_sync_rounded
                          : sync.hasError
                          ? Icons.cloud_off_outlined
                          : Icons.cloud_done_outlined,
                      background: AppColors.surfaceMuted,
                      foreground: AppColors.ink,
                      size: 38,
                      onTap: () {
                        if (sync.isSyncing) return;
                        ref
                            .read(syncControllerProvider.notifier)
                            .syncNow(context: context);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Appear(
              delay: const Duration(milliseconds: 40),
              child: NestCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (members.isEmpty)
                      const Expanded(
                        child: Text(
                          'Invite family with your code below',
                          style: TextStyle(color: AppColors.inkMuted),
                        ),
                      )
                    else
                      ...members.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: MemberAvatar(
                            initials: m.initials,
                            color: Color(m.colorValue),
                            size: 40,
                          ),
                        ),
                      ),
                    if (members.isNotEmpty) const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          nest?.name ?? 'Your nest',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          members.isEmpty
                              ? 'No members yet'
                              : '${members.length} member${members.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (members.isNotEmpty) ...[
              const SizedBox(height: 12),
              const SectionLabel('Family roles'),
              Appear(
                delay: const Duration(milliseconds: 55),
                child: NestCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < members.length; i++) ...[
                        ListTile(
                          onTap: () => _editRole(context, ref, members[i]),
                          leading: MemberAvatar(
                            initials: members[i].initials,
                            color: Color(members[i].colorValue),
                            size: 36,
                          ),
                          title: Text(
                            members[i].name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            MemberRoles.normalize(members[i].role),
                            style: const TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12.5,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.inkMuted,
                            size: 20,
                          ),
                        ),
                        if (i != members.length - 1)
                          const Divider(height: 1, indent: 68),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            if (nest != null) ...[
              const SizedBox(height: 6),
              Appear(
                delay: const Duration(milliseconds: 70),
                child: NestCard(
                  onTap: () => showInviteFamilySheet(
                    context,
                    inviteCode: nest.inviteCode,
                    nestName: nest.name,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.vpn_key_rounded,
                        color: AppColors.accentDeep,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Invite code',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.inkMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              nest.inviteCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Share',
                        style: TextStyle(
                          color: AppColors.accentDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const SectionLabel('Settings'),
            Appear(
              delay: const Duration(milliseconds: 100),
              child: NestCard(
                onTap: () => nestPush(
                  context,
                  TimelineScreen(onOpenTab: onOpenTab),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.history_rounded, color: AppColors.accentDeep),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Timeline',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Recent nest activity across the family',
                            style: TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.inkMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Appear(
              delay: const Duration(milliseconds: 105),
              child: NestCard(
                onTap: () => nestPush(context, const LocatorScreen()),
                child: const Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.accentDeep,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Locator',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Live nest map · opt-in last-known pins',
                            style: TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.inkMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Appear(
              delay: const Duration(milliseconds: 90),
              child: NestCard(
                onTap: () => showChangePasswordSheet(context, ref),
                child: const Row(
                  children: [
                    Icon(Icons.lock_reset_rounded, color: AppColors.accentDeep),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Change password',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Still signed in? Update it here',
                            style: TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.inkMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Appear(
              delay: const Duration(milliseconds: 100),
              child: NestCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.nights_stay_outlined,
                      color: AppColors.accentDeep,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tomorrow preview',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Quiet evening reminder for tomorrow’s bills, care, and school',
                            style: TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: tomorrowPreviewEnabled,
                      onChanged: (value) async {
                        await ref
                            .read(expenseRepositoryProvider)
                            .setTomorrowPreviewEnabled(value);
                        await ref
                            .read(notificationServiceProvider)
                            .rescheduleReminders();
                        await syncAfterWrite(ref, quiet: true);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Appear(
              delay: const Duration(milliseconds: 110),
              child: NestCard(
                onTap: () => nestPush(context, const PrivacyScreen()),
                child: const Row(
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: AppColors.accentDeep,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Privacy & data',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.inkMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Appear(
              delay: const Duration(milliseconds: 130),
              child: NestCard(
                onTap: () => nestPush(context, const AboutScreen()),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.accentDeep,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'About Nestly',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.inkMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (nest != null && (kDebugMode || kProfileMode)) ...[
              const SizedBox(height: 6),
              Appear(
                delay: const Duration(milliseconds: 150),
                child: NestCard(
                  onTap: () => _loadShowcase(context, ref),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.accentDeep,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Load App Store showcase',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Debug/profile only — not in App Store builds',
                              style: TextStyle(
                                color: AppColors.inkMuted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.inkMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (NestlyTelemetry.crashlyticsReady) ...[
                const SizedBox(height: 6),
                Appear(
                  delay: const Duration(milliseconds: 160),
                  child: NestCard(
                    onTap: () => FirebaseCrashlytics.instance.crash(),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.bug_report_outlined,
                          color: AppColors.danger,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Force test crash',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Verify Crashlytics in Firebase console',
                                style: TextStyle(
                                  color: AppColors.inkMuted,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.inkMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 6),
            Text(
              'Nestly is free for families — no paywall.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            if (nest != null) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => _confirmLeaveNest(context, ref, nest.name),
                icon: const Icon(
                  Icons.door_front_door_outlined,
                  color: AppColors.danger,
                ),
                label: const Text(
                  'Leave nest',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
            const SizedBox(height: 2),
            TextButton.icon(
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                ref.invalidate(nestInfoProvider);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
            TextButton.icon(
              onPressed: () => confirmAndDeleteAccount(context, ref),
              icon: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.danger,
              ),
              label: const Text(
                'Delete account',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLeaveNest(
    BuildContext context,
    WidgetRef ref,
    String nestName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave this nest?'),
        content: Text(
          'You’ll lose access to “$nestName” on this account. '
          'Other members keep the nest and all shared data. '
          'Your Nestly login stays — you can create or join another nest.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Leave nest'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(nestPrivacyServiceProvider).leaveNest();
      ref.invalidate(nestInfoProvider);
      ref.invalidate(membersProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Left nest — create or join another')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn’t leave nest: $e')),
      );
    }
  }
}
