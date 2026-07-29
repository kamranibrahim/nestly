import 'package:flutter/material.dart';
import '../widgets/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/repositories.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/sheet_form.dart';

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
            tooltip: 'Shop this week',
            onPressed: () => _shopWeek(context, ref, mealsAsync.valueOrNull ?? const []),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
          IconButton(
            tooltip: 'Plan dinner week',
            onPressed: () => _showPlanWeek(context, ref, mealsAsync.valueOrNull ?? const []),
            icon: const Icon(Icons.calendar_view_week_rounded),
          ),
          IconButton(
            onPressed: () => _showAddMeal(context, ref, weekday: today),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: mealsAsync.when(
        loading: () => const NestLoadingSkeleton(itemCount: 5),
        error: (_, _) =>
            const Center(child: Text('Could not load meals.')),
        data: (meals) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 72),
            children: [
              const NestCard(
                child: Text(
                  'Plan dinners for the week, then push ingredients to the shared grocery list.',
                  style: TextStyle(color: AppColors.inkSecondary, height: 1.4),
                ),
              ),
              const SizedBox(height: 6),
              for (final day in MealRepository.weekdays) ...[
                SectionLabel(
                  day.$2 + (day.$1 == today ? ' · Today' : ''),
                ),
                ..._dayCards(context, ref, day.$1, meals),
                const SizedBox(height: 6),
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
          padding: const EdgeInsets.only(bottom: 6),
          child: NestCard(
            onTap: () => _showEditMeal(context, ref, meal),
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
    await _showMealSheet(context, ref, weekday: weekday);
  }

  Future<void> _showEditMeal(
    BuildContext context,
    WidgetRef ref,
    MealPlan meal,
  ) async {
    await _showMealSheet(
      context,
      ref,
      weekday: meal.weekday,
      existing: meal,
    );
  }

  Future<void> _showMealSheet(
    BuildContext context,
    WidgetRef ref, {
    required int weekday,
    MealPlan? existing,
  }) async {
    final result = await showModalBottomSheet<
        ({String title, String mealType, String ingredients, bool deleteMeal})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        var mealType = existing?.mealType ?? 'Dinner';
        return OwnedControllers(
          count: 2,
          builder: (context, c) {
            if (c[0].text.isEmpty && existing != null) {
              c[0].text = existing.title;
            }
            if (c[1].text.isEmpty && existing != null) {
              c[1].text = existing.ingredients;
            }
            return StatefulBuilder(
              builder: (context, setModal) {
                return sheetBody(
                  context: context,
                  children: [
                    sheetHandle(),
                    const SizedBox(height: 6),
                    Text(
                      existing == null ? 'Plan a meal' : 'Edit meal',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                            showCheckmark: false,
                            selectedColor: AppColors.primary,
                            checkmarkColor: AppColors.onDark,
                            labelStyle: TextStyle(
                              color: mealType == type
                                  ? AppColors.onDark
                                  : AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) =>
                                setModal(() => mealType = type),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: c[0],
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration:
                          const InputDecoration(hintText: 'Dish name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: c[1],
                      minLines: 2,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Ingredients (comma or new line)',
                      ),
                    ),
                    const SizedBox(height: 6),
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
                            mealType: mealType,
                            ingredients: c[1].text.trim(),
                            deleteMeal: false,
                          ),
                        );
                      },
                      child: Text(existing == null ? 'Save meal' : 'Save changes'),
                    ),
                    if (existing != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(
                          context,
                          (
                            title: existing.title,
                            mealType: existing.mealType,
                            ingredients: existing.ingredients,
                            deleteMeal: true,
                          ),
                        ),
                        child: const Text('Delete meal'),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (result != null) {
      if (result.deleteMeal && existing != null) {
        await ref.read(mealRepositoryProvider).delete(existing.id);
      } else {
        await ref.read(mealRepositoryProvider).upsert(
              id: existing?.id,
              weekday: weekday,
              title: result.title,
              mealType: result.mealType,
              ingredients: result.ingredients,
            );
      }
      try {
        await ref.read(syncServiceProvider).syncAll();
      } catch (_) {}
    }
  }

  Future<void> _showPlanWeek(
    BuildContext context,
    WidgetRef ref,
    List<MealPlan> meals,
  ) async {
    final result = await showModalBottomSheet<Map<int, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PlanDinnerWeekSheet(meals: meals),
    );

    if (result == null) return;
    await ref.read(mealRepositoryProvider).planDinnerWeek(result);
    try {
      await ref.read(syncServiceProvider).syncAll();
    } catch (_) {}
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dinner week updated')),
    );
  }

  Future<void> _shopWeek(
    BuildContext context,
    WidgetRef ref,
    List<MealPlan> meals,
  ) async {
    final dinners = meals
        .where((meal) => meal.mealType.toLowerCase() == 'dinner')
        .toList();
    final added = await ref
        .read(mealRepositoryProvider)
        .addMealsIngredientsToShopping(dinners, label: 'this week');
    try {
      await ref.read(syncServiceProvider).syncAll();
    } catch (_) {}
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added == 0
              ? 'No new dinner ingredients to add'
              : 'Added $added item${added == 1 ? '' : 's'} from this week',
        ),
      ),
    );
  }
}

class _PlanDinnerWeekSheet extends StatefulWidget {
  const _PlanDinnerWeekSheet({required this.meals});

  final List<MealPlan> meals;

  @override
  State<_PlanDinnerWeekSheet> createState() => _PlanDinnerWeekSheetState();
}

class _PlanDinnerWeekSheetState extends State<_PlanDinnerWeekSheet> {
  late final Map<int, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final day in MealRepository.weekdays)
        day.$1: TextEditingController(text: _initialTitle(day.$1)),
    };
  }

  String _initialTitle(int weekday) {
    for (final meal in widget.meals) {
      if (meal.weekday == weekday && meal.mealType == 'Dinner' && !meal.deleted) {
        return meal.title;
      }
    }
    return '';
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return sheetBody(
      context: context,
      children: [
        sheetHandle(),
        const SizedBox(height: 6),
        const Text(
          'Plan dinner week',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Fill the nights you care about. Blank days stay empty.',
          style: TextStyle(color: AppColors.inkSecondary),
        ),
        const SizedBox(height: 12),
        for (final day in MealRepository.weekdays) ...[
          Text(
            day.$2,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _controllers[day.$1],
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Dinner for ${day.$2}',
            ),
          ),
          const SizedBox(height: 10),
        ],
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              {
                for (final day in MealRepository.weekdays)
                  day.$1: _controllers[day.$1]!.text.trim(),
              },
            );
          },
          child: const Text('Save week'),
        ),
      ],
    );
  }
}
