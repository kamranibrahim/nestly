# Plan 001: Ship a modern Nestly Home Screen widget

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 8711b09..HEAD -- ios/NestlyHomeWidget lib/data/nest_home_widget.dart android/`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: L (phased M + M; Android optional L)
- **Risk**: MED (App Group / WidgetKit / Android Glance wiring)
- **Depends on**: none
- **Category**: direction
- **Planned at**: commit `8711b09`, 2026-07-31

## Why this matters

The Nestly home-screen widget is a soft-launch surface that currently reads as a
prototype: system tertiary fill, raw task count + two text rows, no Nestly
pastel brand, no Android implementation (despite Flutter publishing
`androidName`), and a single deep link (`nestly://home`). Families glance at
widgets more often than they open the app — a professional “Today” widget
should feel like Nestly Home (calm pastels, one clear job, privacy-safe), not
a debug dump of three strings.

## Product vision (modern, Nestly-native)

**One job:** answer “What does our nest need today?” in under two seconds.

**Brand rules (match in-app):**
- Soft pastel lime + lavender on white/off-white — **not** dark mode chrome,
  purple gradients, glassmorphism, or neon accents.
- Tokens to mirror from `lib/theme/app_colors.dart`:
  - ink `#1C1C1E`, secondary `#636366`
  - mint `#D4E7B3`, accent `#B2B2E6`, teal `#C5E8E0`, peach `#FFD8A8`
  - surface muted `#F7F7F8`, border `#E5E5EA`
- Typography: bold nest/title, calm secondary captions; monospaced digits for counts.
- No vault data, no Locator pins, no member avatars that imply live tracking.

**Layouts**

| Family | Composition |
|--------|-------------|
| **Small** | Nestly wordmark/mark · hero line (“3 open tasks” or next event) · soft mint/lavender badge · empty/quiet state when nothing due |
| **Medium** | Header: nest name + “Today” · three soft rows/chips: Tasks · Next · Dinner · footer “Updated …” (relative) · tap targets per row when interactive APIs available |
| **Large** *(phase 2)* | Same as medium + up to 2 extra “needs” lines (care due / shopping) using existing Family Needs priority — still no vault |

**Empty / signed-out states**
- No nest: branded empty — “Open Nestly to join a nest” (not generic caption dump).
- Quiet day (has nest, 0 tasks, no event, no dinner): mint wash + “Quiet day · enjoy it”.

**Interaction (phase 2)**
- Small: open Home.
- Medium: Tasks → tasks tab; Next → calendar; Dinner → meals (deep links).
- Optional iOS 17+ `Button` / App Intents for “Mark dinner planned” is **out of scope** for v1 redesign unless time remains after Android.

## Current state

Relevant files:

- `ios/NestlyHomeWidget/NestlyHomeWidget.swift` — WidgetKit UI + App Group reader; `StaticConfiguration`; small + medium only; `.containerBackground(.fill.tertiary)`.
- `lib/data/nest_home_widget.dart` — Flutter publisher via `home_widget`; keys: `open_tasks`, `next_event`, `dinner`, `nest_name`, `has_nest`, `updated_at`.
- Publish callers: `lib/data/sync_controller.dart`, `lib/screens/auth_gate.dart`; clear on leave/sign-out via privacy/auth.
- **No** `android/` Glance/RemoteViews provider exists for `NestlyHomeWidget` (Android name is published but unused).
- Deep link today: only `nestly://home` (`NestHomeWidget.launchUri`).

Excerpt — current medium layout is plain VStack + Divider:

```56:106:ios/NestlyHomeWidget/NestlyHomeWidget.swift
struct NestlyHomeWidgetEntryView: View {
  // … headline nest name + openTasks count …
  // … caption “open tasks” …
  // … if not small: Divider + Next / Dinner rows …
}
```

Excerpt — snapshot fields are minimal:

```36:45:lib/data/nest_home_widget.dart
        HomeWidget.saveWidgetData<int>('open_tasks', snapshot.openTasks),
        HomeWidget.saveWidgetData<String>('next_event', snapshot.nextEvent),
        HomeWidget.saveWidgetData<String>('dinner', snapshot.dinner),
        HomeWidget.saveWidgetData<String>('nest_name', snapshot.nestName),
        HomeWidget.saveWidgetData<bool>('has_nest', snapshot.hasNest),
        HomeWidget.saveWidgetData<String>(
          'updated_at',
          DateTime.now().toIso8601String(),
        ),
```

