# Plan 014: Timeline pins, announcements, and mentions

> **Executor instructions**: Follow step by step. Verify each step. SKIP `plans/README.md` if reviewer maintains the index.
>
> **Drift check**: `git diff --stat ddaf75b..HEAD -- lib/data/db/app_database.dart lib/data/repositories.dart lib/data/auth_repository.dart lib/data/enums.dart lib/data/notification_service.dart lib/data/notification_intent.dart lib/screens/timeline_screen.dart lib/data/member_roles.dart test/`
>
> **Advisor note**: Base `feature/phase1-pillar1` @ `ddaf75b` (013 merged). Live `schemaVersion` is **20**. `pinned` column already exists — wire pin/unpin + sort. `TimelineKind.announcement` exists — add compose + styling. Mentions are new. Do not build notes/polls/presence.

## Status

- **Priority**: P2
- **Effort**: M–L
- **Risk**: MED (notifications)
- **Depends on**: [012](./012-timeline-kinds-posts.md), [013](./013-timeline-reactions-comments.md) DONE
- **Category**: direction
- **Planned at**: commit `ddaf75b`, 2026-08-08

## Why this matters

Pins surface must-know items; announcements emphasize adult posts; mentions close the loop with notifications — without turning timeline into a full messenger.

## Current state

- `TimelineEvents.pinned` bool exists (default false) but UI/repo do not toggle or sort by it
- `TimelineKind.announcement` exists; UI has a label helper; composer only creates `post`
- No mention parsing or storage; no timeline notification destination required yet
- Roles are labels via `member_roles.dart` (Adult/Co-parent/etc.) — soft UI only for “who can announce”
- `NotificationService` + `NotificationIntent` / destinations for modules — extend for timeline if needed

## Commands

| Purpose | Command | Expected |
|---------|---------|----------|
| Codegen | `dart run build_runner build --delete-conflicting-outputs` | Exit 0 if schema changes |
| Tests | `flutter test test/repositories_test.dart test/timeline_nav_test.dart test/notification_intent_test.dart` | Pass |
| Full | `flutter test` | Pass |

## Scope

**In scope**

- `TimelineRepository.setPinned(id, pinned)` + `watchRecent` orders pinned first then `createdAt` desc
- Sync already has `pinned` — ensure toggle sets `dirty` + `updatedAt`
- UI: pin/unpin action on top-level events; visual pin indicator; pinned section or sort-only
- Announcements: composer option (or secondary action) to post as `TimelineKind.announcement`; stronger card styling; soft gate — prefer adults (`MemberRoles` adult-like) for announce compose, still allow if solo/no role match without hard ACL
- Mentions: parse `@Name` tokens against nest member display names (case-insensitive); store mentioned member ids on event (new nullable text column `mentionIds` JSON/CSV — bump schema **21**); on create post/comment with mentions, show local notification to current device only if mentioned id == current member (FCM fan-out to other devices is optional best-effort if token plumbing is trivial — prefer local notify + timeline deep link; document if FCM to others skipped)
- Add `NotificationDestination.timeline` (or reuse existing) + payload open Timeline
- l10n EN/AR; tests for pin sort, announcement kind, mention parse helper

**Out of scope**

- Roles-as-ACL / server enforcement
- Presence, shared notes, polls
- Full rich text editor / autocomplete mention picker (simple `@Name` parse is enough; optional simple member chip insert is OK)
- Encrypting mentions

## Steps

### Step 1: Repo pins + sort

`setPinned`; update `watchRecent` ordering (pinned desc, then createdAt desc). Tests.

**Verify**: repository test pins float above unpinned.

### Step 2: Mentions schema + parse

Schema 21: `mentionIds` text nullable on `TimelineEvents`. Pure helper `parseTimelineMentions(body, members) -> List<String> ids`. Wire into `addPost` / `addComment`. Sync field. Local mention notification helper.

**Verify**: codegen; unit/repo tests for parse + storage.

### Step 3: UI

Pin control; announcement compose + styling; optional @ hint in composer; notification intent test if destination added.

**Verify**: `flutter test` full.

## Done criteria

- [ ] Pinned events sort first; pin toggles sync
- [ ] Announcements visually distinct and creatable
- [ ] Mentions parsed/stored; notify path for current member when mentioned
- [ ] `flutter test` passes
- [ ] No notes/polls/presence

## STOP conditions

- Hard ACL required mid-flight — keep soft UI filter and report
- FCM fan-out to other members blocked — ship local notify + stored mentions; note in NOTES
- Schema version conflict — read live `schemaVersion` first
- Never pass `Variable<>` into `customStatement` args

## Git workflow

- Branch: `advisor/014-timeline-pins-announcements-mentions`
- Do not push unless asked
