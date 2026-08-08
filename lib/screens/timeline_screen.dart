import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/enums.dart';
import '../data/member_roles.dart';
import '../data/repositories.dart';
import '../data/timeline_nav.dart';
import '../providers/providers.dart';
import '../state/timeline_ui.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/first_run_empty_card.dart';
import '../widgets/motion.dart';
import 'care_screen.dart';
import 'expenses_screen.dart';
import 'meals_screen.dart';
import 'school_screen.dart';
import 'vault_screen.dart';
import '../l10n/l10n_ext.dart';

final timelineFullProvider = StreamProvider<List<TimelineEvent>>((ref) {
  return ref.watch(timelineRepositoryProvider).watchRecent(limit: 120);
});

/// Full nest activity feed with module filters and deep links.
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key, this.onOpenTab});

  /// Opens AppShell tabs (1 calendar, 2 tasks, 3 shopping) after popping.
  final ValueChanged<int>? onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(timelineUiProvider);
    final uiCtrl = ref.read(timelineUiProvider.notifier);
    final async = ref.watch(timelineFullProvider);
    final events = async.valueOrNull ?? const <TimelineEvent>[];
    final filtered = ui.filter == TimelineModule.all
        ? events
        : events
            .where(
              (e) =>
                  classifyTimeline(kind: e.kind, message: e.message) ==
                  ui.filter,
            )
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.screenTimeline)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              children: [
                for (final module in TimelineModule.values) ...[
                  SoftPill(
                    label: module.display(context.l10n),
                    selected: ui.filter == module,
                    onTap: () => uiCtrl.setFilter(module),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: async.isLoading && events.isEmpty
                ? const Center(child: CircularProgressIndicator.adaptive())
                : filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: FirstRunEmptyCard(
                          icon: Icons.history_rounded,
                          color: AppColors.tileTeal,
                          title: events.isEmpty
                              ? context.l10n.emptyTimelineTitle
                              : context.l10n.emptyTimelineFilter,
                          body: events.isEmpty
                              ? context.l10n.emptyTimelineBody
                              : context.l10n.emptyTimelineFilterHint,
                          actionLabel: events.isEmpty
                              ? context.l10n.timelineBackHome
                              : context.l10n.timelineShowAll,
                          onAction: () {
                            if (events.isEmpty) {
                              Navigator.of(context).pop();
                              onOpenTab?.call(0);
                            } else {
                              uiCtrl.showAll();
                            }
                          },
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final event = filtered[index];
                          return _TimelineEventCard(
                            event: event,
                            onOpenTab: onOpenTab,
                          );
                        },
                      ),
          ),
          const _TimelineComposer(),
        ],
      ),
    );
  }
}

String _kindLabel(String kind, AppLocalizations l10n) {
  return switch (TimelineKind.parse(kind)) {
    TimelineKind.announcement => l10n.timelineAnnouncementLabel,
    TimelineKind.post => l10n.timelinePostLabel,
    TimelineKind.comment => l10n.timelineCommentLabel,
    TimelineKind.activity => l10n.timelineActivityLabel,
  };
}

class _TimelineEventCard extends ConsumerStatefulWidget {
  const _TimelineEventCard({required this.event, this.onOpenTab});

  final TimelineEvent event;
  final ValueChanged<int>? onOpenTab;

  @override
  ConsumerState<_TimelineEventCard> createState() => _TimelineEventCardState();
}

