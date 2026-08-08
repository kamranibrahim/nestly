# Plan 015: Add shared notes module (grocery / school / house / medical)

> **Executor instructions**: Follow step by step. Verify each step. SKIP `plans/README.md` if reviewer maintains the index.
>
> **Drift check**: `git diff --stat a18e2c8..HEAD -- lib/data/db/app_database.dart lib/data/repositories.dart lib/data/auth_repository.dart lib/data/enums.dart lib/providers/providers.dart lib/screens/notes_screen.dart lib/screens/more_screen.dart lib/screens/home_screen.dart lib/l10n/ test/`
>
> **Advisor note**: Base `feature/phase1-pillar1` @ `a18e2c8` (014 merged). Live `schemaVersion` is **21** — bump to **22** for `SharedNotes`. Entity `notes` on care/vault/school/recipes are **not** this module. Do not build polls/presence. Optional quiet timeline activity on create/update is nice-to-have, not required.

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: LOW–MED
- **Depends on**: [011](./011-phase1-pillar2-family-collaboration.md); preferred after timeline Wave A (012–014 DONE)
- **Category**: direction
- **Planned at**: commit `a18e2c8`, 2026-08-08

## Why this matters

Families park scraps in group chats. Nest-synced notes by category replace that without a messenger.

## Current state

- No `SharedNotes` table
- Entity `notes` columns elsewhere stay entity-local
- More/Home navigate via `nestPush` to module screens (mirror Timeline / Vault pattern)

## Commands

| Purpose | Command | Expected |
|---------|---------|----------|
| Codegen | `dart run build_runner build --delete-conflicting-outputs` | Exit 0 |
| Tests | `flutter test test/repositories_test.dart` | Pass |
| Full | `flutter test` | Pass |

## Scope

**In scope**

- Table `SharedNotes`: id, nestId, title, body, category (`grocery|school|house|medical`), updatedByMemberId, dirty/deleted/createdAt/updatedAt
- Enum `SharedNoteCategory` (or string helpers) in `enums.dart`
- Repo CRUD + `watchNotes({category?})` ordered by updatedAt desc
- Sync `nests/{id}/sharedNotes/{id}` push/pull LWW (mirror Recipes)
- Provider wiring in `providers.dart`
- UI: `notes_screen.dart` — category chips, list, create/edit sheet (**StatefulWidget**-owned controllers), soft-delete
- Entry from More (+ optional Home shortcut)
- Privacy banner/copy: medical notes are nest-visible, not E2E encrypted (Vault for sensitive files)
- l10n EN+AR; repository tests

**Out of scope**

- OT co-editing, encryption, rich markdown, attachments
- Polls (016), presence (017)
- Hard ACL by role

## Steps

### Step 1: Schema + enum + migration

Add `SharedNotes` table; register in `@DriftDatabase`; bump `schemaVersion` **21 → 22**; `if (from < 22) await _createTableIfMissing(m, sharedNotes);`. Never pass Drift `Variable<>` into `customStatement` args.

**Verify**: codegen succeeds; app opens / `ensureSeeded` still works (no seed required).

### Step 2: Repository + provider

- `SharedNotesRepository` (or methods on a nest notes repo): `watchNotes`, `addNote`, `updateNote`, `deleteNote` (soft)
- Set `updatedByMemberId` from current member meta when writing
- Provider + optional stream providers for UI

**Verify**: repository tests — CRUD per category; soft-delete hides from watch; update bumps updatedAt + dirty.

### Step 3: Sync

Mirror Recipes: `_pushSharedNotes` / `_pullSharedNotes` in sync loop; fields include title, body, category, updatedByMemberId, timestamps, deleted handling.

**Verify**: push/pull present; analyze clean.

### Step 4: UI + l10n

- `NotesScreen` with category filter chips; empty states; NestCard list rows
- Create/edit bottom sheet: title + body + category; StatefulWidget controllers (dispose in State)
- More entry (and optional Home); medical category shows short privacy note
- Optional: quiet `TimelineKind.activity` (or existing activity kind) on create/update — skip if awkward

**Verify**: `flutter test` full; analyze notes + more screens.

## Test plan

- Add grocery note → appears under grocery filter
- Update medical note → category/privacy copy visible; updatedAt newer
- Soft-delete → gone from watch
- Sync fields round-trip in push map (unit/repo as feasible)

## Done criteria

- [ ] CRUD + category filter offline
- [ ] Sync push/pull for `sharedNotes`
- [ ] More (and optional Home) entry
- [ ] Medical privacy copy present
- [ ] `flutter test` passes
- [ ] No polls/presence/OT/encryption

## STOP conditions

- Schema version conflict — re-read live `schemaVersion` first
- Confusion with entity `notes` columns — do not overload those
- Never pass `Variable<>` into `customStatement` args

## Git workflow

- Branch: `advisor/015-shared-notes`
- Do not push unless asked
