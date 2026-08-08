# Plan 012: Add timeline event kinds and freeform family posts

> **Executor instructions**: Follow step by step. Run every verification before the next step. On STOP conditions, stop and report. SKIP updating `plans/README.md` if a reviewer maintains the index.
>
> **Drift check**: `git diff --stat 51dc7f8..HEAD -- lib/data/db/app_database.dart lib/data/repositories.dart lib/data/auth_repository.dart lib/data/enums.dart lib/data/timeline_nav.dart lib/screens/timeline_screen.dart lib/state/timeline_ui.dart test/timeline_nav_test.dart test/repositories_test.dart`
>
> **Advisor note**: Base `feature/phase1-pillar1` @ `51dc7f8`. Live `schemaVersion` is **18** — bump to **19**. Pillar 2 Wave A first slice ([011](./011-phase1-pillar2-family-collaboration.md)). Do not implement reactions/comments/polls/notes/presence here.

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: MED (timeline sync + nav classification)
- **Depends on**: [011](./011-phase1-pillar2-family-collaboration.md)
- **Category**: direction
- **Planned at**: commit `51dc7f8`, 2026-08-08

## Why this matters

Timeline today is an append-only log of system strings (`Completed "…"`). Families need to post human messages so the wall becomes a collaboration surface. Structured `kind` unblocks reactions/comments/pins later without string-hacking.

## Current state

- `TimelineEvents` (`app_database.dart` ~181–193): `id`, `nestId`, `message`, `memberId`, `memberName`, `dirty`, `deleted`, `createdAt` — no kind/parent/pin/updatedAt
- `schemaVersion => 18`
- `TimelineRepository.add({message, memberId, memberName})` only
- Sync `_pushTimeline` / `_pullTimeline`: message + member + createdAt; pull limit 100; skips if `local.dirty`
- UI: `timeline_screen.dart` filters via `classifyTimelineMessage(e.message)` string matching
- Auto writers: tasks/shop/care/etc. call `TimelineRepository.add(message: '…')`

## Commands

| Purpose | Command | Expected |
|---------|---------|----------|
| Codegen | `dart run build_runner build --delete-conflicting-outputs` | Exit 0 |
| Nav tests | `flutter test test/timeline_nav_test.dart` | Pass |
| Repo tests | `flutter test test/repositories_test.dart` | Pass |
| Full | `flutter test` | Pass |

## Scope

**In scope**

- Schema: `kind` (text, default `'activity'`), `parentId` (nullable text, unused until 013 but column ready), `pinned` (bool default false), optional `updatedAt` for future edits
- Enum `TimelineKind` { activity, post, announcement } — announcement styling can be minimal in 012 (same as post or slight emphasis); full announcement UX in 014
- Migration `from < 19`: add columns; backfill `kind = 'activity'` for existing rows
- `TimelineRepository.add` accepts `kind` (default activity); `addPost({body, memberId, memberName})` → kind post
- Sync push/pull new fields; default kind activity on pull if missing
- `timeline_nav`: classify by `kind` first (post/announcement → other or new `TimelineModule.family`); keep message heuristics for activity
- UI: composer (text field + Post) on timeline; list shows posts distinctly from activity (subtle label)
- Resolve current member id/name from members/auth providers like other screens
- l10n EN/AR
- Tests: addPost persists kind; classify post; existing activity classification still works
- Seed: optional sample post

**Out of scope**

- Reactions, comments threads, @mentions, pin UI, presence, notes, polls (013+)
- Full chat / DMs
- Changing Firestore security rules

## Steps

### Step 1: Schema 19

Add columns; register migration; codegen.

**Verify**: codegen exit 0.

### Step 2: Repository + sync

Extend add APIs; push/pull `kind`, `parentId`, `pinned`, `updatedAt` if added.

**Verify**: repository test creates post with kind `post`.

### Step 3: Nav + UI

Update classification; composer + list rendering; StatefulWidget-owned controller for composer (or dispose safely).

**Verify**: `flutter test test/timeline_nav_test.dart`; full `flutter test`.

## Done criteria

- [ ] Existing auto-activity rows still appear (kind activity)
- [ ] User can create a freeform post offline and it syncs
- [ ] schemaVersion 19
- [ ] `flutter test` passes
- [ ] No reactions/comments/notes/polls

## STOP conditions

- Classification rewrite breaks all deep links — stop and keep heuristics for activity
- Schema version conflict — read live version first
- `customStatement` with `Variable<>` — use plain Dart values (see grocery habits fix)

## Git workflow

- Branch: `advisor/012-timeline-kinds-posts`
- Commit focused messages; do not push unless asked