class _TimelineEventCardState extends ConsumerState<_TimelineEventCard> {
  bool _commentsExpanded = false;
  final _commentController = TextEditingController();
  bool _commenting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty || _commenting) return;
    final (memberId, memberName) = _resolveActor(ref);
    final members = ref.read(membersProvider).valueOrNull ?? const [];
    setState(() => _commenting = true);
    try {
      await ref.read(timelineRepositoryProvider).addComment(
            parentId: widget.event.id,
            body: body,
            memberId: memberId,
            memberName: memberName,
            members: members,
          );
      _commentController.clear();
      if (!_commentsExpanded && mounted) {
        setState(() => _commentsExpanded = true);
      }
    } finally {
      if (mounted) setState(() => _commenting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final l10n = context.l10n;
    final repo = ref.watch(timelineRepositoryProvider);
    final (memberId, _) = _resolveActor(ref);
    final module = classifyTimeline(kind: event.kind, message: event.message);
    final isPost = isTimelinePostKind(event.kind);
    final isAnnouncement =
        TimelineKind.parse(event.kind) == TimelineKind.announcement;
    final isTopLevel = event.parentId == null;

    return NestCard(
      onTap: isPost
          ? null
          : () => _openModule(context, module, widget.onOpenTab),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: DecoratedBox(
        decoration: isAnnouncement
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              )
            : const BoxDecoration(),
        child: Padding(
          padding: isAnnouncement
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
              : EdgeInsets.zero,
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ModuleIcon(
                module: module,
                isPost: isPost,
                isAnnouncement: isAnnouncement,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPost)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            if (event.pinned)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.push_pin_rounded,
                                  size: 14,
                                  color: AppColors.accentDeep.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                              ),
                            Text(
                              _kindLabel(event.kind, l10n),
                              style: TextStyle(
                                color: isAnnouncement
                                    ? AppColors.accentDeep
                                    : AppColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!isPost && event.pinned)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.push_pin_rounded,
                              size: 14,
                              color: AppColors.accentDeep.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.timelinePinnedLabel,
                              style: TextStyle(
                                color: AppColors.accentDeep.withValues(alpha: 0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      event.message,
                      style: TextStyle(
                        fontWeight: isPost ? FontWeight.w600 : FontWeight.w700,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.memberName} · ${_relative(event.createdAt, l10n)} · ${isPost ? _kindLabel(event.kind, l10n) : module.display(l10n)}',
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isTopLevel)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.inkMuted,
                    size: 20,
                  ),
                  onSelected: (value) async {
                    if (value == 'pin') {
                      await repo.setPinned(event.id, true);
                    } else if (value == 'unpin') {
                      await repo.setPinned(event.id, false);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!event.pinned)
                      PopupMenuItem(
                        value: 'pin',
                        child: Text(l10n.timelinePinAction),
                      ),
                    if (event.pinned)
                      PopupMenuItem(
                        value: 'unpin',
                        child: Text(l10n.timelineUnpinAction),
                      ),
                  ],
                )
              else if (!isPost)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.inkMuted,
                ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<TimelineReaction>>(
            stream: repo.watchReactions(event.id),
            builder: (context, snapshot) {
              final reactions = snapshot.data ?? const <TimelineReaction>[];
              final counts = <String, int>{};
              TimelineReaction? myReaction;
              for (final reaction in reactions) {
                counts[reaction.emoji] = (counts[reaction.emoji] ?? 0) + 1;
                if (reaction.memberId == memberId) {
                  myReaction = reaction;
                }
              }
              return Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final emoji in TimelineRepository.reactionEmojis)
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      label: Text(
                        counts.containsKey(emoji)
                            ? '$emoji ${counts[emoji]}'
                            : emoji,
                        style: const TextStyle(fontSize: 13),
                      ),
                      backgroundColor: myReaction?.emoji == emoji
                          ? AppColors.accent.withValues(alpha: 0.18)
                          : AppColors.background,
                      side: BorderSide.none,
                      onPressed: () => repo.toggleReaction(
                        eventId: event.id,
                        memberId: memberId,
                        emoji: emoji,
                      ),
                    ),
                ],
              );
            },
          ),
          StreamBuilder<List<TimelineEvent>>(
            stream: repo.watchComments(event.id),
            builder: (context, snapshot) {
              final comments = snapshot.data ?? const <TimelineEvent>[];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => setState(
                        () => _commentsExpanded = !_commentsExpanded,
                      ),
                      child: Text(
                        l10n.timelineCommentsToggle(comments.length),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (_commentsExpanded) ...[
                    for (final comment in comments)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                comment.memberName.isNotEmpty
                                    ? comment.memberName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.memberName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    comment.message,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                  Text(
                                    _relative(comment.createdAt, l10n),
                                    style: const TextStyle(
                                      color: AppColors.inkMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            minLines: 1,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: l10n.timelineCommentHint,
                              filled: true,
                              fillColor: AppColors.background,
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onSubmitted: (_) => _submitComment(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        FilledButton(
                          onPressed: _commenting ? null : _submitComment,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: _commenting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.timelineCommentButton),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
          ),
        ),
      ),
    );
  }
}

class _TimelineComposer extends ConsumerStatefulWidget {
  const _TimelineComposer();

  @override
  ConsumerState<_TimelineComposer> createState() => _TimelineComposerState();
}

class _TimelineComposerState extends ConsumerState<_TimelineComposer> {
  final _controller = TextEditingController();
  bool _posting = false;
  bool _announcementMode = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _posting) return;
    final (memberId, memberName) = _resolveActor(ref);
    final members = ref.read(membersProvider).valueOrNull ?? const [];
    final repo = ref.read(timelineRepositoryProvider);
    setState(() => _posting = true);
    try {
      if (_announcementMode) {
        await repo.addAnnouncement(
          body: body,
          memberId: memberId,
          memberName: memberName,
          members: members,
        );
      } else {
        await repo.addPost(
          body: body,
          memberId: memberId,
          memberName: memberName,
          members: members,
        );
      }
      _controller.clear();
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final members = ref.watch(membersProvider).valueOrNull ?? const [];
    final actorRole = _resolveActorRole(ref, members);
    final canAnnounce = MemberRoles.isAdultLike(actorRole);

    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (canAnnounce)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(l10n.timelinePostLabel),
                        selected: !_announcementMode,
                        onSelected: (_) =>
                            setState(() => _announcementMode = false),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(l10n.timelineAnnouncementLabel),
                        selected: _announcementMode,
                        onSelected: (_) =>
                            setState(() => _announcementMode = true),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: _announcementMode
                        ? l10n.timelineAnnouncementHint
                        : l10n.timelinePostHint,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _posting ? null : _submit,
                child: _posting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                      )
                    : Text(
                        _announcementMode
                            ? l10n.timelineAnnounceButton
                            : l10n.timelinePostButton,
                      ),
              ),
            ],
          ),
            ],
          ),
        ),
      ),
    );
  }
}

