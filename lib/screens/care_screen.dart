import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/db/app_database.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/sheet_form.dart';

class CareScreen extends ConsumerWidget {
  const CareScreen({super.key});

  static const _categories = ['Home', 'Pet', 'Car'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(careItemsProvider);
    final now = DateTime.now();
    final endToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Care'),
        actions: [
          IconButton(
            onPressed: () => _showAdd(context, ref),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Could not load care items.')),
        data: (items) {
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
                  'Recurring pet, home, and car upkeep — mark done to roll the next due date.',
                  style: TextStyle(color: AppColors.inkSecondary, height: 1.4),
                ),
              ),
              const SizedBox(height: 6),
              if (items.isEmpty)
                NestCard(
                  onTap: () => _showAdd(context, ref),
                  child: const Text(
                    'No care schedules yet. Tap to add one.',
                    style: TextStyle(color: AppColors.inkMuted),
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
                            highlight: true,
                            onDone: () async {
                              await ref
                                  .read(careRepositoryProvider)
                                  .markDone(due[i]);
                              try {
                                await ref.read(syncServiceProvider).syncAll();
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
                            highlight: false,
                            onDone: () async {
                              await ref
                                  .read(careRepositoryProvider)
                                  .markDone(upcoming[i]);
                              try {
                                await ref.read(syncServiceProvider).syncAll();
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

  Future<void> _showAdd(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<
        ({String title, String category, int cadence})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        var category = 'Home';
        var cadence = 7;
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
                      decoration: const InputDecoration(
                        hintText: 'e.g. Change HVAC filter',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final cat in _categories)
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
                            onSelected: (_) =>
                                setModal(() => category = cat),
                          ),
                      ],
                    ),
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
          );
      try {
        await ref.read(syncServiceProvider).syncAll();
      } catch (_) {}
    }
  }
}

class _CareRow extends StatelessWidget {
  const _CareRow({
    required this.item,
    required this.highlight,
    required this.onDone,
    required this.onDelete,
  });

  final CareItem item;
  final bool highlight;
  final VoidCallback onDone;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        item.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${item.category} · due ${DateFormat.MMMd().format(item.nextDueAt)}'
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
