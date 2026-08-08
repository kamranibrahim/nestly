# Implementation Plans

Generated for Casaio home-widget modernization (2026-07-31). Gap analysis 2026-08-04. Phase 1 Pillar 1 Wave 1 plans 2026-08-08. Pillar 2 Family Collaboration roadmap 2026-08-08.

Execute Wave 1 in order unless dependencies say otherwise.

## Execution order & status

| Plan | Title | Priority | Effort | Depends on | Status |
|------|-------|----------|--------|------------|--------|
| 001 | Ship a modern Casaio Home Screen widget | P1 | L | — | DONE — iOS + Android layouts + deep links (device QA remaining) |
| 002 | End-to-end app gap analysis (brief) | — | — | — | DOC — [002-app-gap-analysis.md](./002-app-gap-analysis.md) |
| 003 | UI state separation (Riverpod controllers) | P2 | L | — | DONE — see [003-ui-state-separation.md](./003-ui-state-separation.md) + `lib/state/` |
| 004 | English + Arabic i18n | P1 | L | — | DONE — see [004-english-arabic-i18n.md](./004-english-arabic-i18n.md) |
| 005 | Phase 1 — Family OS Foundation (Pillar 1 index) | P1 | multi-Q | — | DOC — [005-phase1-family-os-foundation.md](./005-phase1-family-os-foundation.md) |
| 006 | Tasks: real recurrence + due dates | P1 | L | — | DONE — [006-tasks-recurrence-due-dates.md](./006-tasks-recurrence-due-dates.md) (`advisor/006-tasks-recurrence-due-dates` @ `f28a79a`) |
| 007 | Calendar: agenda + recurring events | P1 | L | 006 | DONE — [007-calendar-agenda-recurrence.md](./007-calendar-agenda-recurrence.md) (`advisor/007-calendar-agenda-recurrence` @ `338a187`) |
| 008 | Shopping: multi-list + sync habits | P1 | M | 007 | DONE — [008-shopping-multi-list-habits-sync.md](./008-shopping-multi-list-habits-sync.md) (`advisor/008-shopping-multi-list-habits-sync` @ `4aa40bb`) |
| 009 | Meals: recipe library + templates | P1 | L | 008 | DONE — [009-meals-recipe-library-templates.md](./009-meals-recipe-library-templates.md) (`advisor/009-meals-recipe-library-templates` @ `e0119fc`) |
| 010 | Expenses: recurring bills + charts | P1 | M | 009 | DONE — [010-expenses-recurring-bills-charts.md](./010-expenses-recurring-bills-charts.md) (`advisor/010-expenses-recurring-bills-charts` @ `30bce61`) |
| 011 | Phase 1 — Pillar 2 Family Collaboration (roadmap) | P1 | multi-Q | 005 / Wave 1 | DOC — [011-phase1-pillar2-family-collaboration.md](./011-phase1-pillar2-family-collaboration.md) |
| 012 | Timeline: kinds + freeform posts | P1 | L | 011 | DONE — [012-timeline-kinds-posts.md](./012-timeline-kinds-posts.md) (`advisor/012-timeline-kinds-posts` @ `7591f02`) |
| 013 | Timeline: reactions + comments | P1 | L | 012 | IN PROGRESS — [013-timeline-reactions-comments.md](./013-timeline-reactions-comments.md) |
| 014 | Timeline: pins, announcements, mentions | P2 | M–L | 012, 013 | TODO — [014-timeline-pins-announcements-mentions.md](./014-timeline-pins-announcements-mentions.md) |
| 015 | Shared Notes module | P1 | L | 011 | TODO — [015-shared-notes.md](./015-shared-notes.md) |
| 016 | Family polls | P1 | M | 011 | TODO — [016-family-polls.md](./016-family-polls.md) |
| 017 | Nest presence (active / last seen) | P2 | M | 011 | TODO — [017-nest-presence.md](./017-nest-presence.md) |

## Deferred by request

- Nest-scoped Firestore / Storage **rules** (P0 in 002) — skipped until explicitly requested; **higher risk once Pillar 2 ships presence/notes**.
- Phase 2 AI assistant — after Phase 1 depth.
- Pillar 1 **Wave 2** (photos, barcode, ICS, PDF, etc.) — listed in 005; no executor plans yet.

## Dependency notes

- Pillar 1 Wave 1: `006 → 007 → 008 → 009 → 010` (DONE).
- Pillar 2 Wave A–C: prefer `012 → 013 → 015 → 016 → 014 → 017` (see 011).
- Schema bumps must read live `schemaVersion` before migrating.
- Phase 2 AI must not invent nest fields Pillar 1/2 have not stored.
- Locator last-seen ≠ Presence; entity `notes` ≠ Shared Notes module.

## Findings considered and rejected

- Putting Locator on the widget: privacy/product mismatch with opt-in last-known model.
- Presence on the home widget: same privacy rejection as Locator-on-widget.
- Dark / glass “AI dashboard” widget: conflicts with Casaio pastel brand.
- Interactive App Intents in v1: high complexity vs visual professionalism payoff — defer.
- Full RFC 5545 RRULE in calendar Wave 1: use simple daily/weekly/monthly cadence (007).
- Chart package by default in 010: prefer lightweight custom bars unless pubspec already has a chart lib.
- Full messenger / DMs in Pillar 2: out of scope — timeline + notes + polls only.
