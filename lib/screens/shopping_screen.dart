import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/mock_data.dart';
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

  @override
  void dispose() {
    _addController.dispose();
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Family Groceries'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load list: $error')),
        data: (items) {
          final categories = <String>[];
          for (final item in items) {
            if (!categories.contains(item.category)) {
              categories.add(item.category);
            }
          }
          final left = items.where((i) => !i.done).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              NestCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    ...MockData.members.take(3).map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: MemberAvatar(
                              initials: m.initials,
                              color: m.color,
                              size: 32,
                            ),
                          ),
                        ),
                    const Spacer(),
                    Text(
                      '$left left',
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              NestCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: TextField(
                  controller: _addController,
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
                        color: AppColors.primary,
                      ),
                    ),
                    hintStyle: const TextStyle(color: AppColors.inkMuted),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const NestCard(
                  child: Text(
                    'List is empty. Add milk, eggs, or anything else.',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                )
              else
                for (final category in categories) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
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
                            for (var i = 0; i < categoryItems.length; i++) ...[
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
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(
              item.done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: item.done ? AppColors.primary : AppColors.inkMuted,
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
            Text(
              item.qty,
              style: const TextStyle(
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
