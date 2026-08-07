# Plan 006: Ship real task recurrence and calendar due dates

> **Executor instructions**: Follow step by step. Run every verification before the next step. On STOP conditions, stop and report — do not improvise. When done, update the status row in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 0bba2e7..HEAD -- lib/data/db/app_database.dart lib/data/repositories.dart lib/data/auth_repository.dart lib/data/enums.dart lib/data/notification_service.dart lib/screens/tasks_screen.dart test/repositories_test.dart`
> If in-scope files changed, re-read Current state excerpts before proceeding.

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: MED (schema + sync + reminder date math)
- **Depends on**: none (Pillar 1 Wave 1; see [005](./005-phase1-family-os-foundation.md))
- **Category**: direction
- **Planned at**: commit `0bba2e7`, 2026-08-08

## Why this matters

Families treat chores as real calendars (“every Monday”, “every 7 days”). Today `recurring` only cycles `Today → Tomorrow → In 7 days` and due is a string label, so reminders and Home ranking cannot trust dates. Real `dueAt` + cadence unlocks reliable reminders and sets up Calendar/Meals later.

## Current state

- Schema `Tasks` (`lib/data/db/app_database.dart` ~22–37): `dueLabel` text, `recurring` bool — no `dueAt`, no cadence.
- `schemaVersion => 13`; migrations use `_addColumnIfMissing`.
- `TaskRepository.toggleDone` (`lib/data/repositories.dart` ~33–72): if recurring, keeps `done: false` and sets `dueLabel` via `nextDueLabel`.
- `TaskDueLabel` (`lib/data/enums.dart` ~236–274): three labels + `dueDate({now})` helper already exists.
- Sync (`lib/data/auth_repository.dart` `_pushTasks` / `_pullTasks` ~468–537): pushes `dueLabel`, `recurring` only.
- Reminders (`lib/data/notification_service.dart`): `_dueDateForTaskLabel(task.dueLabel, …)`.
- UI (`lib/screens/tasks_screen.dart`): chips for `TaskDueLabel.values` + recurring switch.
- Exemplar cadence: `CareItems` (`cadenceDays`, `nextDueAt`) + `CareRepository.markDone` advances next due — **match this mental model**.
- Tests: `test/repositories_test.dart` — `recurring task rolls due label and stays open`.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Tests | `flutter test test/repositories_test.dart` | All pass |
| Broader | `flutter test` | All pass |
| Analyze | `flutter analyze lib/data/db/app_database.dart lib/data/repositories.dart lib/data/auth_repository.dart lib/screens/tasks_screen.dart lib/data/notification_service.dart` | No new errors in touched files |
| Codegen | `dart run build_runner build --delete-conflicting-outputs` | Exit 0; `app_database.g.dart` updated |

## Scope

**In scope**

- `lib/data/db/app_database.dart` (+ generated `app_database.g.dart`)
- `lib/data/repositories.dart` (`TaskRepository`)
- `lib/data/auth_repository.dart` (task push/pull)
- `lib/data/enums.dart` (due display helpers only if needed)
- `lib/data/notification_service.dart` (task reminder due source)
- `lib/data/family_needs.dart` / home widget snapshot if they key off `dueLabel` — update to prefer `dueAt`
- `lib/screens/tasks_screen.dart` (+ any task sheet widgets in that file)
- `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb` (new cadence/due strings)
- `test/repositories_test.dart`
- Seed/showcase if they insert tasks: `app_database.dart` seed, `lib/data/showcase_seed.dart` as needed for compile

**Out of scope**

- Subtasks, templates, photos, voice, dependencies, priority, duration (Wave 2)
- Calendar event RRULE (plan 007)
- Changing Firestore security rules
- OT/CRDT collaborative editing

## Git workflow

- Branch: `advisor/006-tasks-recurrence-due-dates` (or repo norm)
- Commits: imperative, focused (e.g. `Add task dueAt and cadenceDays with Drift migration`)
- Do not push/PR unless asked

## Steps

### Step 1: Schema v14 — `dueAt` + `cadenceDays`

Add to `Tasks`:

- `DateTimeColumn dueAt` — nullable initially OR non-null with migration backfill
- `IntColumn cadenceDays` — default `0` meaning “not on a day cadence”; when `recurring == true`, use `cadenceDays` in `{1,7,14,30}` (or free int ≥ 1). Prefer: **`recurring` remains the UX flag**; `cadenceDays` stores interval (default `7` when user enables recurring if unset).

Bump `schemaVersion` to **14**. In `onUpgrade`, `if (from < 14)`:

1. `_addColumnIfMissing` for `dueAt` and `cadenceDays`
2. Backfill SQL or Dart loop: for each task, set `dueAt` from `TaskDueLabel.dueDateFor(dueLabel, now: now)` when `dueAt` null; set `cadenceDays = 7` where `recurring = 1` and cadence is 0

Keep `dueLabel` column for one release as **derived display cache** OR continue writing a human label from `dueAt` for search compatibility. Minimum: sync and UI use `dueAt` as source of truth; `dueLabel` may be updated to a short relative string for search (`Today`/`Tomorrow`/formatted date).

**Verify**: `dart run build_runner build --delete-conflicting-outputs` → exit 0.

### Step 2: Repository — complete advances `dueAt`

Replace label-cycle in `toggleDone`:

- If marking done && `recurring` && `cadenceDays >= 1`: set `done: false`, `dueAt: nextDue(task.dueAt ?? now, cadenceDays)`, update `dueLabel` helper for display, `dirty/updatedAt`
- If marking done && !recurring: `done: true` as today
- `addTask` / `updateTask`: accept `DateTime? dueAt`, `int cadenceDays`; if only label passed from old call sites, map via `TaskDueLabel`

Add pure helper (same file or small `lib/data/task_due.dart`):

```dart
DateTime advanceDueAt(DateTime from, int cadenceDays) {
  final day = DateTime(from.year, from.month, from.day);
  return day.add(Duration(days: cadenceDays.clamp(1, 365)));
}
```

**Verify**: `flutter test test/repositories_test.dart` — update test `recurring task rolls due label…` to assert `dueAt` advanced by cadence and `done == false`.

### Step 3: Sync push/pull

In `_pushTasks` / `_pullTasks`, include:

- `dueAt` as Firestore `Timestamp?`
- `cadenceDays` as int

On pull, default `dueAt` from legacy `dueLabel` if missing (same as migration).

**Verify**: grep that both push and pull mention `dueAt` and `cadenceDays`; no analyze errors on `auth_repository.dart`.

### Step 4: Notifications + consumers

- `notification_service.dart`: schedule from `task.dueAt` when non-null; else fall back to label.
- Grep `dueLabel` / `TaskDueLabel` in `family_needs.dart`, `nest_home_widget*.dart` — prefer `dueAt` for ordering.

**Verify**: `flutter test test/notification_intent_test.dart` (and any task-related tests) still pass.

### Step 5: Tasks UI

In task create/edit sheet:

- Due: date picker (or keep Today/Tomorrow/In 7 days quick chips that set `dueAt`)
- Recurring: switch + cadence chips (`Every day` / `Every week` / `Every 2 weeks` / `Every month` ≈ 30 days)
- List subtitle: format due date (use `intl` + l10n); show “repeats · every N days” when recurring

Add ARB keys (EN + AR); regenerate l10n.

**Verify**: `flutter analyze lib/screens/tasks_screen.dart` clean for new code; `flutter test`.

## Test plan

In `test/repositories_test.dart` (pattern: existing recurring test ~76+):

1. Recurring weekly: complete → `dueAt` += 7 days, stays open
2. Non-recurring: complete → `done == true`
3. `updateTask` persists `dueAt` + `cadenceDays`
4. Optional: migration not unit-tested in-memory if columns exist on createAll — ensure `ensureSeeded` still works with new columns

## Done criteria

- [ ] `schemaVersion == 14` with `from < 14` migration
- [ ] Recurring completion advances `dueAt` by `cadenceDays` (no label-only cycle as sole behavior)
- [ ] Firestore push/pull includes `dueAt` + `cadenceDays`
- [ ] Task reminders use `dueAt` when present
- [ ] `flutter test test/repositories_test.dart` passes with updated recurring assertions
- [ ] `flutter test` passes
- [ ] No Wave 2 features shipped
- [ ] `plans/README.md` status → DONE

## STOP conditions

- Care-style cadence cannot land without also rewriting Calendar events the same way — do **not** expand into 007; stop and report if blocked by shared helper design.
- Existing devices would lose tasks on migration — stop and fix migration before shipping.
- `build_runner` / Drift generation fails twice after a reasonable fix.

## Maintenance notes

- Plan 007 may extract shared `advanceDueAt` / recurrence enums — keep helper small and pure.
- Deprecate relying on `dueLabel` as source of truth in a later cleanup once all clients sync `dueAt`.
- Reviewers: check LWW sync field list and null `dueAt` on old remote docs.