(String id, String name) _resolveActor(WidgetRef ref) {
  final user = FirebaseAuth.instance.currentUser;
  final members = ref.read(membersProvider).valueOrNull ?? const [];
  if (user != null) {
    for (final member in members) {
      if (member.id == user.uid) {
        return (member.id, member.name);
      }
    }
    final display = user.displayName?.trim();
    if (display != null && display.isNotEmpty) {
      return (user.uid, display);
    }
  }
  if (members.isNotEmpty) {
    return (members.first.id, members.first.name);
  }
  return ('', 'Family');
}

String _resolveActorRole(WidgetRef ref, List<NestMember> members) {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    for (final member in members) {
      if (member.id == user.uid) {
        return member.role;
      }
    }
  }
  if (members.isNotEmpty) {
    return members.first.role;
  }
  return MemberRoles.member;
}

void _openModule(
  BuildContext context,
  TimelineModule module,
  ValueChanged<int>? onOpenTab,
) {
  switch (module) {
    case TimelineModule.all:
    case TimelineModule.family:
      return;
    case TimelineModule.tasks:
      _openTabOrStay(context, 2, onOpenTab);
      return;
    case TimelineModule.shopping:
      _openTabOrStay(context, 3, onOpenTab);
      return;
    case TimelineModule.care:
      nestPush(context, const CareScreen());
      return;
    case TimelineModule.meals:
      nestPush(context, const MealsScreen());
      return;
    case TimelineModule.vault:
      nestPush(context, const VaultScreen());
      return;
    case TimelineModule.school:
      nestPush(context, const SchoolScreen());
      return;
    case TimelineModule.other:
      nestPush(context, const ExpensesScreen());
      return;
  }
}

void _openTabOrStay(
  BuildContext context,
  int tab,
  ValueChanged<int>? onOpenTab,
) {
  if (onOpenTab == null) return;
  Navigator.of(context).pop();
  onOpenTab(tab);
}

String _relative(DateTime dt, AppLocalizations l10n) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return l10n.syncJustNow;
  if (diff.inMinutes < 60) return l10n.syncMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.syncHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.syncDaysAgo(diff.inDays);
  return DateFormat.MMMd().format(dt);
}

class _ModuleIcon extends StatelessWidget {
  const _ModuleIcon({
    required this.module,
    this.isPost = false,
    this.isAnnouncement = false,
  });

  final TimelineModule module;
  final bool isPost;
  final bool isAnnouncement;

  @override
  Widget build(BuildContext context) {
    if (isAnnouncement) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.accentDeep.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.campaign_rounded,
          size: 18,
          color: AppColors.accentDeep,
        ),
      );
    }
    final (icon, tone) = switch (module) {
      TimelineModule.tasks => (Icons.checklist_rounded, AppColors.mint),
      TimelineModule.shopping =>
        (Icons.shopping_bag_rounded, AppColors.tileOrange),
      TimelineModule.care => (Icons.favorite_rounded, AppColors.mint),
      TimelineModule.meals => (Icons.restaurant_rounded, AppColors.tileTeal),
      TimelineModule.vault => (Icons.folder_rounded, AppColors.tilePink),
      TimelineModule.school => (Icons.school_rounded, AppColors.accent),
      TimelineModule.family => (Icons.forum_rounded, AppColors.tileTeal),
      TimelineModule.other =>
        (Icons.receipt_long_rounded, AppColors.tileYellow),
      TimelineModule.all => (Icons.history_rounded, AppColors.surfaceMuted),
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: isPost ? 0.75 : 0.55),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: AppColors.ink),
    );
  }
}
