import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/enums.dart';
import '../data/sync_controller.dart';
import '../providers/providers.dart';
import '../state/shopping_ui.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/first_run_empty_card.dart';
import '../widgets/shimmer.dart';
import '../l10n/l10n_ext.dart';

const _qtyPresets = ['1', '2', '3', '6', '12', '1 kg', '2 L'];

String _shoppingCategoryLabel(AppLocalizations l10n, String category) {
  for (final cat in ShoppingCategory.listValues) {
    if (cat.label == category) return cat.display(l10n);
  }
  return category;
}

class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  Future<void> _addItem(
    BuildContext context,
    WidgetRef ref,
    ShoppingUiController controller,
    String category,
  ) async {
    final name = controller.submitName();
    if (name == null) return;
    await ref
        .read(shoppingRepositoryProvider)
        .addItem(name: name, category: category);
    controller.clearAddField();
    await syncAfterWrite(ref, context: context);
  }

  Future<void> _clearBought(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.clearBoughtTitle),
        content: Text(context.l10n.shopClearBoughtBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.clearBoughtAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final cleared = await ref.read(shoppingRepositoryProvider).clearCompleted();
    await syncAfterWrite(ref, context: context);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cleared == 0
              ? context.l10n.shopNothingToClear
              : context.l10n.shopClearedBought(cleared),
        ),
      ),
    );
  }

  List<ShoppingItem> _filtered(List<ShoppingItem> items, ShoppingUiState ui) {
    final q = ui.searchQuery.trim().toLowerCase();
    return items.where((item) {
      if (!ui.filterCategory.isAll &&
          item.category != ui.filterCategory.label) {
        return false;
      }
      if (q.isEmpty) return true;
      return item.name.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingItemsProvider);
    final members = ref.watch(membersProvider).valueOrNull ?? const [];
    final ui = ref.watch(shoppingUiProvider);
    final controller = ref.read(shoppingUiProvider.notifier);

    ref.listen(pendingAddProvider, (prev, next) {
      if (next == PendingAdd.shopping) {
        ref.read(pendingAddProvider.notifier).state = PendingAdd.none;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) controller.addFocus.requestFocus();
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
                      context.l10n.screenShopping,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.clearBought,
                    onPressed: () => _clearBought(context, ref),
                    icon: const Icon(Icons.cleaning_services_outlined),
                  ),
                ],
              ),
            ),
            Expanded(
              child: itemsAsync.when(
                loading: () => const NestLoadingSkeleton(itemCount: 4),
                error: (error, _) => Center(
                  child: Text(context.l10n.loadFailedShopping),
                ),
                data: (items) {
                  final filtered = _filtered(items, ui);
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
                              Text(
                                context.l10n.shopSharedList,
                                style: const TextStyle(
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
                            SoftPill(
                              label: context.l10n.shopLeftCount(left),
                              selected: true,
                            ),
                            if (boughtCount > 0) ...[
                              const SizedBox(width: 6),
                              SoftPill(
                                label: context.l10n.shopBoughtCount(boughtCount),
                              ),
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
                        bordered: true,
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: controller.addController,
                              focusNode: controller.addFocus,
                              textInputAction: TextInputAction.done,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _addItem(
                                context,
                                ref,
                                controller,
                                ui.addCategory.label,
                              ),
                              decoration: InputDecoration(
                                hintText: context.l10n.hintAddItem,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                prefixIcon: const Icon(Icons.add_rounded),
                                suffixIcon: IconButton(
                                  tooltip: context.l10n.addToList,
                                  onPressed: () => _addItem(
                                    context,
                                    ref,
                                    controller,
                                    ui.addCategory.label,
                                  ),
                                  icon: const Icon(Icons.arrow_upward_rounded),
                                ),
                              ),
                            ),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final cat
                                in ShoppingCategory.listValues)
                                  SoftPill(
                                    label: cat.display(context.l10n),
                                    selected: ui.addCategory == cat,
                                    onTap: () =>
                                        controller.setAddCategory(cat),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      NestCard(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextField(
                          controller: controller.searchController,
                          onChanged: controller.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: context.l10n.searchList,
                            border: InputBorder.none,
                            prefixIcon: const Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            SoftPill(
                              label: ShoppingListFilter.all.display(context.l10n),
                              selected: ui.filterCategory.isAll,
                              onTap: () => controller.setFilterCategory(
                                ShoppingListFilter.all,
                              ),
                            ),
                            const SizedBox(width: 6),
                            for (final cat in ShoppingCategory.listValues) ...[
                              SoftPill(
                                label: cat.display(context.l10n),
                                selected: ui.filterCategory ==
                                    ShoppingListFilter.fromCategory(cat),
                                onTap: () => controller.setFilterCategory(
                                  ShoppingListFilter.fromCategory(cat),
                                ),
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
                          title: context.l10n.emptyShoppingTitle,
                          body: context.l10n.emptyShoppingBody,
                          actionLabel: context.l10n.emptyShoppingAction,
                          onAction: () => controller.addFocus.requestFocus(),
                        )
                      else if (openItems.isEmpty && boughtItems.isEmpty)
                        NestCard(
                          child: Text(
                            context.l10n.shopNoMatch,
                            style: const TextStyle(
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
                              _shoppingCategoryLabel(context.l10n, category),
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
                            onTap: controller.toggleBoughtExpanded,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  ui.boughtExpanded
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
                                  onPressed: () => _clearBought(context, ref),
                                  child: Text(context.l10n.commonClear),
                                ),
                              ],
                            ),
                          ),
                          if (ui.boughtExpanded) ...[
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
      ...ShoppingCategory.listValues.map((c) => c.label),
      if (!ShoppingCategory.listValues.any((c) => c.label == _category))
        _category,
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
          Text(
            context.l10n.shopEditItem,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(hintText: context.l10n.hintItemName),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _qty,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: context.l10n.hintQty),
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
          Text(context.l10n.commonCategory, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final cat in cats)
                SoftPill(
                  label: _shoppingCategoryLabel(context.l10n, cat),
                  selected: _category == cat,
                  onTap: () => setState(() => _category = cat),
                ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: _submit, child: Text(context.l10n.commonSave)),
          TextButton(
            onPressed: () => _submit(deleteItem: true),
            child: Text(
              context.l10n.shopDeleteItem,
              style: const TextStyle(color: AppColors.danger),
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
    final cat = habit.category.trim().isEmpty
        ? ShoppingCategory.general.label
        : habit.category;
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
          Text(
            context.l10n.shopBasedOnUsual,
            style: const TextStyle(
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
