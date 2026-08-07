import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/enums.dart';
import '../data/repositories.dart';
import '../data/sync_controller.dart';
import '../providers/providers.dart';
import '../state/meals_ui.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/first_run_empty_card.dart';
import '../widgets/sheet_form.dart';
import '../widgets/shimmer.dart';
import '../l10n/l10n_ext.dart';

export '../data/enums.dart' show MealsEntry;

class MealsScreen extends ConsumerWidget {
  const MealsScreen({super.key, this.entry = MealsEntry.browse});

  final MealsEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(mealsUiProvider);
    final uiCtrl = ref.read(mealsUiProvider.notifier);
    final mealsAsync = ref.watch(mealsProvider);
    final today = DateTime.now().weekday;

    if (entry != MealsEntry.browse && uiCtrl.consumeEntry()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _handleEntry(context, ref, entry);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.screenMeals),
        actions: [
          IconButton(
            tooltip: context.l10n.shopThisWeek,
            onPressed: () =>
                _shopWeek(context, ref, mealsAsync.valueOrNull ?? const []),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
          IconButton(
            tooltip: context.l10n.planDinnerWeek,
            onPressed: () => _showPlanWeek(
              context,
              ref,
              mealsAsync.valueOrNull ?? const [],
            ),
            icon: const Icon(Icons.calendar_view_week_rounded),
          ),
          IconButton(
            onPressed: () =>
                _showAddMeal(context, ref, weekday: ui.focusWeekday),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: mealsAsync.when(
        loading: () => const NestLoadingSkeleton(itemCount: 5),
        error: (_, _) => Center(child: Text(context.l10n.loadFailedMeals)),
        data: (meals) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 84),
            children: [
              NestCard(
                child: Text(
                  context.l10n.mealsIntro,
                  style: const TextStyle(color: AppColors.inkSecondary, height: 1.4),
                ),
              ),
              if (meals.isEmpty) ...[
                const SizedBox(height: 8),
                FirstRunEmptyCard(
                  icon: Icons.restaurant_rounded,
                  color: AppColors.tileTeal,
                  title: context.l10n.emptyMealsTitle,
                  body: context.l10n.emptyMealsBody,
                  actionLabel: context.l10n.emptyMealsAction,
                  onAction: () => _showPlanWeek(context, ref, meals),
                ),
              ],
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final day in MealRepository.weekdays) ...[
                      SoftPill(
                        label: day.$1 == today ? '${day.$2} · Today' : day.$2,
                        selected: ui.focusWeekday == day.$1,
                        onTap: () => uiCtrl.setFocusWeekday(day.$1),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SectionLabel(
                MealRepository.weekdays
                        .firstWhere((d) => d.$1 == ui.focusWeekday)
                        .$2 +
                    (ui.focusWeekday == today ? ' · Today' : ''),
              ),
              ..._dayCards(context, ref, ui.focusWeekday, meals),
              const SizedBox(height: 10),
              SectionLabel(context.l10n.mealsRestOfWeek),
              for (final day in MealRepository.weekdays)
                if (day.$1 != ui.focusWeekday) ...[
                  NestCard(
                    onTap: () => uiCtrl.setFocusWeekday(day.$1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            day.$1 == today ? '${day.$2} · Today' : day.$2,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          _daySummary(day.$1, meals),
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.inkMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
            ],
          );
        },
      ),
    );
  }
}

Future<void> _handleEntry(
  BuildContext context,
  WidgetRef ref,
  MealsEntry entry,
) async {
  final meals = ref.read(mealsProvider).valueOrNull ?? const <MealPlan>[];
  switch (entry) {
    case MealsEntry.browse:
      return;
    case MealsEntry.planWeek:
      await _showPlanWeek(context, ref, meals);
      return;
    case MealsEntry.addDinnerToday:
      await _showAddMeal(
        context,
        ref,
        weekday: DateTime.now().weekday,
        initialMealType: 'Dinner',
      );
      return;
  }
}

String _daySummary(int weekday, List<MealPlan> meals) {
  final dayMeals = meals.where((m) => m.weekday == weekday).toList();
  if (dayMeals.isEmpty) return 'Open';
  final dinner = dayMeals.where((m) => m.mealType.toLowerCase() == 'dinner');
  if (dinner.isNotEmpty) return dinner.first.title;
  return '${dayMeals.length} meal${dayMeals.length == 1 ? '' : 's'}';
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
        onTap: () => _showAddMeal(
          context,
          ref,
          weekday: weekday,
          initialMealType: 'Dinner',
        ),
        child: Text(
          context.l10n.mealsNonePlanned,
          style: const TextStyle(color: AppColors.inkMuted),
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
                tooltip: context.l10n.addIngredients,
                onPressed: () => _confirmAddIngredients(
                  context,
                  ref,
                  meals: [meal],
                  label: meal.title,
                ),
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                tooltip: context.l10n.commonRemove,
                onPressed: () async {
                  await ref.read(mealRepositoryProvider).delete(meal.id);
                  await syncAfterWrite(ref, context: context);
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.inkMuted,
                ),
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
  String initialMealType = 'Dinner',
}) async {
  await _showMealSheet(
    context,
    ref,
    weekday: weekday,
    initialMealType: initialMealType,
  );
}

Future<void> _showEditMeal(
  BuildContext context,
  WidgetRef ref,
  MealPlan meal,
) async {
  await _showMealSheet(context, ref, weekday: meal.weekday, existing: meal);
}

Future<void> _showMealSheet(
  BuildContext context,
  WidgetRef ref, {
  required int weekday,
  MealPlan? existing,
  String initialMealType = 'Dinner',
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
      var mealType = existing?.mealType ?? initialMealType;
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
                    existing == null
                        ? context.l10n.mealsPlanAMeal
                        : context.l10n.mealsEditMeal,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
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
                          onSelected: (_) => setModal(() => mealType = type),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: c[0],
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: context.l10n.hintDishName,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: c[1],
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: context.l10n.hintIngredients,
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
                      Navigator.pop(context, (
                        title: name,
                        mealType: mealType,
                        ingredients: c[1].text.trim(),
                        deleteMeal: false,
                      ));
                    },
                    child: Text(
                      existing == null
                          ? context.l10n.mealsSaveMeal
                          : context.l10n.commonSaveChanges,
                    ),
                  ),
                  if (existing != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context, (
                        title: existing.title,
                        mealType: existing.mealType,
                        ingredients: existing.ingredients,
                        deleteMeal: true,
                      )),
                      child: Text(context.l10n.deleteMeal),
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
    await syncAfterWrite(ref, context: context);
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
  await syncAfterWrite(ref, context: context);
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(context.l10n.mealsUpdated)));
}

