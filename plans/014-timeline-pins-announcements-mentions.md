# Plan 014: Timeline pins, announcements, and mentions

> Depends on [012](./012-timeline-kinds-posts.md) + [013](./013-timeline-reactions-comments.md).

## Status

- **Priority**: P2
- **Effort**: M–L
- **Depends on**: 012, 013
- **Category**: direction
- **Planned at**: commit `51dc7f8`, 2026-08-08

## Why this matters

Pins surface must-know items; announcements emphasize adult posts; mentions close the loop with notifications.

## Scope

**In scope**

- Pin/unpin using `pinned` column from 012; sort pinned first in watchRecent
- Announcement kind styling + optional soft “adults compose” filter (roles are labels — UI only)
- `@Member` parse in posts/comments; store mention memberIds; local notification or FCM payload when mentioned (reuse `notification_service` patterns)
- l10n; tests

**Out of scope**: ACL enforcement, presence, notes, polls

## Done criteria

- Pinned events float; announcements visually distinct; mention triggers notify path
- `flutter test` passes

## Git

- Branch: `advisor/014-timeline-pins-announcements-mentions`
