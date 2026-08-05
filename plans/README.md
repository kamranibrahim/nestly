# Implementation Plans

Generated for Nestly home-widget modernization (2026-07-31). Gap analysis added 2026-08-04. Execute in order unless dependencies say otherwise.

## Execution order & status

| Plan | Title | Priority | Effort | Depends on | Status |
|------|-------|----------|--------|------------|--------|
| 001 | Ship a modern Nestly Home Screen widget | P1 | L | — | DONE — iOS + Android layouts + deep links (device QA remaining) |
| 002 | End-to-end app gap analysis (brief) | — | — | — | DOC — [002-app-gap-analysis.md](./002-app-gap-analysis.md) |
| 003 | UI state separation (Riverpod controllers) | P2 | L | — | DONE — see [003-ui-state-separation.md](./003-ui-state-separation.md) + `lib/state/` |

## Deferred by request

- Nest-scoped Firestore / Storage **rules** (P0 in 002) — skipped until explicitly requested.

## Dependency notes

- Phase A (iOS + Flutter snapshot) should land before Phase B (Android) so both platforms share the same keys/hero model.
- Phase C (large size / a11y polish) is optional after A+B.

## Findings considered and rejected

- Putting Locator on the widget: privacy/product mismatch with opt-in last-known model.
- Dark / glass “AI dashboard” widget: conflicts with Nestly pastel brand.
- Interactive App Intents in v1: high complexity vs visual professionalism payoff — defer.


## Dependency notes

- Phase A (iOS + Flutter snapshot) should land before Phase B (Android) so both platforms share the same keys/hero model.
- Phase C (large size / a11y polish) is optional after A+B.

## Findings considered and rejected

- Putting Locator on the widget: privacy/product mismatch with opt-in last-known model.
- Dark / glass “AI dashboard” widget: conflicts with Nestly pastel brand.
- Interactive App Intents in v1: high complexity vs visual professionalism payoff — defer.
