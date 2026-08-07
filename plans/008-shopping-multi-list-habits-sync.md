# Plan 008: Expose multi-list shopping and sync grocery habits

> **Executor instructions**: Follow step by step. Verify each step. Update `plans/README.md` when done.
>
> **Drift check**: `git diff --stat 0bba2e7..HEAD -- lib/data/db/app_database.dart lib/data/repositories.dart lib/data/auth_repository.dart lib/screens/shopping_screen.dart lib/state/ test/repositories_test.dart`

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED (habits currently local-only; syncing changes privacy/device assumptions)
- **Depends on**: none (after 006/007 preferred for sequencing only)
- **Category**: direction
- **Planned at**: commit `0bba2e7`, 2026-08-08

## Why this matters

Store-specific lists (“Costco”, “Pharmacy”) are in the Pillar 1 brief. Schema already has `ShoppingLists`, but UI defaults everything to `list-groceries`. Habits power restock suggestions but never leave the device, so a second phone cannot help.

## Current state

- Tables: `ShoppingLists`, `ShoppingItems`, `GroceryHabits` (`app_database.dart`). Habits comment: **device-side; not synced**.
- `ShoppingRepository.defaultListId = 'list-groceries'`; most APIs default to it.
- UI: `shopping_screen.dart` — categories, bought filter, suggestions; no list switcher.
- Sync: lists/items push/pull exist; **no habits sync** in `auth_repository.dart`.

## Commands

| Purpose | Command | Expected |
|---------|---------|----------|
| Tests | `flutter test test/repositories_test.dart` | Pass |
| Full | `flutter test` | Pass |
| Codegen | `dart run build_runner build --delete-conflicting-outputs` | Exit 0 if schema changes |

## Scope

**In scope**

- CRUD for shopping lists (create/rename/archive-or-soft-delete)
- Shopping UI: list picker / tabs; add item targets selected list
- Meals `addIngredientsToShopping` stays on groceries **or** accepts listId (default groceries)
- Sync `GroceryHabits` under nest (LWW like other tables) — add `nestId`, `dirty`, `deleted`, `updatedAt` if missing
- Migration + push/pull for habits
- l10n; tests for multi-list + habit sync field round-trip if feasible in repo tests

**Out of scope**

- Barcode, price tracking, pantry stock, expiry, favorites product DB, OT presence, purchase history screens (Wave 2)
- Changing LWW to CRDT

## Steps

### Step 1: Lists API

In `ShoppingRepository`:

- `watchLists()`, `addList(name)`, `renameList`, `softDeleteList` (mark list + optionally items deleted)
- Ensure nest always has `list-groceries` (existing seed/auth path)
- `watchItems(listId:)` already exists — wire UI

**Verify**: repository tests create second list, add item with that `listId`, watch returns only that list’s items.

### Step 2: Habits nest-scoped + sync

- If `GroceryHabits` lacks sync columns, add them (schema bump — read live version) + migration
- Implement `_pushGroceryHabits` / `_pullGroceryHabits` mirroring shopping items LWW
- Keep normalize-name keys stable

**Verify**: analyze + tests; document that habits now leave the device (privacy sheet one-liner if product copy mentions local-only — update only if existing string claims local-only).

### Step 3: Shopping UI

- List selector at top (chips or dropdown)
- “New list” action
- Empty states per list
- Suggestions still scoped to active list when possible

**Verify**: `flutter test`; manual smoke not required for DONE but note in PR.

## Test plan

- Default list still works for existing tests
- Second list isolation
- Soft-delete list hides it from `watchLists`
- Habit record after toggleDone still updates (existing test ~128+)

## Done criteria

- [ ] User can create and switch lists; items stay on the correct list and sync
- [ ] Grocery habits sync with the nest
- [ ] `flutter test` passes
- [ ] No barcode/pantry/price features
- [ ] `plans/README.md` → DONE

## STOP conditions

- Habit primary key / name normalization cannot nest-scope without data loss — stop and propose migration design.
- Soft-delete cascades break meal ingredient adds — fix or stop.

## Maintenance notes

- Wave 2 pantry should be a new table, not overload shopping categories (“Pantry” aisle ≠ inventory).
- Store-specific lists are just named `ShoppingLists` rows.
