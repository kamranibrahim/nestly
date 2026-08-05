# lib/state

Ephemeral, per-screen UI state (busy flags, obscure toggles, page index,
selection, filters, form controllers) lives here as `StateNotifier` +
`StateNotifierProvider.autoDispose` pairs — one state class, one controller,
one provider per screen (see `vault_ui.dart`, `locator_ui.dart`, etc.).

- Screens should be `ConsumerWidget`, not `ConsumerStatefulWidget`. If a
  screen owns a controller with real lifecycle needs (e.g. `PageController`,
  `AnimationController`), put that controller on the `StateNotifier` instead
  and dispose it in the notifier's `dispose()`.
- Small, self-contained form sheets/dialogs (multiple text fields, one-shot
  submit) may stay local `StatefulWidget`s when moving them out wouldn't
  simplify anything — that's a judgment call, not a hard rule.
- Persisted/synced data — Drift tables, Firebase, repositories — stays in
  `lib/data` and is exposed to screens via `lib/providers`. Nothing in
  `lib/state` should read/write the database or network directly.
- Shared domain / UI enums (filters, folders, upload status, deep links)
  live in `lib/data/enums.dart`. Screens and controllers should switch on
  those types, not hardcoded strings.
