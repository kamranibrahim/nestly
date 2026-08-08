# Plan 016: Add family polls

> Preferred after [015](./015-shared-notes.md) per [011](./011-phase1-pillar2-family-collaboration.md).

## Status

- **Priority**: P1
- **Effort**: M
- **Depends on**: 011
- **Category**: direction
- **Planned at**: commit `51dc7f8`, 2026-08-08

## Why this matters

Lightweight decisions (“What should we eat?” / “When should we travel?”) without leaving Casaio.

## Scope

**In scope**

- Tables: `Polls` (question, status open/closed, createdBy, timestamps, sync flags); `PollOptions` (pollId, label, sort); `PollVotes` (pollId, optionId, memberId — one vote per member)
- Repo: createPoll, vote, closePoll, watchPolls + results counts
- Sync three collections under nest
- UI: Polls list + create sheet + vote + results
- Optional timeline post on create/close
- Examples as composer placeholders only
- l10n; tests

**Out of scope**: ranked-choice, anonymous votes, scheduling integrations

## Done criteria

- Create/vote/close/results offline + sync; `flutter test` passes

## Git

- Branch: `advisor/016-family-polls`
