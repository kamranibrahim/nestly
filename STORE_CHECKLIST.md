# Store closed testing checklist

Nestly soft-launches **without a paywall**. Core family features stay free.

## Before upload

- [ ] Enable Email/Password in Firebase Auth console
- [x] Deploy rules: `firebase deploy --only firestore:rules,storage` (auth-only)
- [x] Enable Firebase Storage in console + deploy storage rules
- [ ] Confirm `com.nestly.nestly` matches store listing package / bundle ID
- [ ] Build release: `flutter build appbundle` / `flutter build ipa`
- [ ] Privacy policy URL live (in-app: Nest → Privacy — includes export + delete)
- [ ] Store listing screenshots of Home, Calendar, Tasks, Vault, Nest/Privacy
- [ ] Short description: “Nestly — the operating system for modern families.”
- [ ] Data safety / App Privacy: account email, nest content, files, notifications, optional document-scan AI

## Optional AI scan (not required for store)

- [x] Mobile scan uses **Firebase AI Logic → Vertex AI Gemini**
- [ ] Firebase project on **Blaze** + Vertex AI Gemini API enabled in Build → AI
- [x] Harden scan AI acceptance UX (hint picker, editable review, clearer errors)
- [ ] (Optional) Web companion: https://glowing-strudel-442ff8.netlify.app
  - Add domain in Firebase Auth → Authorized domains if using web sign-in

## Tester flow

1. Sign up with email → create nest (“Start nest”)
2. Invite second tester with code → join nest
3. Add task, check shopping item, upload vault file, add expense/bill
4. Nest → Privacy → Export nest data (share JSON)
5. Force-quit / airplane mode → confirm offline edits still work
6. Sync when online → both devices see updates
7. Confirm bill reminder notification (local) fires if a bill is due soon
8. (Optional) FAB → Scan receipt / invite → review draft → save

## Known manual steps

- Apple / Google social sign-in not enabled yet
- **No Nestly Plus paywall** — free soft launch by design
- Enable Firebase Storage in console before vault cloud upload
- Account delete may require a fresh sign-in (`requires-recent-login`)
