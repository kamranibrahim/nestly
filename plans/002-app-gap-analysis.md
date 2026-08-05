# Nestly — end-to-end gap analysis (brief)

**Date:** 2026-08-04  
**Scope:** Cold start → splash → auth → onboarding → nest setup → shell tabs → modules → privacy/leave. Read-only survey; no code changes in this pass.  
**Not audited in depth:** Native release signing, Firebase console config, live store listings, device QA of widgets/maps.

---

## Journey (what exists)

| Stage | What ships today |
|-------|------------------|
| Launch | Native solid-blue splash → `AuthGate` (home-shaped skeleton while auth loads) |
| First open | 3-page onboarding → email/password auth (defaults to **Sign up**) |
| Nest | Create nest or join via 6-char code → optional invite sheet |
| Shell | Home · Calendar · Tasks · Shop · Nest (More) + global Add FAB |
| Home depth | Today briefing, family needs, feature grid (Expenses, Vault, Emergency, Locator, Meals, Care, School, Timeline) |
| Sync | Offline-first Drift + Firestore pull/push; home widget publish; reminders (bills/care/school + optional tomorrow preview) |
| Exit | Export JSON, leave nest, delete account, sign out |

**Verdict:** Core “family organizer” modules match the App Store listing. Soft-launch free claim holds. Gaps below are where depth, honesty, or production safety lag the pitch.

---

## Where we’re lacking

### P0 — Ship blockers / trust

1. **Firestore & Storage rules are auth-only**  
   Any signed-in user can read/write all nests and vault objects (`firestore.rules`, `storage.rules`). No membership checks. Highest privacy/multi-family risk.

2. **Account deletion is incomplete**  
   Deletes Auth user + member/location docs + local DB; does **not** wipe Storage vault binaries or cascade nest collections for last member. Export also omits vault files. Store/privacy claims overstate cleanup.

3. **Store / ops checklist still open**  
   No CI (`.github` absent). `STORE_CHECKLIST.md` still unchecked on Auth provider, release builds, Data safety / App Privacy, Maps keys, listing assets process. Local `flutter test` only.

### P1 — Product honesty & multi-device reality

4. **Roles are labels, not permissions**  
   Adult / Kid / etc. filter calendar and assignee UX only. Any member can edit bills, vault, nest settings. Listing’s “right people see the right day” is filter-only.

5. **Sync conflicts are invisible**  
   Dirty / newer `updatedAt` wins (last-write-wins). No “someone else changed this,” merge, or undo for concurrent edits.

6. **“Quiet daily summary” is thin**  
   Home ranking + optional 19:30 tomorrow preview ≠ a crafted daily digest. Bell sheet is mostly a count dump. No task/event reminder channels beyond bills/care/school.

### P2 — Journey friction (splash → first value)

7. **Cold start feels wrong for logged-out users** — Today skeleton before onboarding/auth; blue native splash vs cream app; no branded Flutter splash bridge.  
8. **Auth defaults to Sign up**; weak client validation; email/password only (no Apple/Google); no email verification.  
9. **Invite is code-only** — share text lacks store URLs / `nestly://invite/…` deep link.  
10. **Error/empty unevenness** — sync-error banner can still read like “Last synced”; onboarding finish can stick on spinner; meals/expenses/vault/timeline empty coaching weaker than tasks/calendar/shop.

### P3 — Depth & polish (post-login)

11. **Search** only on Shopping + Vault; missing on Calendar, Tasks, Bills, Care, School, Meals, Timeline.  
12. **Calendar filter vs month dots mismatch** — role filter doesn’t filter month/week dots.  
13. **Tasks** — relative due labels only; recurring is a flag, not real cadence.  
14. **Timeline from Nest tab** — no `onOpenTab`, so some deep links no-op vs Home entry.  
15. **Public copy lag** — privacy/support pages still mention “web companion” after Flutter web removal; Play listing understates Android home widget; `plans/README.md` still says Android widget deferred (stale).

### Relatively strong (don’t over-invest first)

- Module coverage vs listing (calendar, tasks, shop, meals→list, budget/bills, care/school, vault+scan, locator opt-in).  
- Crashlytics / Analytics wiring + Privacy disclosures.  
- iOS + Android home widgets + deep links (verify on device; plan status is wrong).  
- First-run empty cards on several core tabs.

---

## Priority order (recommended)

1. ~~Nest-scoped Firestore + Storage rules~~ **deferred** (explicit skip)
2. Full account / last-member nest + Storage deletion
3. CI (`analyze` + `test`) + close store checklist
4. Conflict UX or at least clearer sync-failure surfacing
5. Splash/auth first-run polish + invite deep links
6. Roles-as-ACL only if product needs kid-safe nests
7. Search / reminders / calendar filter consistency as depth sprints

**Progress (2026-08-04, rules excluded):** items 2–5 and depth sprints partially shipped — nest wipe + Storage delete, CI, sync-failed banner + kept-local notes, auth/first-run polish, invite share URL, Timeline `onOpenTab`, calendar filter dots, search on Tasks/Calendar/Budget, event/task reminders, Meals/Timeline/Budget empty coaching. Still open: Firebase rules (deferred), roles-as-ACL, full conflict merge UI, store checklist ops, Care/School/Meals search.
---

## Suggested follow-up plans (when you pick)

| Candidate | Focus |
|-----------|--------|
| `003` | Nest-scoped security rules + membership helper |
| `004` | Account/nest deletion + Storage wipe |
| `005` | CI + store checklist automation notes |
| `006` | Auth/splash first-run UX |
| `007` | Sync failure + conflict visibility |

Say which IDs to expand into full executor plans.
