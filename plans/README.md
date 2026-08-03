# Implementation Plans

Generated for Nestly home-widget modernization (2026-07-31). Execute in order unless dependencies say otherwise.

## Execution order & status

| Plan | Title | Priority | Effort | Depends on | Status |
|------|-------|----------|--------|------------|--------|
| 001 | Ship a modern Nestly Home Screen widget | P1 | L | — | IN PROGRESS — Phase A done (Flutter snapshot + iOS UI + deep links); Phase B Android deferred |

## Dependency notes

- Phase A (iOS + Flutter snapshot) should land before Phase B (Android) so both platforms share the same keys/hero model.
- Phase C (large size / a11y polish) is optional after A+B.

## Findings considered and rejected

- Putting Locator on the widget: privacy/product mismatch with opt-in last-known model.
- Dark / glass “AI dashboard” widget: conflicts with Nestly pastel brand.
- Interactive App Intents in v1: high complexity vs visual professionalism payoff — defer.
