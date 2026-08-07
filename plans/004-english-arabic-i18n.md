# 004 — English + Arabic i18n

Status: **DONE** (2026-08-05)

## What landed

- Flutter gen-l10n with `en` + `ar`, in-app language override (More → Settings)
- RTL + Noto Sans Arabic when resolved locale is Arabic
- UI chrome, family-needs copy, auth/onboarding, notifications, home-widget Dart snapshot
- Native widget fallbacks: iOS `en.lproj` / `ar.lproj`, Android `values` / `values-ar`
- Locale preference tests + translator README (`lib/l10n/README.md`)

## Out of scope (unchanged)

- App Store / Play listing localization
- `web/privacy.html` / `web/support.html`
- Timeline history translation / stored enum label migration
- FCM server payload language
- Extra languages beyond Arabic
