import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/repositories.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

class MealsScreen extends ConsumerWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(mealsProvider);
    final today = DateTime.now().weekday;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meals'),
        actions: [
          IconButton(
            onPressed: () => _showAddMeal(context, ref, weekday: today),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: mealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Could not load meals.')),
        data: (meals) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              const NestCard(
                child: Text(
                  'Plan dinners for the week, then push ingredients to the shared grocery list.',
                  style: TextStyle(color: AppColors.inkSecondary, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              for (final day in MealRepository.weekdays) ...[
                SectionLabel(
                  day.$2 + (day.$1 == today ? ' · Today' : ''),
                ),
                ..._dayCards(context, ref, day.$1, meals),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }

  List<Widget> _dayCards(
    BuildContext context,
    WidgetRef ref,
    int weekday,
    List<MealPlan> meals,
  ) {
    final dayMeals = meals.where((m) => m.weekday == weekday).toList();
    if (dayMeals.isEmpty) {
      return [
        NestCard(
          onTap: () => _showAddMeal(context, ref, weekday: weekday),
          child: const Text(
            'No meal planned — tap to add',
            style: TextStyle(color: AppColors.inkMuted),
          ),
        ),
      ];
    }
    return [
      for (final meal in dayMeals)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: NestCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.mealType,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        meal.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (meal.ingredients.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          meal.ingredients.replaceAll('\n', ', '),
                          style: const TextStyle(
                            color: AppColors.inkSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Add ingredients to list',
                  onPressed: () async {
                    final added = await ref
                        .read(mealRepositoryProvider)
                        .addIngredientsToShopping(meal);
                    try {
                      await ref.read(syncServiceProvider).syncAll();
                    } catch (_) {}
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          added == 0
                              ? 'No new ingredients to add'
                              : 'Added $added item${added == 1 ? '' : 's'} to groceries',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart_outlined,
                      color: AppColors.primary),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: () async {
                    await ref.read(mealRepositoryProvider).delete(meal.id);
                    try {
                      await ref.read(syncServiceProvider).syncAll();
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ),
      NestCard(
        onTap: () => _showAddMeal(context, ref, weekday: weekday),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: const Text(
          '+ Add another meal',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];
  }

  Future<void> _showAddMeal(
    BuildContext context,
    WidgetRef ref, {
    required int weekday,
  }) async {
    final title = TextEditingController();
    final ingredients = TextEditingController();
    var mealType = 'Dinner';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Plan a meal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final type in const [
                        'Breakfast',
                        'Lunch',
                        'Dinner',
                      ])
                        ChoiceChip(
                          label: Text(type),
                          selected: mealType == type,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: mealType == type
                                ? Colors.white
                                : AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setModal(() => mealType = type),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: title,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Dish name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ingredients,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Ingredients (comma or new line)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Save meal'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final name = title.text.trim();
    title.dispose();
    final ings = ingredients.text.trim();
    ingredients.dispose();
    if (saved == true && name.isNotEmpty) {
      await ref.read(mealRepositoryProvider).upsert(
            weekday: weekday,
            title: name,
            mealType: mealType,
            ingredients: ings,
          );
      try {
        await ref.read(syncServiceProvider).syncAll();
      } catch (_) {}
    }
  }
}
