# Plan 010: Add recurring bills and month expense charts

> **Executor instructions**: Follow step by step. Verify each step. Update `plans/README.md` when done.
>
> **Drift check**: `git diff --stat 0bba2e7..HEAD -- lib/data/db/app_database.dart lib/data/repositories.dart lib/data/auth_repository.dart lib/data/notification_service.dart lib/screens/expenses_screen.dart pubspec.yaml test/repositories_test.dart`

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: LOW–MED
- **Depends on**: none (Wave 1 last domain slice)
- **Category**: direction
- **Planned at**: commit `0bba2e7`, 2026-08-08

## Why this matters

Bills are almost always monthly/weekly; today `Bills` are one-off `dueAt` + paid toggle. Expenses already have category totals as **chips** — Pillar 1 asks for charts and clearer monthly reporting without leaving the nest money screen.

## Current state

- `Expenses`: title, category, amount, paidBy, spentAt.
- `Bills`: title, amount, dueAt, paid — **no cadence** (`app_database.dart` ~97–120).
- UI: `expenses_screen.dart` — budget bar, category chips via `watchMonthCategoryTotals`, bill list.
- Reminders: day-before unpaid bills in `notification_service.dart`.
- No chart package required today — check `pubspec.yaml` before adding; prefer **lightweight CustomPainter / bar rows** matching Casaio UI over a heavy chart dependency unless already present.

## Commands

| Purpose | Command | Expected |
|---------|---------|----------|
| Tests | `flutter test test/repositories_test.dart` | Pass |
| Full | `flutter test` | Pass |
| Codegen | `dart run build_runner build --delete-conflicting-outputs` | Exit 0 if schema changes |

## Scope

**In scope**

- Bills: `cadenceDays` (0 = one-off; 7/14/30 common) + behavior on mark paid: advance `dueAt`, set `paid: false` (Care/Task Wave 1 pattern)
- Sync bill fields
- Update bill reminders to use next `dueAt`
- Expenses UI: simple bar/segment chart for month category totals (reuse `watchMonthCategoryTotals` data)
- Optional “This month” summary header (total spent vs budget) — keep one composition, not a dashboard of widgets
- l10n; tests for recurring bill advance

**Out of scope**

- Shared savings goals, PDF export, email report (Wave 2)
- Bank sync / Plaid
- Multi-currency

## Steps

### Step 1: Schema + BillRepository

- Add `cadenceDays` to `Bills` (default 0)
- Migration bump (read live schema version)
- `markPaid`: if `cadenceDays >= 1`, advance `dueAt` by cadence, `paid: false`; else `paid: true`
- Create/edit accept cadence

**Verify**: tests in `repositories_test.dart` (existing bill tests ~402+) extended for recurring.

### Step 2: Sync + notifications

- Push/pull `cadenceDays`
- Reminder scheduling unchanged aside from advanced `dueAt`

**Verify**: analyze; bill reminder code compiles with new fields.

### Step 3: Charts UI

- In expenses screen, replace or augment category chips with horizontal bar chart (amounts normalized to max category)
- Use existing totals stream — no new query required unless adding spend-over-time (defer time series to Wave 2 reports)
- Match `AppColors` / theme; no purple glow / generic AI chrome

**Verify**: `flutter test`; analyze `expenses_screen.dart`.

## Test plan

- One-off bill mark paid → stays paid
- Monthly bill mark paid → dueAt += ~30 days, unpaid
- Category totals still sum correctly (existing coverage)

## Done criteria

- [ ] Recurring bills advance on pay and sync
- [ ] Month category visualization beyond text chips only
- [ ] `flutter test` passes
- [ ] No PDF / savings goals
- [ ] `plans/README.md` → DONE

## STOP conditions

- Adding a chart package forces wide dependency churn — prefer custom bars; stop if told to add a package that breaks Flutter web/mobile constraints unexpectedly.
- Schema version conflict — reconcile with 006–009.

## Maintenance notes

- Wave 2 PDF can render the same totals used by the chart.
- Savings goals should be a new table, not overload `NestSettings.monthBudget`.
