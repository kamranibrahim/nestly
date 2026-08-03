import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/sync_controller.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/first_run_empty_card.dart';
import '../widgets/shimmer.dart';

const _shopCategories = [
  'Produce',
  'Dairy',
  'Meat',
  'Bakery',
  'Pantry',
  'Frozen',
  'Household',
  'General',
  'Meals',
];

const _qtyPresets = ['1', '2', '3', '6', '12', '1 kg', '2 L'];

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  final _addController = TextEditingController();
  final _searchController = TextEditingController();
  final _addFocus = FocusNode();
  String _addCategory = 'General';
  String _filterCategory = 'All';
  String _searchQuery = '';
  bool _boughtExpanded = false;

  @override
  void dispose() {
    _addController.dispose();
    _searchController.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final name = _addController.text.trim();
    if (name.isEmpty) return;
    await ref
        .read(shoppingRepositoryProvider)
        .addItem(name: name, category: _addCategory);
    _addController.clear();
    await syncAfterWrite(ref, context: context);
  }

  Future<void> _clearBought() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear bought items?'),
        content: const Text(
          'Removes checked-off groceries from this list. You can still restock habits later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final cleared = await ref.read(shoppingRepositoryProvider).clearCompleted();
    await syncAfterWrite(ref, context: context);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cleared == 0
              ? 'Nothing to clear'
              : 'Cleared $cleared bought item${cleared == 1 ? '' : 's'}',
        ),
      ),
    );
  }

  List<ShoppingItem> _filtered(List<ShoppingItem> items) {
    final q = _searchQuery.trim().toLowerCase();
    return items.where((item) {
      if (_filterCategory != 'All' && item.category != _filterCategory) {
        return false;
      }
      if (q.isEmpty) return true;
      return item.name.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q);
    }).toList();
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
              padding: const EdgeInsets.fromLTRB(10, 2, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Groceries',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Clear bought',
                    onPressed: _clearBought,
                    icon: const Icon(Icons.cleaning_services_outlined),
                  ),
                ],
              ),
            ),
            Expanded(
              child: itemsAsync.when(
                loading: () => const NestLoadingSkeleton(itemCount: 4),
                error: (error, _) => const Center(
                  child: Text('Could not load list. Try again later.'),
                ),
                data: (items) {
                  final filtered = _filtered(items);
                  final openItems = filtered
                      .where((i) => !i.done)
                      .toList(growable: false);
                  final boughtItems = filtered
                      .where((i) => i.done)
                      .toList(growable: false);
                  final categories = <String>[];
                  for (final item in openItems) {
                    if (!categories.contains(item.category)) {
                      categories.add(item.category);
                    }
                  }
                  final left = items.where((i) => !i.done).length;
                  final boughtCount = items.where((i) => i.done).length;

                  return ListView(
                    padding: nestShellPageInsets(context, top: 6),
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
                            if (boughtCount > 0) ...[
                              const SizedBox(width: 6),
                              SoftPill(label: '$boughtCount bought'),
                            ],
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
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
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
                            const SizedBox(height: 4),
                            const Text(
                              'Category',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.inkMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final cat in _shopCategories)
                                  SoftPill(
                                    label: cat,
                                    selected: _addCategory == cat,
                                    onTap: () =>
                                        setState(() => _addCategory = cat),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      NestCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          decoration: const InputDecoration(
                            hintText: 'Search list',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            prefixIcon: Icon(Icons.search_rounded),
                            hintStyle: TextStyle(color: AppColors.inkMuted),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            SoftPill(
                              label: 'All',
                              selected: _filterCategory == 'All',
                              onTap: () =>
                                  setState(() => _filterCategory = 'All'),
                            ),
                            const SizedBox(width: 6),
                            for (final cat in _shopCategories) ...[
                              SoftPill(
                                label: cat,
                                selected: _filterCategory == cat,
                                onTap: () =>
                                    setState(() => _filterCategory = cat),
                              ),
                              const SizedBox(width: 6),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (items.isEmpty)
                        FirstRunEmptyCard(
                          icon: Icons.shopping_bag_outlined,
                          color: AppColors.tileOrange,
                          title: 'Start the grocery list',
                          body:
                              'Add milk, eggs, or anything else — pick a category, then tap +.',
                          actionLabel: 'Add an item',
                          onAction: () => _addFocus.requestFocus(),
                        )
                      else if (openItems.isEmpty && boughtItems.isEmpty)
                        const NestCard(
                          child: Text(
                            'No items match this search or filter.',
                            style: TextStyle(
                              color: AppColors.inkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else ...[
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
                                  final categoryItems = openItems
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
                        if (boughtItems.isNotEmpty) ...[
                          NestCard(
                            onTap: () => setState(
                              () => _boughtExpanded = !_boughtExpanded,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _boughtExpanded
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  color: AppColors.inkMuted,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Bought (${boughtItems.length})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _clearBought,
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          ),
                          if (_boughtExpanded) ...[
                            const SizedBox(height: 6),
                            NestCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  for (
                                    var i = 0;
                                    i < boughtItems.length;
                                    i++
                                  ) ...[
                                    _ShopRow(
                                      item: boughtItems[i],
                                      onToggle: () async {
                                        await ref
                                            .read(shoppingRepositoryProvider)
                                            .toggleDone(boughtItems[i]);
                                        await syncAfterWrite(
                                          ref,
                                          context: context,
                                        );
                                      },
                                      onEdit: () => showItemSheet(
                                        context,
                                        ref,
                                        existing: boughtItems[i],
                                      ),
                                    ),
                                    if (i != boughtItems.length - 1)
                                      const Divider(height: 1, indent: 52),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
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
                  Text(
                    item.qty == '1'
                        ? item.category
                        : '${item.qty} · ${item.category}',
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
    final cat = habit.category.trim().isEmpty ? 'General' : habit.category;
    final when = overdue >= 2
        ? '${overdue}d overdue'
        : overdue >= 0
        ? 'due now'
        : '~${habit.cadenceDays}d';
    return '${habit.name} · $cat · $when';
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
