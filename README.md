# Nestly

The operating system for modern families.

## Stack

- Flutter + Material 3
- Drift (SQLite) offline-first
- Firebase Auth + Cloud Firestore sync
- Riverpod

## Firebase

Project: `nestly-family-os`

Before first sign-up, enable **Email/Password** in:

https://console.firebase.google.com/project/nestly-family-os/authentication/providers

Firestore rules are in `firestore.rules` (already deployable via `firebase deploy --only firestore:rules`).

## Run

```bash
flutter pub get
dart run build_runner build
flutter run
```

## Year 1 Q1 status

- [x] Firebase project + Android/iOS apps
- [x] Email auth screens + nest create/join (invite code)
- [x] Drift schema for tasks, shopping, calendar, members
- [x] Drift ↔ Firestore last-write-wins sync
- [ ] Enable Email/Password in Firebase Console (manual)
- [ ] Apple / Google sign-in providers