Conventions: privacy-first (no vault); best-effort publish (never throw into app flows); commit style is imperative sentences (e.g. “Add opt-in Nest Locator…”).

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Tests | `flutter test test/nest_home_widget_test.dart` (create) + `flutter test` | all pass |
| Analyze | `dart analyze lib/data/nest_home_widget.dart` | No issues |
| iOS build (local) | open `ios/Runner.xcworkspace`, build NestlyHomeWidget target / run on device | widget renders with new chrome |
| Android (phase B) | `./gradlew :app:assembleDebug` from `android/` | exit 0; widget listed in picker |

## Suggested executor toolkit

- Match Nestly pastels from `lib/theme/app_colors.dart` — do **not** invent a purple/dark widget theme.
- Reuse Family Needs priority ideas from `lib/data/family_needs.dart` (or equivalent) only for optional large-widget copy — keep snapshot **privacy-safe**.
- `home_widget` package docs for Android provider registration.
- Apple HIG: Widget margins, Dynamic Type, Lock Screen later (deferred).

## Scope

**In scope**
- Phase A (must ship): iOS visual redesign + richer shared snapshot + deep-link URLs + Flutter unit tests for snapshot formatting.
- Phase B (strongly recommended): Android Glance (or RemoteViews) widget that reads the same App Group / SharedPreferences keys `home_widget` already writes.
- Docs touch: short note in `store/LOCATOR_MAPS_SETUP.md` is **wrong place** — add 10–15 lines to `README.md` or `store/` soft-launch notes only if a widget setup section already exists; otherwise `STORE_CHECKLIST.md` one checkbox.

**Out of scope**
- Live Locator / map on the widget.
- Vault filenames or document counts.
- Continuous background refresh beyond existing 30‑minute timeline + app-driven `updateWidget`.
- Lock Screen / watchOS / macOS widgets.
- Interactive App Intents that mutate Nest data (unless leftover capacity after Phase B).
- Redesigning in-app `HomeScreen` itself (widget only).

## Git workflow

- Branch: `feature/home-widget` (or continue from current feature branch if operator prefers).
- Commits: imperative, why-focused; example: `Modernize Nestly Home widget with branded Today layouts.`
- Do NOT push or open a PR unless the operator asks.

## Phased steps

### Phase A1 — Expand privacy-safe snapshot (Flutter)

Update `lib/data/nest_home_widget.dart` / `_WidgetSnapshot` to publish:

| Key | Type | Purpose |
|-----|------|---------|
| `open_tasks` | int | keep |
| `next_event` | string | keep |
| `dinner` | string | keep |
| `nest_name` | string | keep |
| `has_nest` | bool | keep |
| `updated_at` | ISO8601 | keep |
| `hero_kind` | string | `quiet` \| `tasks` \| `event` \| `dinner` — which line is the “main” story for small |
| `hero_title` | string | short hero copy |
| `tasks_label` | string | e.g. `3 open` / `All clear` |
| `event_label` | string | display-ready next event or `Nothing scheduled` |
| `dinner_label` | string | display-ready or `Not planned` |
| `accent` | string | `mint` \| `lavender` \| `teal` \| `peach` — UI hint for small badge wash |

Hero selection rule (deterministic):
1. If open tasks > 0 → `tasks`
2. Else if next event non-empty → `event`
3. Else if dinner non-empty → `dinner`
4. Else → `quiet`

Extract pure helpers (testable without plugins) into `lib/data/nest_home_widget_snapshot.dart` (or keep in same file but top-level functions):
- `selectWidgetHero(...)`
- `formatWidgetUpdatedAt(...)` if needed on Flutter side (Swift can also format)

**Verify**: `dart analyze lib/data/nest_home_widget.dart` → No issues  
**Verify**: new `test/nest_home_widget_test.dart` covers hero selection + label formatting (quiet / tasks / event / dinner) → all pass

### Phase A2 — Modern iOS WidgetKit UI

Rewrite `NestlyHomeWidgetEntryView` in `ios/NestlyHomeWidget/NestlyHomeWidget.swift`:

1. Add Nestly color constants (Swift `Color` hex matching AppColors).
2. Replace `.containerBackground(.fill.tertiary)` with a soft branded background:
   - Base: near-white `#FAFAFB` or mint/lavender wash at ~12–18% for quiet/tasks.
   - Use `containerBackground(for: .widget) { … }` with a subtle vertical gradient (mint → white) — keep contrast high for readability.
3. **Small**: brand row (“Nestly” or nest name) + large hero title + optional count capsule.
4. **Medium**: header + three rows with pastel leading dots (lavender tasks, teal event, mint dinner) — not a dense dashboard.
5. Read new keys with fallbacks so old App Group data still renders.
6. Show relative “Updated …” from `updated_at` on medium only.
7. Keep `widgetURL` default `nestly://home`; prepare per-row `Link`/`widgetURL` only after A3.

