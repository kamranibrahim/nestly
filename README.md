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

Full horizon: see [`FIVE_YEAR_PLAN.md`](FIVE_YEAR_PLAN.md).

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

### Q4 (free soft launch — no paywall)
- [x] No demo seed in production; wipe local data on nest bind
- [x] Home / Tasks / Lists driven by live nest data
- [x] Forgot password + friendlier auth errors
- [x] Center FAB opens real add flows; About screen
- [ ] Store public listing / TestFlight external (manual)
- [ ] Nestly Plus paywall (deferred)

## Year 2 status

### Depth (first slice)
- [x] Weekly meal plan → push ingredients to shopping
- [x] Care schedules (home / pet / car) with due + mark done
- [x] Quiet “Today for your nest” summary on Home (local, no chatbot)
- [x] Web companion (calendar + tasks + lists)
- [x] Model-backed quiet AI via Firebase AI Logic → Vertex AI Gemini
- [x] School & activities (sports, pickups, clubs)
- [x] Grocery suggestions from recurring buys (device-local)
- [x] Harden scan AI acceptance UX
- [ ] Store closed testing → public listing (manual)

## Web companion

Flutter web app (same repo) that talks to Firestore directly — no local Drift DB.

Live: https://glowing-strudel-442ff8.netlify.app

```bash
flutter run -d chrome
# or
flutter build web --release
./node_modules/.bin/netlify deploy --dir=build/web --prod --no-build --functions=netlify/functions
```

In Firebase Console → Authentication → Settings → Authorized domains, add your Netlify domain (and `localhost` for local runs).

Before first sign-up, enable **Email/Password** in Firebase Authentication → Sign-in method.
