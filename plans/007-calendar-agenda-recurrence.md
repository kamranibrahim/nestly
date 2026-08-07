# Plan 007: Add calendar agenda view and recurring events

> **Executor instructions**: Follow step by step. Run every verification before the next step. On STOP conditions, stop and report. Update `plans/README.md` when done.
>
> **Drift check**: `git diff --stat 0bba2e7..HEAD -- lib/data/db/app_database.dart lib/data/repositories.dart lib/data/auth_repository.dart lib/data/enums.dart lib/state/calendar_ui.dart lib/screens/calendar_screen.dart lib/data/calendar_view_math.dart test/calendar_view_math_test.dart test/repositories_test.dart`

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: MED
- **Depends on**: preferably [006](./006-tasks-recurrence-due-dates.md) for shared day-cadence helpers (can proceed alone if you duplicate a tiny pure helper)
- **Category**: direction
- **Planned at**: commit `0bba2e7`, 2026-08-08

## Why this matters

Month/week grids are weak for “what’s next for the family today.” Agenda is the daily-driver view. Recurring events (school pickup, payday) are expected in any family calendar; without them users recreate events manually.

## Current state

- `CalendarEvents` (`app_database.dart` ~70–87): `startsAt`, `endsAt`, `allDay` — **no recurrence fields**.
- `CalendarBrowseMode` (`enums.dart`): `month`, `week` only.
- UI: `calendar_screen.dart` + `calendar_ui.dart` toggle month/week; search + member filters exist.
- Math helpers: `lib/data/calendar_view_math.dart` + `test/calendar_view_math_test.dart`.
- Sync: event push/pull in `auth_repository.dart` (grep `_pushEvents` / `_pullEvents`).
- School can create a **one-off** event (`SchoolRepository.createCalendarEvent`) — not ICS import (out of scope).

## Commands

| Purpose | Command | Expected |
|---------|---------|----------|
| View math tests | `flutter test test/calendar_view_math_test.dart` | Pass |
| Repo tests | `flutter test test/repositories_test.dart` | Pass |
| Full | `flutter test` | Pass |
| Codegen | `dart run build_runner build --delete-conflicting-outputs` | Exit 0 |

## Scope

**In scope**

- Drift: recurrence fields on `CalendarEvents` + migration (schema **15** if 006 took 14; if 006 not merged, use next free version — **read live `schemaVersion` first**)
- `EventRepository` expand/create/update for recurrence
- Sync push/pull new fields
- `CalendarBrowseMode.agenda` + UI list for selected day / upcoming range
- `calendar_view_math.dart` helpers to expand recurring instances in a date range (or materialize next N)
- l10n EN/AR
- Tests for expansion math + repository create

**Out of scope**

- School ICS import, public holidays, travel time, conflict detection, availability (Wave 2)
- Full RFC 5545 RRULE parser — use **simple cadence** first: `cadenceDays` + optional `weeklyWeekdays` bitmask OR enum `none|daily|weekly|monthly`
- Google/Apple calendar sync

## Steps

### Step 1: Schema — recurrence columns

Add (recommended minimal model):

- `TextColumn recurrence` default `'none'` — values: `none`, `daily`, `weekly`, `monthly`
- `DateTimeColumn recurrenceUntil` nullable — end date
- Keep master row as the series anchor (`startsAt` = first occurrence)

Bump schema; migrate with `_addColumnIfMissing`.

**Verify**: codegen succeeds; app opens on empty DB.

### Step 2: Expansion helper

In `calendar_view_math.dart` (or `calendar_recurrence.dart`):

- `List<DateTimeRange> expandEvent(CalendarEvent e, DateTime rangeStart, DateTime rangeEnd)`
- Cap expansions (e.g. max 366) to avoid runaway
- All-day: date-only arithmetic

**Verify**: unit tests in `test/calendar_view_math_test.dart` for daily/weekly/monthly within a month window + until cutoff.

### Step 3: Repository + sync

- Create/update APIs accept recurrence fields
- Push/pull Firestore fields `recurrence`, `recurrenceUntil`
- Editing “this event only” vs “series” is **out of scope** for v1 — editing updates the master series (document in UI copy)

**Verify**: repository test creates weekly event; expansion returns expected count.

### Step 4: Agenda UI

- Add `CalendarBrowseMode.agenda`
- Agenda: chronological list for focused day (and optional +7 days section) using expansion helper + member filter + search
- Mode chips: Month | Week | Agenda
- Event editor: recurrence dropdown matching schema values

**Verify**: `flutter analyze` on touched screens; `flutter test`.

## Test plan

- Expansion: weekly Mon event across 4 weeks → 4 instances
- `recurrenceUntil` stops expansion
- `none` → single instance
- Existing month/week tests still pass

## Done criteria

- [ ] Agenda mode lists occurrences for the visible range
- [ ] Recurring create/edit persists and syncs
- [ ] Expansion unit tests pass
- [ ] No Wave 2 calendar features
- [ ] `plans/README.md` → DONE

## STOP conditions

- Schema version collision with parallel 006 work — reconcile version numbers before migrating.
- Full RRULE demanded by product mid-flight — stop; simple cadence is the plan.
- Expansion must rewrite all Firestore docs as instances — stop and report (prefer expand-at-read).

## Maintenance notes

- Wave 2 holidays/ICS should feed the same occurrence list API.
- Conflict detection later compares expanded instances in range.
