import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

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
    try {
      await ref.read(syncServiceProvider).syncAll();
    } catch (_) {}
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
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
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
                              ...members.take(4).map(
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
                          try {
                            await ref.read(syncServiceProvider).syncAll();
                          } catch (_) {}
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
                            hintStyle:
                                const TextStyle(color: AppColors.inkMuted),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (items.isEmpty)
                        NestCard(
                          color: AppColors.accent,
                          bordered: false,
                          child: const Text(
                            'List is empty. Add milk, eggs, or anything else.',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
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
                                    for (var i = 0;
                                        i < categoryItems.length;
                                        i++) ...[
                                      _ShopRow(
                                        item: categoryItems[i],
                                        onToggle: () async {
                                          await ref
                                              .read(shoppingRepositoryProvider)
                                              .toggleDone(categoryItems[i]);
                                          try {
                                            await ref
                                                .read(syncServiceProvider)
                                                .syncAll();
                                          } catch (_) {}
                                        },
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
}

class _ShopRow extends StatelessWidget {
  const _ShopRow({required this.item, required this.onToggle});

  final ShoppingItem item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              item.done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: item.done ? AppColors.ink : AppColors.inkMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: item.done ? TextDecoration.lineThrough : null,
                  color: item.done ? AppColors.inkMuted : AppColors.ink,
                ),
              ),
            ),
            if (item.qty != '1')
              Text(
                item.qty,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions =
        ref.watch(grocerySuggestionsProvider).valueOrNull ?? const [];
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Often bought — tap to add',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.inkSecondary,
              fontSize: 13,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final habit in suggestions) ...[
                SoftPill(
                  label: '+ ${habit.name} · ~${habit.cadenceDays}d',
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
        const SizedBox(height: 4),
      ],
    );
  }
}