Future<void> _shopWeek(
  BuildContext context,
  WidgetRef ref,
  List<MealPlan> meals,
) async {
  final dinners = meals
      .where((meal) => meal.mealType.toLowerCase() == 'dinner')
      .toList();
  await _confirmAddIngredients(
    context,
    ref,
    meals: dinners,
    label: 'this week',
  );
}

Future<int> confirmAddMealIngredients(
  BuildContext context,
  WidgetRef ref, {
  required Iterable<MealPlan> meals,
  required String label,
}) {
  return _confirmAddIngredients(context, ref, meals: meals, label: label);
}

Future<int> _confirmAddIngredients(
  BuildContext context,
  WidgetRef ref, {
  required Iterable<MealPlan> meals,
  required String label,
}) async {
  final preview = await ref
      .read(mealRepositoryProvider)
      .previewIngredientsToShopping(meals);
  if (!context.mounted) return 0;

  if (preview.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.mealsNoNewIngredients)));
    return 0;
  }

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final bottom = MediaQuery.viewPaddingOf(sheetContext).bottom;
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
              sheetContext.l10n.mealsAddIngredientsTitle(preview.length),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              sheetContext.l10n.mealsAddIngredientsBody(label),
              style: const TextStyle(
                color: AppColors.inkSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: preview.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.accentDeep,
                    ),
                    title: Text(
                      preview[index],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(context.l10n.screenMeals),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext, true),
              child: Text(context.l10n.mealsAddToGroceries(preview.length)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext, false),
              child: Text(context.l10n.commonCancel),
            ),
          ],
        ),
      );
    },
  );

  if (confirmed != true) return 0;
  final added = await ref
      .read(mealRepositoryProvider)
      .addMealsIngredientsToShopping(meals, label: label);
  await syncAfterWrite(ref, context: context);
  if (!context.mounted) return added;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.l10n.mealsAddedToGroceries(added)),
    ),
  );
  return added;
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
      if (meal.weekday == weekday &&
          meal.mealType == 'Dinner' &&
          !meal.deleted) {
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
        Text(
          context.l10n.planDinnerWeek,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.mealsPlanWeekBody,
          style: const TextStyle(color: AppColors.inkSecondary),
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
              hintText: context.l10n.hintDinnerFor(day.$2),
            ),
          ),
          const SizedBox(height: 10),
        ],
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              for (final day in MealRepository.weekdays)
                day.$1: _controllers[day.$1]!.text.trim(),
            });
          },
          child: Text(context.l10n.saveWeek),
        ),
      ],
    );
  }
}
