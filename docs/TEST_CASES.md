# Manual Test Cases (Demo Scripts)

Run after each slice ([FEATURE_GUIDE.md](./FEATURE_GUIDE.md) §3). Use **Firebase Console** → project **JobScope** (`flutter-ai-playground-2379c`) → database **`jobscope`** → verify writes.

**Agents:** no git commands; if you changed shared code, run regression rows for affected features below.

**Run app:** `flutter run -d chrome` (two windows = two accounts: normal + incognito).

---

## Demo accounts (create once, reuse)

| Role | Suggested signup | Purpose |
|------|------------------|---------|
| **Recruiter R** | `recruiter.demo@jobscope.test` / `Demo1234!` | Posts jobs, changes applicant status |
| **Candidate C** | `candidate.demo@jobscope.test` / `Demo1234!` | CV, apply, notifications inbox |

**Candidate C — CV setup (required for match / apply tests):**

1. Log in as C → Profile → **My CV** (or Dashboard **Upload CV**).
2. Upload a PDF whose text includes: `Flutter`, `Dart`, `Firebase`, `Riverpod` (or use any real dev CV).
3. Wait for parsing to finish → open **My CV** → confirm skills list not empty.

**Recruiter R — job for matching (reuse across tests):**

1. Log in as R → **Post Job**.
2. Title: `Flutter Developer (Demo)`
3. Company: `JobScope Demo Co`
4. Location: `Remote`
5. Skills: `Flutter`, `Dart`, `Firebase`
6. Requirements: `2+ years mobile`
7. Post → **My Jobs** → note job appears as Active.

---

## Do not redo (extend only)

| If your task is… | Already exists — extend, don’t rebuild |
|------------------|----------------------------------------|
| Apply + application states | `applyNotifierProvider`, `application_repository.dart`, `job_detail_screen.dart` |
| Recruiter accept/reject/shortlist | `applicant_detail_screen.dart`, `job_applicants_screen.dart` |
| Candidate applications list | `features/applications/applications_screen.dart` — **not** `home/.../applications_screen.dart` (stub) |
| Match badge on job cards (candidate) | `jobMatchResultProvider`, `match_badge_widget.dart` |
| Match on recruiter list | Needs `matchScore` on `applications` doc (**D0-1**) — don’t recompute-only in UI |
| Interview practice | `interview_training_screen.dart` — **not** Train Before Apply |
| Local OS alert on status change | `LocalNotificationService` in `candidate_home_screen` — add Firestore inbox, don’t replace |
| Settings / dark theme | `AppTheme.darkTheme` exists — wire `ThemeMode` + screen only |

Check [FEATURE_TRACKER.md](./FEATURE_TRACKER.md) for ✅/🟡 before coding.

---

## David — D0-1: `matchScore` on apply

**Goal:** `applications/{id}.matchScore` is set when C applies to R’s demo job.

| Step | Actor | Action | Expected |
|------|-------|--------|----------|
| 1 | R | Post demo Flutter job (above) | `jobs/{id}` `isActive: true` |
| 2 | C | Jobs → open demo job → **Apply** → confirm | Apply succeeds |
| 3 | — | Firebase → `applications` → latest doc for this `jobId` + `candidateId` | `matchScore` number **roughly 40–95** (not null) if CV has skills |
| 4 | R | My Jobs → demo job → applicants list | Applicant visible; if UI shows score, matches Firestore |
| 5 | C | Apply same job again | “Already applied” / no duplicate doc |

**Edge TC-D0-1-E1:** C with **no CV** applies → application created, `matchScore` null or 0 — no crash.

---

## David — D2: Apply flow + status (verify / polish)

**Prerequisite:** Demo job + C with CV; one application in `pending`.

| Step | Actor | Action | Expected |
|------|-------|--------|----------|
| 1 | C | Applications tab → open application | Detail + timeline shows **Under Review** |
| 2 | R | Applicants → open C → **Shortlist** | Firestore `status: shortlisted`, `updatedAt` set |
| 3 | C | Applications tab (or pull refresh) | Status **Shortlisted**; optional local notification if app open |
| 4 | R | **Reject** another test applicant (or same after reset) | `status: rejected` |
| 5 | C | Pending application → **Withdraw** (if available) | Firestore `status: withdrawn`, `updatedAt` set; doc kept; can re-apply |

