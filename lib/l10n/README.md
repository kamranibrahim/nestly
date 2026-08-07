# Casaio translations

English is the source language. Arabic (`ar`) is Modern Standard Arabic for short UI copy.

## Files

- `app_en.arb` — template / source strings
- `app_ar.arb` — Arabic translations
- Generated `app_localizations*.dart` (checked in so CI does not need a separate gen step)

Regenerate after ARB edits:

```bash
flutter gen-l10n
```

## Key naming

- `common*` — shared actions (`Save`, `Cancel`, `Delete`)
- `tab*` / `screen*` — navigation chrome
- `auth*` / `onboarding*` / `nestSetup*` — pre-auth
- `need*` — Home family-needs copy
- `notif*` — local notification titles, bodies, channel names
- `widget*` — home-screen widget snapshot copy

Use ICU plurals for counts:

```json
"needTasksOpen": "{count, plural, =1{1 open task} other{{count} open tasks}}"
```

## Do not translate

- Brand name **Casaio**
- User-generated content (task titles, notes, nest names, invite codes)
- Persisted enum / role storage labels (`Today`, `Elder`, `Family`, `Dinner` meal type)
- Timeline history sentences stored in Drift / Firestore

Localize those only at display time via `*.display(l10n)` / `localizedMemberRole`.

## Language override

More → Settings → Language persists `syncMeta.appLocale` as `system` | `en` | `ar`.
System follows the device when it is English or Arabic; otherwise English.

## Review

Arabic strings are professional MSA drafts. Flag uncertain phrasing in `@` metadata on the English template only — never in visible UI.
