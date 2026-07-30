import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/first_run_empty_card.dart';
import '../widgets/shimmer.dart';
import '../data/sync_controller.dart';

const _shopCategories = [
  'Produce',
  'Dairy',
  'Meat',
  'Bakery',
  'Pantry',
  'Frozen',
  'Household',
  'General',
];

const _qtyPresets = ['1', '2', '3', '6', '12', '1 kg', '2 L'];

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  final _addController = TextEditingController();
  final _addFocus = FocusNode();

  @override
  void dispose() {
    _addController.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final name = _addController.text.trim();
    if (name.isEmpty) return;
    await ref.read(shoppingRepositoryProvider).addItem(name: name);
    _addController.clear();
    await syncAfterWrite(ref, context: context);
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(shoppingItemsProvider);
    final members = ref.watch(membersProvider).valueOrNull ?? const [];

    ref.listen(pendingAddProvider, (prev, next) {
      if (next == PendingAdd.shopping) {
        ref.read(pendingAddProvider.notifier).state = PendingAdd.none;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _addFocus.requestFocus();
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
              child: Text(
                'Groceries',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            Expanded(
              child: itemsAsync.when(
                loading: () => const NestLoadingSkeleton(itemCount: 4),
                error: (error, _) => const Center(
                  child: Text('Could not load list. Try again later.'),
                ),
                data: (items) {
                  final categories = <String>[];
                  for (final item in items) {
                    if (!categories.contains(item.category)) {
                      categories.add(item.category);
                    }
                  }
                  final left = items.where((i) => !i.done).length;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 72),
                    children: [
                      NestCard(
                        color: AppColors.mint,
                        bordered: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            if (members.isEmpty)
                              const Text(
                                'Shared list',
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            else
                              ...members
                                  .take(4)
                                  .map(
                                    (m) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: MemberAvatar(
                                        initials: m.initials,
                                        color: Color(m.colorValue),
                                        size: 32,
                                      ),
                                    ),
                                  ),
                            const Spacer(),
                            SoftPill(label: '$left left', selected: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      _SuggestionsStrip(
                        onAdded: () async {
                          await syncAfterWrite(ref, context: context);
                        },
                      ),
                      const SizedBox(height: 6),
                      NestCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        child: TextField(
                          controller: _addController,
                          focusNode: _addFocus,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addItem(),
                          decoration: InputDecoration(
                            hintText: 'Add an item',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            prefixIcon: IconButton(
                              onPressed: _addItem,
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppColors.ink,
                              ),
                            ),
                            hintStyle: const TextStyle(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (items.isEmpty)
                        FirstRunEmptyCard(
                          icon: Icons.shopping_bag_outlined,
                          color: AppColors.tileOrange,
                          title: 'Start the grocery list',
                          body:
                              'Add milk, eggs, or anything else — type above or tap to focus the add field.',
                          actionLabel: 'Add an item',
                          onAction: () => _addFocus.requestFocus(),
                        )
                      else
                        for (final category in categories) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 4,
                              bottom: 8,
                              top: 4,
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          NestCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                ...() {
                                  final categoryItems = items
                                      .where((i) => i.category == category)
                                      .toList();
                                  return [
                                    for (
                                      var i = 0;
                                      i < categoryItems.length;
                                      i++
                                    ) ...[
                                      _ShopRow(
                                        item: categoryItems[i],
                                        onToggle: () async {
                                          await ref
                                              .read(shoppingRepositoryProvider)
                                              .toggleDone(categoryItems[i]);
                                          await syncAfterWrite(
                                            ref,
                                            context: context,
                                          );
                                        },
                                        onEdit: () => showItemSheet(
                                          context,
                                          ref,
                                          existing: categoryItems[i],
                                        ),
                                      ),
                                      if (i != categoryItems.length - 1)
                                        const Divider(height: 1, indent: 52),
                                    ],
                                  ];
                                }(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showItemSheet(
    BuildContext context,
    WidgetRef ref, {
    required ShoppingItem existing,
  }) async {
    final result =
        await showModalBottomSheet<
          ({String name, String category, String qty, bool deleteItem})
        >(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          builder: (context) => _ItemSheet(existing: existing),
        );

    if (result == null) return;

    if (result.deleteItem) {
      await ref.read(shoppingRepositoryProvider).deleteItem(existing.id);
      await syncAfterWrite(ref, context: context);
      return;
    }

    if (result.name.isEmpty) return;

    await ref
        .read(shoppingRepositoryProvider)
        .updateItem(
          id: existing.id,
          name: result.name,
          category: result.category,
          qty: result.qty,
        );
    await syncAfterWrite(ref, context: context);
  }
}

class _ItemSheet extends StatefulWidget {
  const _ItemSheet({required this.existing});

  final ShoppingItem existing;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  late final TextEditingController _name;
  late final TextEditingController _qty;
  late String _category;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing.name);
    _qty = TextEditingController(text: widget.existing.qty);
    _category = widget.existing.category;
  }

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    super.dispose();
  }

  void _submit({bool deleteItem = false}) {
    final name = _name.text.trim();
    if (!deleteItem && name.isEmpty) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context, (
      name: name,
      category: _category,
      qty: _qty.text.trim().isEmpty ? '1' : _qty.text.trim(),
      deleteItem: deleteItem,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final cats = {
      ..._shopCategories,
      if (!_shopCategories.contains(_category)) _category,
    }.toList();

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
          const Text(
            'Edit item',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'Item name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _qty,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Qty (e.g. 2, 1 kg)'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final q in _qtyPresets)
                SoftPill(
                  label: q,
                  selected: _qty.text.trim() == q,
                  onTap: () => setState(() => _qty.text = q),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final cat in cats)
                SoftPill(
                  label: cat,
                  selected: _category == cat,
                  onTap: () => setState(() => _category = cat),
                ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: _submit, child: const Text('Save')),
          TextButton(
            onPressed: () => _submit(deleteItem: true),
            child: const Text(
              'Delete item',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopRow extends StatelessWidget {
  const _ShopRow({
    required this.item,
    required this.onToggle,
    required this.onEdit,
  });

  final ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  item.done
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: item.done ? AppColors.ink : AppColors.inkMuted,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: item.done ? TextDecoration.lineThrough : null,
                      color: item.done ? AppColors.inkMuted : AppColors.ink,
                    ),
                  ),
                  if (item.qty != '1')
                    Text(
                      item.qty,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.inkMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsStrip extends ConsumerWidget {
  const _SuggestionsStrip({required this.onAdded});

  final VoidCallback onAdded;

  static String _restockLabel(GroceryHabit habit) {
    final overdue =
        DateTime.now().difference(habit.lastBoughtAt).inDays -
        habit.cadenceDays;
    if (overdue >= 2) return '${habit.name} · ${overdue}d overdue';
    if (overdue >= 0) return '${habit.name} · due now';
    return '${habit.name} · ~${habit.cadenceDays}d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions =
        ref.watch(grocerySuggestionsProvider).valueOrNull ?? const [];
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return NestCard(
      color: AppColors.tileOrange,
      bordered: false,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.replay_rounded, size: 18, color: AppColors.ink),
              SizedBox(width: 6),
              Text(
                'Restock',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Based on what you usually buy',
            style: TextStyle(
              color: AppColors.inkSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final habit in suggestions) ...[
                  SoftPill(
                    label: '+ ${_restockLabel(habit)}',
                    background: Colors.white,
                    foreground: AppColors.ink,
                    onTap: () async {
                      await ref
                          .read(shoppingRepositoryProvider)
                          .addSuggestion(habit);
                      onAdded();
                    },
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
