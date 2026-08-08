# Plan 017: Add privacy-safe nest presence (active now / last seen)

> Preferred last in Pillar 2 wave order ([011](./011-phase1-pillar2-family-collaboration.md)).

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: MED (privacy)
- **Depends on**: 011
- **Category**: direction
- **Planned at**: commit `51dc7f8`, 2026-08-08

## Why this matters

Families want to know who is around in-app. Must not confuse with Locator geo last-seen or put presence on the widget.

## Scope

**In scope**

- Fields or `MemberPresence` docs: `lastSeenAt`, optional `platform` (ios/android), `active` derived client-side (&lt; N minutes)
- Foreground heartbeat while app resumed; update on pause
- Sync: Firestore `nests/{id}/presence/{memberId}` (live-friendly) and/or member fields — document choice; offline shows cached lastSeen
- UI: member chips on Home or More — Active / Last seen relative time
- Privacy: disclose in Privacy screen; nest-scoped only
- l10n; tests for derive-active helper

**Out of scope**: Locator changes, widget presence, device fingerprinting, always-on background GPS, typing indicators

## Done criteria

- Heartbeat updates lastSeen; UI shows active vs last seen; no widget presence
- `flutter test` passes

## STOP

- Requiring background location for presence
- Shipping without Privacy copy update

## Git

- Branch: `advisor/017-nest-presence`
