# Plan 009: Add meal recipe library and templates

> **Executor instructions**: Follow step by step. Verify each step. Update `plans/README.md` when done.
>
> **Drift check**: `git diff --stat 0bba2e7..HEAD -- lib/data/db/app_database.dart lib/data/repositories.dart lib/data/auth_repository.dart lib/screens/meals_screen.dart test/repositories_test.dart`

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: LOW–MED
- **Depends on**: [008](./008-shopping-multi-list-habits-sync.md) optional (ingredient → list); can target `list-groceries` if 008 not done
- **Category**: direction
- **Planned at**: commit `0bba2e7`, 2026-08-08

## Why this matters

Meal plans today are flat weekday slots (`title` + `ingredients` string). Families reuse the same dinners; without a recipe library they retype ingredients weekly. Templates speed “plan dinner week.”

## Current state

- `MealPlans` table: `weekday`, `mealType`, `title`, `ingredients` text (`app_database.dart` ~188–202).
- `MealRepository`: plan week helpers; `addIngredientsToShopping` splits ingredients string → shopping items.
- UI: `meals_screen.dart`.
- Sync: meal plans push/pull already exist (grep `_pushMeal` / meals collection).

## Commands

| Purpose | Command | Expected |
|---------|---------|----------|
| Tests | `flutter test test/repositories_test.dart` | Pass |
| Codegen | `dart run build_runner build --delete-conflicting-outputs` | Exit 0 |
| Full | `flutter test` | Pass |

## Scope

**In scope**

- New synced table `Recipes` (id, nestId, title, ingredients text or JSON lines, notes optional, dirty/deleted/timestamps)
- Optional `MealTemplates` **or** represent templates as recipes tagged `isTemplate` / `templateWeekday` — prefer **one `Recipes` table** + `applyRecipeToSlot` / `applyTemplateSet`
- Repo: CRUD recipes; “add to meal plan” copies title+ingredients into `MealPlans` row; “save slot as recipe”
- Sync push/pull for recipes
- Meals UI: library tab/section + apply to day; simple template: “apply recipe to all dinners this week” or saved named set of 7 recipe ids (keep v1 simpler: **library + apply to slot** + **duplicate week from recipes list**)
- l10n; tests

**Out of scope**

- Nutrition macros, leftovers, pantry suggestions, cooking timer, preference engine (Wave 2)
- Web recipe import / scraping
- Rich markdown recipe steps (optional `notes` plain text only)

## Steps

### Step 1: Schema + migration

Add `Recipes` table; bump schema version (read live `schemaVersion`, next integer). Register in `@DriftDatabase` tables list.

**Verify**: codegen + `ensureSeeded` still works (seed 0–2 sample recipes optional).

### Step 2: Repository + shopping bridge

- `watchRecipes`, `addRecipe`, `updateRecipe`, `deleteRecipe`
- `applyRecipeToMealPlan(recipeId, weekday, mealType)` → upserts `MealPlans`
- Existing `addIngredientsToShopping` unchanged (reads meal ingredients)

**Verify**: repository tests cover create → apply → meal row has ingredients → shopping add count > 0.

### Step 3: Sync

Mirror other collections: `nests/{id}/recipes/{id}` with LWW.

**Verify**: push/pull fields present; analyze clean.

### Step 4: UI

- Meals screen: section or route for Recipe library
- Actions: Add recipe, Apply to day, Save current slot as recipe
- Keep week grid as primary; library is secondary (one job per section)

**Verify**: `flutter test`; analyze meals screen.

## Test plan

- CRUD recipe
- Apply to Wednesday dinner
- Soft-delete hides from watch
- Ingredients still push to shopping from applied meal

## Done criteria

- [ ] Recipes persist offline and sync
- [ ] Apply recipe fills a meal plan slot
- [ ] `flutter test` passes
- [ ] No nutrition/timer/pantry features
- [ ] `plans/README.md` → DONE

## STOP conditions

- Product requires structured ingredient qty units mid-flight — stop; keep newline/comma text compatible with current shopping split.
- Schema version conflict with parallel plans — reconcile first.

## Maintenance notes

- Wave 2 pantry suggestions should join recipe ingredients to pantry/habits.
- Prefer not forking ingredients parsing — reuse meal → shopping splitter.
