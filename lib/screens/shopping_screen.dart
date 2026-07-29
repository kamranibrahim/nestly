import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  late List<ShoppingItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(MockData.shopping);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _items.map((i) => i.category).toSet().toList();
    final left = _items.where((i) => !i.done).length;

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          NestCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              decoration: InputDecoration(
                hintText: 'Add an item',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                prefixIcon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.primary,
                ),
                hintStyle: const TextStyle(color: AppColors.inkMuted),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                    final items =
                        _items.where((i) => i.category == category).toList();
                    return [
                      for (var i = 0; i < items.length; i++) ...[
                        _ShopRow(
                          item: items[i],
                          onToggle: () {
                            final index = _items.indexOf(items[i]);
                            setState(() {
                              _items[index] = ShoppingItem(
                                name: items[i].name,
                                category: items[i].category,
                                qty: items[i].qty,
                                done: !items[i].done,
                              );
                            });
                          },
                        ),
                        if (i != items.length - 1)
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
