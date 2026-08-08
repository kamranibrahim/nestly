# Plan 015: Add shared notes module (grocery / school / house / medical)

> Depends on Pillar 2 roadmap [011](./011-phase1-pillar2-family-collaboration.md). Can run after 012; preferred after 013 per 011 order.
>
> Live schema: read HEAD — expect **20+** after timeline waves; bump next free int.

## Status

- **Priority**: P1
- **Effort**: L
- **Depends on**: 011 (012 preferred)
- **Category**: direction
- **Planned at**: commit `51dc7f8`, 2026-08-08

## Why this matters

Families park scraps in group chats. Nest-synced notes by category replace that without a messenger.

## Current state

No `SharedNotes` table. Entity `notes` on care/vault/school/recipes are **not** this module.

## Scope

**In scope**

- Table `SharedNotes`: id, nestId, title, body, category (`grocery|school|house|medical`), updatedByMemberId, dirty/deleted/createdAt/updatedAt
- Repo CRUD + watch by category
- Sync `nests/{id}/sharedNotes/{id}`
- UI: Notes screen from More/Home; category chips; create/edit sheet (StatefulWidget controllers)
- Privacy copy: medical notes are nest-visible, not E2E encrypted (Vault for files)
- Optional quiet timeline activity on create/update
- l10n; tests

**Out of scope**: OT co-editing, encryption, rich markdown, attachments (Wave later)

## Done criteria

- CRUD + sync per category; `flutter test` passes

## Git

- Branch: `advisor/015-shared-notes`
