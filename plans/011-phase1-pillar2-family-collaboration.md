# Plan 011: Phase 1 — Pillar 2 Family Collaboration (roadmap)

> **Type**: DOC / product roadmap index.  
> **Active scope**: Phase 1 **Pillar 2 — Family Collaboration** only.  
> Builds on Pillar 1 Wave 1 (006–010 DONE) and existing timeline + members.  
> Grounded in `PROJECT_IMPLEMENTATION.md` and codebase survey at commit `a27f840`.

## Status

- **Priority**: P1
- **Effort**: multi-quarter
- **Category**: direction
- **Planned at**: commit `a27f840`, 2026-08-08
- **Related**: [005](./005-phase1-family-os-foundation.md) (Pillar 1), [002](./002-app-gap-analysis.md)

---

## Frame

| Pillar | Job |
|--------|-----|
| Pillar 1 | Best everyday family organizer (tasks, calendar, shop, meals, money) |
| **Pillar 2** | **Family feels together in-app** — presence, richer shared activity, notes, lightweight decisions |
| Phase 2 (later) | AI assistant on nest data — must not invent collaboration fields this pillar does not store |

### Pillar 2 success means

- Members know who is around (without turning Casaio into a chat app)
- Timeline is a living family wall, not only system auto-logs
- Shared notes replace scattered “put it in the group chat” scraps
- Simple polls settle everyday decisions (“what’s for dinner?”)

### Already shipped (reuse, do not rebuild)

| Asset | Role for Pillar 2 |
|-------|-------------------|
| `NestMembers` + roles (labels) | Identity for presence, mentions, poll voters |
| `TimelineEvents` + `TimelineRepository` + `nests/{id}/timeline` | Activity wall foundation |
| `timeline_nav.dart` / `TimelineModule` | Module filters + deep links |
| Locator last-known | **Geo** last seen only — not app presence; keep privacy model |
| Entity `notes` fields (care, vault, school, recipes) | Stay entity-local; do not confuse with Shared Notes module |
| Offline-first Drift + LWW sync | Same patterns for new tables |

---

## Product brief → grounded backlog

### Presence

| | Capability | Notes |
|---|------------|--------|
| **Current** | None for online/active/device | `NestMembers` has no presence columns |
| **Current (adjacent)** | Locator “last seen” age | Opt-in location share — **not** app presence |
| **Next** | Online members | Heartbeat / lastHeartbeatAt while app foreground |
| **Next** | Active now | Derived from recent heartbeat (e.g. &lt; 2–5 min) |
| **Next** | Last seen | App session lastSeenAt when backgrounded/offline |
| **Next** | Device status | Optional coarse platform (iOS/Android) — avoid battery-invasive detail |

**Privacy / product constraints**

- Presence must be **nest-scoped**, opt-in or clearly disclosed (More / Privacy)
- Do **not** put presence on the home widget (same rejection as Locator-on-widget)
- Do **not** require always-on background location for presence
- Prefer Firestore ephemeral presence doc or member fields with short TTL; offline UI shows last cached lastSeen

**Recommended first slice:** lastSeenAt + active-now derived from foreground heartbeat (no device fingerprinting).

### Activity Timeline

| | Capability | Notes |
|---|------------|--------|
| **Current** | Append-only activity wall | `message`, `memberId`, `memberName`, `createdAt`; auto-logged from modules |
| **Current** | Module filter pills + tap-to-navigate | String classification via `classifyTimelineMessage` |
| **Next** | Reactions | Emoji react on an event (per member, nest-synced) |
| **Next** | Comments | Thread replies on an event |
| **Next** | Mentions | `@Name` in comments / freeform posts → notify mentioned member |
| **Next** | Pins | Pin important events to top of timeline |
| **Next** | Announcements | Distinct post type (adult-authored, emphasized) — roles remain labels unless ACL lands |

**Design note:** Keep auto-activity rows; add **human posts** as a first-class kind so the wall is not only “Completed X”. Extend schema beyond a bare `message` string (kind, parentId, pinned, etc.) while remaining offline-first.

**Recommended first slices:** structured event kind + freeform post → reactions → comments → pins → mentions/notifications → announcements styling.

