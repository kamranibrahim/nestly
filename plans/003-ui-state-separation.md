# Plan 003 — UI / logic separation (Riverpod)

**Status:** Done (2026-08-04)

## Goal
Move ephemeral screen UI state out of `setState` into Riverpod `StateNotifier`s under `lib/state/`, and prefer `ConsumerWidget` screens.

## Layout
See `lib/state/README.md`. Controllers: vault, shopping, tasks, calendar, expenses, care, school, meals, timeline, shell, locator, auth, privacy, onboarding, reset_password.

## Still Stateful (by design)
- `AppShell` — bridges `nestlyShellTabRequest` ValueNotifier
- `_SyncedShell` — app lifecycle observer
- Locator — `DraggableScrollableController` lifecycle only
- Vault/scan/password **sheets** — short-lived form fields

## Verify
`flutter test` + `flutter analyze`