Also update asset colorsets if useful (`AccentColor`, `WidgetBackground`) to Nestly mint/lavender — optional if Swift constants suffice.

**Verify**: Build NestlyHomeWidget extension in Xcode; gallery preview shows branded small + medium.  
**Verify**: Placeholder / snapshot still work with empty defaults.

### Phase A3 — Deep links

1. Define URIs (document in `nest_home_widget.dart`):
   - `nestly://home`
   - `nestly://tasks`
   - `nestly://calendar`
   - `nestly://meals`
2. Ensure Flutter app already routes these **or** add minimal routing in the existing deep-link / notification intent path (search for `nestly://` and notification intent handling). If no router exists beyond home, implement a small parser that selects the right tab/screen — match existing navigation patterns (`nestPush`, tab index).
3. On medium widget, wrap each row in a `Link` (iOS 17+) to the matching URI; small keeps `nestly://home`.

**Verify**: Tapping medium “Tasks” opens Nestly on Tasks (device/simulator).  
**Verify**: `flutter test` still green.

### Phase B — Android widget parity

1. Add an Android App Widget provider named `NestlyHomeWidget` compatible with `home_widget` (follow package README for `HomeWidgetProvider` / Glance).
2. Layouts: `widget_small`, `widget_medium` XML or Glance composables mirroring iOS hierarchy and Nestly colors.
3. Register in `AndroidManifest.xml`; add preview strings “Nestly Today”.
4. Read the same preference keys Flutter already writes.

**Verify**: `./gradlew :app:assembleDebug` exit 0  
**Verify**: Widget appears in Android picker; after opening Nestly once, data populates.

### Phase C — Polish (if time)

- Support `.systemLarge` with 1–2 extra need lines (care due count / shopping count) — publish two optional ints from Flutter.
- Accessibility: Dynamic Type, sufficient contrast, `accessibilityLabel` summarizing hero.
- Timeline: keep 30‑min refresh; optionally schedule end-of-dinner-day invalidation — do not add background location.

## Test plan

Create `test/nest_home_widget_test.dart` modeled after `test/locator_models_test.dart` / `test/family_needs_test.dart`:

- Hero picks tasks when openTasks > 0 even if event exists
- Hero picks event when tasks == 0 and event set
- Hero quiet when all empty
- Labels truncate safely (reuse `_short` behavior)
- Deep link constants are non-empty and unique

No need for WidgetKit UI snapshot tests in CI unless the repo already has Swift tests (it does not — skip).

## Done criteria

- [ ] iOS small + medium look branded (pastel wash, clear hierarchy) — not system tertiary list
- [ ] Shared snapshot includes hero fields; Flutter tests pass
- [ ] Deep links for home/tasks/calendar/meals work from widget (or documented partial if Android-only delay)
- [ ] Android widget exists **or** Phase B explicitly deferred in PR description with operator OK
- [ ] Still no vault / locator data on widget
- [ ] `flutter test` exit 0; `dart analyze` clean on touched Dart files
- [ ] `plans/README.md` status updated

## STOP conditions

- App Group id `group.app.nestly.family` entitlement missing / mismatched — stop; do not invent a new group without operator.
- Deep-link routing requires rewriting the entire nav shell — stop and propose a minimal tab-index approach first.
- Android Glance conflicts with minSdk / AGP in a way that blocks assemble — stop after documenting; ship Phase A alone.
- Any request to show vault or live location on the widget — refuse; out of scope.

## Maintenance notes

- Whenever Home “Family Needs” priority changes, reconsider `hero_kind` rules so widget and Home stay aligned.
- Publish path must remain best-effort in sync/auth flows.
- Reviewer should check: contrast on mint wash, Dynamic Type clipping on small, and that Android keys match iOS exactly.
- Deferred: Lock Screen accessory, interactive complete-task, large family roster.

## Design reference (executor UI checklist)

Small (conceptual):

```
┌─────────────────────┐
│ Nestly        [mint]│
│                     │
│ 3 open tasks        │  ← hero
│ Soccer @ 4pm        │  ← secondary whisper
└─────────────────────┘
```

Medium (conceptual):

```
┌──────────────────────────────────────┐
│ The Nestly Family          Today     │
│                                      │
│ ●  Tasks      3 open                 │
│ ●  Next       Soccer · Tue · 4:00 PM │
│ ●  Dinner     Pasta night            │
│                          Updated 2m  │
└──────────────────────────────────────┘
```
