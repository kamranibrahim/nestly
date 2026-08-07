# Plan 005: Phase 1 — Family OS Foundation (Pillar 1 active)

> **Type**: DOC / product roadmap index.  
> **Active scope**: Phase 1 **Pillar 1 — Core Household Experience** only.  
> Other pillars / Phase 2 are out of scope until requested.  
> Grounded in `PROJECT_IMPLEMENTATION.md` and commit `0bba2e7`.

## Status

- **Priority**: P1
- **Effort**: multi-quarter
- **Category**: direction
- **Planned at**: commit `0bba2e7`, 2026-08-08

---

## Frame

| Phase | Job |
|-------|-----|
| Phase 1 | Best everyday family organizer |
| Phase 2 | AI-powered family assistant on the same nest data (later) |

Pillar 1 success = families use Tasks / Calendar / Shop / Meals / Expenses daily, offline-first, with trustworthy sync.

---

## Pillar 1 backlog (from product brief → waves)

### Wave 1 — Daily-loop depth (executor plans now)

| Plan | Domain | Ships | Effort |
|------|--------|-------|--------|
| [006](./006-tasks-recurrence-due-dates.md) | Tasks | Real cadence recurrence + calendar due dates | L |
| [007](./007-calendar-agenda-recurrence.md) | Calendar | Agenda view + recurring events | L |
| [008](./008-shopping-multi-list-habits-sync.md) | Shopping | Multi-list / store lists + sync grocery habits | M |
| [009](./009-meals-recipe-library-templates.md) | Meals | Recipe library + meal templates | L |
| [010](./010-expenses-recurring-bills-charts.md) | Expenses | Recurring bills + month charts | M |

**Execute in order 006 → 007 → 008 → 009 → 010** unless a domain owner picks a single plan. 006 before 007 helps shared recurrence helpers; 008 before 009 so meals can later suggest from pantry/lists.

### Wave 2 — Still Pillar 1, plans later

| Domain | Deferred Next items |
|--------|---------------------|
| Tasks | Templates, smart priority, photos, voice notes, dependencies, estimated duration, subtasks |
| Calendar | Shared schedules polish, school ICS import, public holidays, travel time, availability/conflicts |
| Shopping | Barcode, price tracking, favorites, pantry inventory, expiry, collaborative presence, purchase history UI |
| Meals | Nutrition, leftovers, pantry suggestions, family preferences, cooking timer |
| Expenses | Shared savings goals, PDF export, richer monthly report share |

### Already Current (do not rebuild)

Shared tasks/assignee/done; events + member filters; shopping lists/categories/habits (local); weekly meals → shop; expenses + budget + bills (one-off).

### Partial today (Wave 1 must replace/upgrade)

- Tasks `recurring` = due-label cycle only (`TaskRepository.nextDueLabel`)
- Expenses categories = chips, not charts
- Shopping multi-list schema exists; UI is single `list-groceries`
- Bills have `dueAt` but no cadence

---

## Conventions every Pillar 1 executor must follow

- Offline-first: Drift write + `dirty`/`updatedAt`; extend `_push*` / `_pull*` in `lib/data/auth_repository.dart`
- Schema: bump `schemaVersion`, add `from < N` migration via `_addColumnIfMissing` / `_createTableIfMissing` in `lib/data/db/app_database.dart`
- UI state: ephemeral only in `lib/state/`; repos in `lib/data/repositories.dart`
- i18n: new strings in `lib/l10n/app_en.arb` + `app_ar.arb`, then regenerate
- Tests: extend `test/repositories_test.dart` (in-memory Drift) for repo behavior
- Match Care cadence pattern (`CareItems.cadenceDays` + `nextDueAt`) for household recurrence — do not invent a second recurrence system without reason
- Brand: quiet Casaio UX — no noisy “AI dashboard” chrome in Wave 1

---

## Verification baseline (all Wave 1 plans)

```bash
flutter test test/repositories_test.dart
flutter analyze lib/data lib/screens lib/state
```

Expect: tests pass; analyze clean for touched paths (pre-existing issues outside scope: report, do not mass-fix).
