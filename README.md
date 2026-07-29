# Nestly

The operating system for modern families.

## Stack

- Flutter + Material 3
- Drift (SQLite) offline-first
- Firebase Auth + Cloud Firestore sync
- Firebase Storage (family vault files)
- Riverpod

## Firebase

Project: `nestly-family-os`

Before first sign-up, enable **Email/Password** in:

https://console.firebase.google.com/project/nestly-family-os/authentication/providers

Firestore rules are in `firestore.rules` (already deployable via `firebase deploy --only firestore:rules`).
Storage rules are in `storage.rules` (`firebase deploy --only storage`).

## Run

```bash
flutter pub get
dart run build_runner build
flutter run
```

## Year 1 status

### Q1
- [x] Firebase project + Android/iOS apps
- [x] Email auth screens + nest create/join (invite code)
- [x] Drift schema for tasks, shopping, calendar, members
- [x] Drift ↔ Firestore last-write-wins sync
- [ ] Enable Email/Password in Firebase Console (manual)
- [ ] Apple / Google sign-in providers

### Q2
- [x] Expenses + bills (offline + sync)
- [x] Emergency center (offline-first + sync)
- [x] FCM token registration + local bill reminders
- [x] Faster nest onboarding

### Q3
- [x] Family vault (local + Firebase Storage upload)
- [x] Timeline / family wall (offline + sync)
- [x] In-app privacy summary
- [x] Closed-testing checklist (`STORE_CHECKLIST.md`)
- [ ] Play / App Store closed testing submission (manual)
