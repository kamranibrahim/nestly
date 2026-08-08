# Plan 013: Add timeline reactions and comments

> **Drift check**: `git diff --stat <012-done-SHA>..HEAD -- lib/data/db/app_database.dart lib/data/repositories.dart lib/data/auth_repository.dart lib/screens/timeline_screen.dart test/`
>
> Depends on [012](./012-timeline-kinds-posts.md). Live schema after 012 should be 19 → bump to **20** (+21 if split tables).

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: MED
- **Depends on**: 012
- **Category**: direction
- **Planned at**: commit `51dc7f8`, 2026-08-08 (refresh SHA after 012 lands)

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
