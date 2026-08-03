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
Next 16 weeks: see [`FOUR_MONTH_PLAN.md`](FOUR_MONTH_PLAN.md) (web paused; no domain required).

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
- [x] Four-month execution (Home→widget→a11y→Nest hub→tests); see `FOUR_MONTH_PLAN.md`
- [x] Nestly Plus one-pager only (`store/NESTLY_PLUS_ONE_PAGER.md`) — **no paywall code**
- [ ] Store public listing / TestFlight external (manual — see `STORE_CHECKLIST.md`)
- [ ] Nestly Plus paywall (deferred; one-pager only)

## Year 2 status

### Depth (first slice)
- [x] Weekly meal plan → push ingredients to shopping
- [x] Care schedules (home / pet / car) with due + mark done
- [x] Quiet “Today for your nest” summary on Home (local, no chatbot)
- [ ] Web experience (planned in JS — Flutter web companion removed)
- [x] Model-backed quiet AI via Firebase AI Logic → Vertex AI Gemini
- [x] School & activities (sports, pickups, clubs)
- [x] Grocery suggestions from recurring buys (device-local)
- [x] Harden scan AI acceptance UX
- [ ] Store closed testing → public listing (manual)

## Website

Static Netlify site for Privacy / Support (and later a JS web app). Flutter web is not part of this repo anymore.

```bash
./node_modules/.bin/netlify deploy --dir=web --prod --functions=netlify/functions
```
