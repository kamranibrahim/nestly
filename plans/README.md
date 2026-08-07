# Implementation Plans

Generated for Casaio home-widget modernization (2026-07-31). Gap analysis 2026-08-04. Phase 1 Pillar 1 Wave 1 plans 2026-08-08.

Execute Wave 1 in order unless dependencies say otherwise.

## Execution order & status

| Plan | Title | Priority | Effort | Depends on | Status |
|------|-------|----------|--------|------------|--------|
| 001 | Ship a modern Casaio Home Screen widget | P1 | L | — | DONE — iOS + Android layouts + deep links (device QA remaining) |
| 002 | End-to-end app gap analysis (brief) | — | — | — | DOC — [002-app-gap-analysis.md](./002-app-gap-analysis.md) |
| 003 | UI state separation (Riverpod controllers) | P2 | L | — | DONE — see [003-ui-state-separation.md](./003-ui-state-separation.md) + `lib/state/` |
| 004 | English + Arabic i18n | P1 | L | — | DONE — see [004-english-arabic-i18n.md](./004-english-arabic-i18n.md) |
| 005 | Phase 1 — Family OS Foundation (Pillar 1 index) | P1 | multi-Q | — | DOC — [005-phase1-family-os-foundation.md](./005-phase1-family-os-foundation.md) |
| 006 | Tasks: real recurrence + due dates | P1 | L | — | IN PROGRESS — [006-tasks-recurrence-due-dates.md](./006-tasks-recurrence-due-dates.md) |
| 007 | Calendar: agenda + recurring events | P1 | L | 006 preferred | TODO — [007-calendar-agenda-recurrence.md](./007-calendar-agenda-recurrence.md) |
| 008 | Shopping: multi-list + sync habits | P1 | M | — | TODO — [008-shopping-multi-list-habits-sync.md](./008-shopping-multi-list-habits-sync.md) |
| 009 | Meals: recipe library + templates | P1 | L | 008 optional | TODO — [009-meals-recipe-library-templates.md](./009-meals-recipe-library-templates.md) |
| 010 | Expenses: recurring bills + charts | P1 | M | — | TODO — [010-expenses-recurring-bills-charts.md](./010-expenses-recurring-bills-charts.md) |

## Deferred by request

- Nest-scoped Firestore / Storage **rules** (P0 in 002) — skipped until explicitly requested.
- Phase 1 pillars beyond Pillar 1 — wait for user brief.
- Phase 2 AI assistant — after Phase 1 depth.
- Pillar 1 **Wave 2** (photos, barcode, ICS, PDF, etc.) — listed in 005; no executor plans yet.

## Dependency notes

- Wave 1: prefer `006 → 007 → 008 → 009 → 010`.
- Schema bumps must read live `schemaVersion` before migrating (006 expects 14; later plans take next free ints).
- Phase 2 AI must not invent nest fields Wave 1/2 have not stored.

## Findings considered and rejected

- Putting Locator on the widget: privacy/product mismatch with opt-in last-known model.
- Dark / glass “AI dashboard” widget: conflicts with Casaio pastel brand.
- Interactive App Intents in v1: high complexity vs visual professionalism payoff — defer.
- Full RFC 5545 RRULE in calendar Wave 1: use simple daily/weekly/monthly cadence (007).
- Chart package by default in 010: prefer lightweight custom bars unless pubspec already has a chart lib.