**Regression:** Apply + bookmark + job detail still work on another job.

**Automated (run anytime):**

```bash
flutter test test/d2_apply_flow_test.dart
```

### D2 — Test record — 2026-06-05

| Step | Type | Result | Evidence |
|------|------|--------|----------|
| 1 | Manual UI | ⬜ Pending human | C → bottom nav **Applications** → open app → badge **Under Review**; timeline step **Under Review** |
| 2 | Manual + Firestore | ⬜ Pending human | R → **Applicants** → open C → **Shortlist** → `applications/{id}`: `status: shortlisted`, `updatedAt` present |
| 3 | Manual UI | ⬜ Pending human | C → Applications → same app shows **Shortlisted** (live stream; no refresh required) |
| 4 | Manual + Firestore | ⬜ Pending human | R → **Reject** → `status: rejected`, `updatedAt` set |
| 5 | Manual + Firestore | ⬜ Pending human | C → pending app → **Withdraw** → `status: withdrawn` (doc **not** deleted); apply same job again → succeeds |
| Regression | Manual UI | ⬜ Pending human | Second job: Apply + bookmark + job detail unchanged |
| Automated | `flutter test` | ✅ Pass | 7/7 in `test/d2_apply_flow_test.dart` (status/withdrawn/isActive/labels/payload) |

**Code verification (agent, 2026-06-05):**

- Applications tab uses `features/applications/applications_screen.dart` (not home stub).
- Shortlist/reject: `application_repository.updateStatus` sets `updatedAt`.
- Withdraw: `withdraw()` sets `status: withdrawn`, not delete; `hasApplied` ignores withdrawn.
- Detail: `applicationByIdProvider` live-updates status/timeline.

**Sign-off:** Mark manual rows ✅ after one Chrome + incognito run with demo accounts above.

---

## David — D1: Train Before Apply (when built)

**Prerequisite:** Demo Flutter job; C with CV.

| Step | Actor | Action | Expected |
|------|-------|--------|----------|
| 1 | C | Job detail → **Train Before Apply** | Sheet/screen with ~5 questions |
| 2 | C | Answer all → submit | Per-question feedback; readiness **0–100** |
| 3 | C | Score **&lt; 60** → tap **Apply** | Blocked or strong warning (per spec) |
| 4 | C | Retry training → score **≥ 60** → Apply | Apply allowed; application created |
| 5 | — | Firestore `training_sessions` (or chosen path) | Session doc with `jobId`, score, timestamp |

**Do not test on** Dashboard → Interview Practice — that is a different feature.

---

## David — D3: Notifications (in-app inbox)

### TC-N1 — Recruiter: new application

| Step | Actor | Action | Expected |
|------|-------|--------|----------|
| 1 | R | Post **new** job “Backend Demo” (skills: `Node`) | Job live |
| 2 | C | (Optional: second CV or same CV) Apply to **Backend Demo** | New `applications` doc |
| 3 | R | Profile → **Notifications** | New item: e.g. “New application from …” |
| 4 | — | Firestore `users/{R_uid}/notifications` | New doc `type: new_application`, `read: false` |

### TC-N2 — Candidate: status change

| Step | Actor | Action | Expected |
|------|-------|--------|----------|
| 1 | C | Apply to R’s **Flutter Developer (Demo)** job | `status: pending` |
| 2 | R | Shortlist C on that application | Status updated |
| 3 | C | Profile → **Notifications** | Item about status / shortlisted |
| 4 | C | App foreground on home | May also see **local** OS/banner (existing behavior) |
| 5 | — | Firestore `users/{C_uid}/notifications` | Matching doc created |

### TC-N3 — Read / delete / badge

| Step | Actor | Action | Expected |
|------|-------|--------|----------|
| 1 | C | Open notifications with 2+ unread | Badge on Profile **and** dashboard bell shows count |
| 2 | C | Tap **Mark all read** | All `read: true`; badge clears |
| 3 | C | Mark one unread (long-press) then tap | Single item marked read |
| 4 | C | Swipe delete one | Removed from list and Firestore |

### TC-N5 — New message inbox

