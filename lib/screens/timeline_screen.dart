import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../data/timeline_nav.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'care_screen.dart';
import 'expenses_screen.dart';
import 'meals_screen.dart';
import 'school_screen.dart';
import 'vault_screen.dart';

final timelineFullProvider = StreamProvider<List<TimelineEvent>>((ref) {
  return ref.watch(timelineRepositoryProvider).watchRecent(limit: 120);
});

/// Full nest activity feed with module filters and deep links.
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key, this.onOpenTab});

  /// Opens AppShell tabs (1 calendar, 2 tasks, 3 shopping) after popping.
  final ValueChanged<int>? onOpenTab;

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  TimelineModule _filter = TimelineModule.all;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(timelineFullProvider);
    final events = async.valueOrNull ?? const <TimelineEvent>[];
    final filtered = _filter == TimelineModule.all
        ? events
        : events
            .where((e) => classifyTimelineMessage(e.message) == _filter)
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Timeline')),
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
                    label: module.label,
                    selected: _filter == module,
                    onTap: () => setState(() => _filter = module),
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
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No activity in this filter yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.inkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final event = filtered[index];
                          final module =
                              classifyTimelineMessage(event.message);
                          return NestCard(
                            onTap: () => _openModule(context, module),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ModuleIcon(module: module),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.message,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${event.memberName} · ${_relative(event.createdAt)} · ${module.label}',
                                        style: const TextStyle(
                                          color: AppColors.inkMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.inkMuted,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _openModule(BuildContext context, TimelineModule module) {
    switch (module) {
      case TimelineModule.all:
        return;
      case TimelineModule.tasks:
        _openTabOrStay(context, 2);
        return;
      case TimelineModule.shopping:
        _openTabOrStay(context, 3);
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

  void _openTabOrStay(BuildContext context, int tab) {
    final open = widget.onOpenTab;
    if (open == null) return;
    Navigator.of(context).pop();
    open(tab);
  }

  String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(dt);
  }
}

class _ModuleIcon extends StatelessWidget {
  const _ModuleIcon({required this.module});

  final TimelineModule module;

  @override
  Widget build(BuildContext context) {
    final (icon, tone) = switch (module) {
      TimelineModule.tasks => (Icons.checklist_rounded, AppColors.mint),
      TimelineModule.shopping => (Icons.shopping_bag_rounded, AppColors.tileOrange),
      TimelineModule.care => (Icons.favorite_rounded, AppColors.mint),
      TimelineModule.meals => (Icons.restaurant_rounded, AppColors.tileTeal),
      TimelineModule.vault => (Icons.folder_rounded, AppColors.tilePink),
      TimelineModule.school => (Icons.school_rounded, AppColors.accent),
      TimelineModule.other => (Icons.receipt_long_rounded, AppColors.tileYellow),
      TimelineModule.all => (Icons.history_rounded, AppColors.surfaceMuted),
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: AppColors.ink),
    );
  }
}