### Shared Notes (new module)

| | Capability | Notes |
|---|------------|--------|
| **Current** | No nest notes module | Only entity field notes (care, vault, school, recipes) |
| **Next** | Shared notes boards | Categories/examples: Grocery, School, House, Medical |
| **Next** | Nest-synced CRUD | Title, body, category, updatedBy, timestamps |
| **Next** | Timeline hooks (optional) | “Updated School notes” auto event — keep quiet |

**Recommended first slice:** one `SharedNotes` table + category enum + More/Home entry + sync; Medical notes remain visible to nest (call out privacy in copy — nest-wide, not doctor-encrypted vault).

### Family Polls (new module)

| | Capability | Notes |
|---|------------|--------|
| **Current** | Absent | No poll/vote tables or UI |
| **Next** | Create poll | Question + 2–N options |
| **Next** | Vote | One vote per member (or allow change) |
| **Next** | Examples | “What should we eat?” / “When should we travel?” |
| **Next** | Close / show results | Simple majority; no ranked-choice in v1 |

**Recommended first slice:** polls CRUD + vote + results on a Polls surface; optional “post to timeline” when created/closed.

---

## Sequencing principles

1. **Timeline depth before presence polish** — richer wall drives daily opens; presence is ambient.
2. **Schema before social chrome** — kinds, parentId, reactions table before fancy UI.
3. **Reuse sync patterns** — Drift dirty/updatedAt + `_push*`/`_pull*` LWW; presence may use a lighter live path (document explicitly).
4. **Quiet Casaio** — no noisy chat bubbles, purple glow, or “AI social” chrome; one job per section.
5. **Roles stay labels** unless product asks for ACL (announcements “adults only” may be soft UI filter first).
6. **Trust** — nest-scoped Firestore rules still deferred (002); Pillar 2 increases multi-family risk if rules stay auth-only — call out before shipping presence/notes widely.

---

## Wave plan (Pillar 2)

### Wave A — Timeline becomes a family wall (executor plans next)

| Plan | Focus | Effort |
|------|--------|--------|
| `012` | Timeline schema: kind, parentId, pinned; freeform post composer | L |
| `013` | Reactions + comments on timeline events | L |
| `014` | Pins + announcements styling + mention notify (optional split) | M–L |

### Wave B — Shared Notes

| Plan | Focus | Effort |
|------|--------|--------|
| `015` | Shared Notes module (categories: grocery/school/house/medical) + sync + UI | L |

### Wave C — Polls + Presence

| Plan | Focus | Effort |
|------|--------|--------|
| `016` | Family polls (create, vote, results) | M |
| `017` | Presence: lastSeen / active-now heartbeat (privacy-safe) | M |

**Suggested order:** `012 → 013 → 015 → 016 → 014 → 017`  
(Notes and polls deliver collaboration value while timeline social layers settle; presence last because it needs clear privacy UX.)

Alternate if presence is product-critical: insert `017` after `012`.

---

## Conventions for Pillar 2 executors

- Offline-first Drift + sync; bump `schemaVersion` from live value
- Ephemeral UI in `lib/state/`; repos in `lib/data/repositories.dart`
- i18n EN + AR for all new strings
- Tests: extend `test/repositories_test.dart` + `test/timeline_nav_test.dart` where classification changes
- Match Care/Tasks cadence and timeline append patterns already in repo
- Do not put presence or medical note previews on the home widget

### Verification baseline

```bash
flutter test test/repositories_test.dart test/timeline_nav_test.dart
flutter analyze lib/data lib/screens lib/state
flutter test
```

---

## Explicit non-goals (Pillar 2)

- Full messenger / DMs
- End-to-end encrypted medical vault-as-notes (use Vault for files)
- Replacing Locator with presence
- OT/CRDT co-editing of notes (LWW + “updated by” is enough for v1)
- Phase 2 AI auto-posting to timeline without user confirm

---

## STOP / maintainers

- Do not treat Locator last-seen as Presence Done.
- Do not overload entity `notes` columns for Shared Notes.
- Do not invent chat threads separate from timeline without updating this DOC.
- Spin executor plans (`012`+) only when a wave slice is selected.
