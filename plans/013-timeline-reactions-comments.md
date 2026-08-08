# Plan 013: Add timeline reactions and comments

> **Drift check**: `git diff --stat e67b6ea..HEAD -- lib/data/db/app_database.dart lib/data/repositories.dart lib/data/auth_repository.dart lib/data/enums.dart lib/screens/timeline_screen.dart test/repositories_test.dart test/timeline_nav_test.dart`
>
> **Advisor note**: Base `feature/phase1-pillar1` @ `e67b6ea` (012 merged). Live `schemaVersion` is **19** — bump to **20** for `TimelineReactions`. Prefer comments as `TimelineEvents` with `kind=comment` + `parentId` (already on schema). Do not implement pins UI, mentions, notes, polls, or presence.

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: MED
- **Depends on**: [012](./012-timeline-kinds-posts.md) DONE
- **Category**: direction
- **Planned at**: commit `e67b6ea`, 2026-08-08

## Why this matters

Posts without reactions/comments stay broadcast-only. Light social affordances make the family wall feel shared without becoming a messenger.

## Current state (pre-012)

Timeline is message-only. After 012: kinds + posts + `parentId` column reserved.

## Scope

**In scope**

- Table `TimelineReactions`: id, nestId, eventId, memberId, emoji (short string), dirty/deleted/timestamps — unique per (eventId, memberId) or allow change
- Comments: either rows with `TimelineEvents.kind = comment` + `parentId` **or** `TimelineComments` table — prefer **reuse TimelineEvents with kind=comment and parentId** to avoid dual sync paths
- Repo: addReaction, removeReaction, watchReactions(eventId); addComment(parentId, body)
- Sync collections `timelineReactions` and/or comment events via existing timeline push if kind=comment
- UI: react chip row under event; expand comments; composer for reply
- l10n; tests

**Out of scope**: mentions/notifications, pins UI, polls, notes, presence

## Steps

1. Schema + migration for reactions (and comment kind if needed)
2. Repository + sync
3. Timeline UI affordances
4. Tests

## Done criteria

- React and comment persist + sync
- `flutter test` passes
- No pins/mentions/polls

## STOP

- Building a full chat thread UX — keep flat comments under one parent
- OT presence for typing indicators

## Git

- Branch: `advisor/013-timeline-reactions-comments`
