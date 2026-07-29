# Store closed testing checklist (Y1 Q3)

Use this when submitting Nestly to Google Play closed testing / Apple TestFlight.

## Before upload

- [ ] Enable Email/Password in Firebase Auth console
- [ ] Deploy rules: `firebase deploy --only firestore:rules,storage`
- [ ] Enable Firebase Storage in console (Get Started) if not already:
  https://console.firebase.google.com/project/nestly-family-os/storage
- [ ] Confirm `com.nestly.nestly` matches store listing package / bundle ID
- [ ] Build release: `flutter build appbundle` / `flutter build ipa`
- [ ] Privacy policy URL live (in-app summary: Explore → Privacy)
- [ ] Store listing screenshots of Home, Calendar, Tasks, Vault
- [ ] Short description: “Nestly — the operating system for modern families.”
- [ ] Data safety / App Privacy: account email, nest content, files, notifications

## Tester flow

1. Sign up with email → create nest (“Start nest”)
2. Invite second tester with code → join nest
3. Add task, check shopping item, upload vault file, add expense/bill
4. Force-quit / airplane mode → confirm offline edits still work
5. Sync when online → both devices see updates
6. Confirm bill reminder notification (local) fires if a bill is due soon

## Known manual steps

- Apple / Google social sign-in not enabled yet
- Nestly Plus paywall arrives in Y1 Q4