| Step | Actor | Action | Expected |
|------|-------|--------|----------|
| 1 | R | Open applicant → **Message** → send text | Message in `conversations` |
| 2 | C | Profile → **Notifications** | Item `type: newMessage`, tap opens chat |
| 3 | — | Firestore `users/{C_uid}/notifications` | `conversationId`, `otherUserId` set |

### TC-N4 — No false positives

| Step | Actor | Action | Expected |
|------|-------|--------|----------|
| 1 | C | Only browse jobs, do not apply | No “new application” notification for C |
| 2 | R | Edit job title only | C does not get spurious status notification (unless you designed for it) |

**FCM (D3-6, phase 2):** Same TC-N1/N2/N5 with app **killed** on a **physical device** — only after [FCM_CLOUD_FUNCTION.md](./FCM_CLOUD_FUNCTION.md) is deployed. Web/Chrome: inbox only (no FCM token).

**Client FCM (now):** On Android/iOS, `users/{uid}.fcmToken` should appear after login; foreground push shows local banner via `fcmListenersProvider`.

**Automated:**

```bash
flutter test test/d3_notifications_test.dart
```

### D3 — Test record — 2026-06-05

| Case | Type | Result | Notes |
|------|------|--------|-------|
| TC-N1 | Manual | ⬜ Pending | R inbox after C applies |
| TC-N2 | Manual | ⬜ Pending | C inbox after R shortlists; local banner may still show |
| TC-N3 | Manual | ⬜ Pending | Badge, mark read, swipe delete |
| TC-N4 | Manual | ⬜ Pending | No false positives |
| Automated | `flutter test` | ✅ Pass | `test/d3_notifications_test.dart` |

---

## David — D4: Settings + dark mode

| Step | Actor | Action | Expected |
|------|-------|--------|----------|
| 1 | C | Profile → **Settings** | Screen opens |
| 2 | C | Toggle **Dark mode** | UI switches immediately |
| 3 | C | Hot restart / reopen app | Dark mode persists |
| 4 | C | Toggle off | Light mode persists |
| 5 | C | Turn off **Push & local alerts** | No OS banner on status change; inbox still works |
| 6 | C | Settings → Privacy / Terms → **Open link** | Browser opens (or snackbar if URL unavailable) |

**Automated:**

```bash
flutter test test/d4_settings_test.dart
```

### D4 — Test record — 2026-06-05

| Case | Type | Result | Notes |
|------|------|--------|-------|
| D4 manual | Manual | ⬜ Pending | Steps 1–6 above |
| Automated | `flutter test` | ✅ Pass | `test/d4_settings_test.dart` |

---

## Raghad — R1 CV (smoke)

| Step | Actor | Action | Expected |
|------|-------|--------|----------|
| 1 | C | Upload PDF on **My CV** | Progress → success |
| 2 | C | View parsed skills / experience | Non-empty sections |
| 3 | — | `cvs/{uid}`, `users/{uid}.cvUrl` | Populated |

---

## Raghad — R2 Jobs browse (smoke)

| Step | Actor | Action | Expected |
|------|-------|--------|----------|
| 1 | C | Jobs → search `Flutter` | Demo job appears |
| 2 | C | Filters: skill `Flutter`, salary range | Demo job still matches |
| 3 | C | Bookmark job → Saved tab | Job listed |

---

## Rahma — H2 Match badge (smoke)

| Step | Actor | Action | Expected |
|------|-------|--------|----------|
| 1 | C | With CV, open Jobs list | Demo Flutter job shows **% match** badge |
| 2 | C | Job detail → match reasons (if button) | Sheet with matched/missing skills |

---

## Rahma — H3 Recruiter applicants (smoke)

**Prerequisite:** D0-1 done for meaningful sort.

| Step | Actor | Action | Expected |
|------|-------|--------|----------|
| 1 | R | Two candidates apply to same job (C + another account) | Two rows |
| 2 | R | Applicants list | Higher `matchScore` applicant higher in list |
| 3 | R | Filter **Shortlisted** | Only shortlisted after action |

---

## After testing — log in tracker

```markdown
### Test record — [slice ID] — YYYY-MM-DD
- Cases run: TC-N1, TC-N2
- Result: pass / fail
- Firestore paths checked: users/.../notifications
```
