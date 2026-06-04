# Feature Tracker

Living log of shipped work. **Update this file at the end of every feature slice** (see [FEATURE_GUIDE.md](./FEATURE_GUIDE.md) §6).

**Agent rules:** **No Git commands.** Do not break unrelated features to ship a slice — see [AGENTS.md](../AGENTS.md) mandatory rules.

**Legend:** ✅ done · 🟡 partial · ⬜ not started · 🚧 in progress

**Last full audit:** 2026-06-04

---

## How to use

1. Check task status here + [FEATURE_GUIDE.md](./FEATURE_GUIDE.md) “Do not redo” if your area is listed.
2. Find your task block (Raghad / Rahma / David).
3. **After each slice:** run cases in [TEST_CASES.md](./TEST_CASES.md); add **Test record** + **Implementation log** (newest first).
4. If you add routes or Firestore collections, update [AGENTS.md](../AGENTS.md) too.
5. David sessions: start from [DAVID_PLAN.md](./DAVID_PLAN.md) (example prompt at bottom).

---

## Team task map

| ID | Owner | Area | Spec status | Tracker section |
|----|-------|------|-------------|-----------------|
| R1 | Raghad | CV upload + AI parsing | 🟡 | [R1](#r1-cv-upload--ai-parsing) |
| R2 | Raghad | Job listings (candidate) | ✅ | [R2](#r2-job-listings-candidate) |
| R3 | Raghad | Models + job CRUD | 🟡 | [R3](#r3-firestore-models--job-crud) |
| R4 | Raghad | Profile edit | ✅ | [R4](#r4-profile-edit) |
| H1 | Rahma | Job posting (recruiter) | 🟡 | [H1](#h1-job-posting-recruiter) |
| H2 | Rahma | AI job matching | 🟡 | [H2](#h2-ai-job-matching) — recruiter sort unblocked by D0-1 |
| H3 | Rahma | Applicants list + detail | 🟡 | [H3](#h3-applicants-list--detail) — sort uses `matchScore` |
| H4 | Rahma | Recruiter analytics | 🟡 | [H4](#h4-recruiter-analytics) |
| D0 | David | Prerequisite fixes | ⬜ | [DAVID_PLAN.md](./DAVID_PLAN.md) |
| D1 | David | AI training module | ✅ | [D1](#d1-ai-training-module) |
| D2 | David | Apply flow + status | 🟡 | [D2](#d2-apply-flow--acceptreject) |
| D3 | David | Notifications (FCM) | 🟡 | [D3](#d3-notifications-fcm) |
| D4 | David | Settings + dark mode | ⬜ | [D4](#d4-settings--dark-mode) |

---

## Raghad

### R1 — CV upload + AI parsing

**Status:** 🟡 (~95%)

| Checklist item | Status |
|----------------|--------|
| File picker PDF/DOCX | ✅ |
| Firebase Storage upload | ✅ |
| URL on `users/{uid}` | ✅ |
| PDF extract (Syncfusion) | ✅ |
| Gemini parse skills/exp/edu | ✅ |
| Profile strength 0–100 | ✅ |
| Display on profile screen | 🟡 strength only; full data on `/cv` |
| Update/replace CV | ✅ |

**Key files:** `cv_parser_service.dart`, `ai_service.dart`, `cv_providers.dart`, `cv_screen.dart`, `dashboard_screen.dart`

**Firestore:** `cvs/{uid}`, `users/{uid}.cvUrl`, `users/{uid}.profileStrength`

#### Implementation log

<!-- Newest first. Example:
### R1-slice-xxx — YYYY-MM-DD
...
-->

*No per-slice log yet — baseline from codebase audit 2026-06-04.*

**Open:** Optional skills summary on `profile_screen.dart` (not blocking).

---

### R2 — Job listings (candidate)

**Status:** ✅

**Key files:** `jobs_screen.dart`, `job_card_widget.dart`, `job_filter_sheet.dart`, `job_detail_screen.dart`, `job_providers.dart`

**Firestore:** reads `jobs` (active); `users/{uid}/bookmarks`

#### Implementation log

*Baseline audit 2026-06-04 — feature complete per spec.*

**Extras shipped:** job folders (`users/{uid}/collections`), cover letter sheet.

---

### R3 — Firestore models + job CRUD

**Status:** 🟡 (~90%)

| Checklist item | Status |
|----------------|--------|
| JobModel, ApplicationModel | ✅ |
| JobRepository CRUD + streams | ✅ |
| Pagination in repository | ✅ |
| Pagination in jobs UI | 🟡 `paginatedJobsProvider` unused; list uses `jobsStreamProvider` |

**Key files:** `job_model.dart`, `application_model.dart`, `job_repository.dart`, `job_providers.dart`

#### Implementation log

*Baseline audit 2026-06-04.*

**Open:** Wire pagination into `jobs_screen` if product requires infinite scroll.

---

### R4 — Profile edit

**Status:** ✅

**Key files:** `edit_profile_screen.dart`, `auth_repository.dart` (`updateProfile`, `uploadProfilePhoto`)

**Firestore:** `users/{uid}` profile fields

#### Implementation log

*Baseline audit 2026-06-04.*

---

## Rahma

### H1 — Job posting (recruiter)

**Status:** 🟡 (~75%)

| Checklist item | Status |
|----------------|--------|
| Multi-step wizard | 🟡 single scroll form |
| Basic info / requirements / skills / salary | ✅ |
| Education + benefits fields | ⬜ |
| Skills autocomplete | ⬜ manual chips |
| Save / edit | ✅ |
| Delete | 🟡 deactivate in UI; `deleteJob()` in repo unused |
| My posted jobs list | ✅ |

**Key files:** `post_job_screen.dart`, `recruiter_jobs_screen.dart`, `job_repository.dart`

#### Implementation log

*Baseline audit 2026-06-04.*

---

### H2 — AI job matching

**Status:** 🟡 (~85%)

| Checklist item | Status |
|----------------|--------|
| Embeddings + similarity | ✅ |
| Match badge + sort (candidate) | ✅ |
| Match reasons sheet | ✅ |
| Match on applications (recruiter) | ⬜ `matchScore` not saved on apply |

**Key files:** `job_matching_service.dart`, `gemini_embedding_service.dart`, `ai_providers.dart`, `match_badge_widget.dart`, `match_reasons_sheet.dart`

#### Implementation log

*Baseline audit 2026-06-04.*

**Note:** Recruiter applicant sort uses `applications.matchScore` — populated on apply (D0-1 ✅).

---

### H3 — Applicants list + detail

**Status:** 🟡 (~80%)

**Key files:** `job_applicants_screen.dart`, `applicant_detail_screen.dart`, `recruiter_providers.dart`

**Gaps:** list sort by match ineffective without stored score; CV “preview” is parsed text not PDF; no skill breakdown on recruiter side.

#### Implementation log

*Baseline audit 2026-06-04.*

---

### H4 — Recruiter analytics

**Status:** 🟡 (~85%)

**Key files:** `recruiter_analytics_screen.dart`, `recruiter_providers.dart` (`recruiterAnalyticsProvider`)

**Gaps:** acceptance rate not displayed; top skills from job postings not applicant CVs.

#### Implementation log

*Baseline audit 2026-06-04.*

---

## David

> **36 original tasks** (11 + 9 + 8 + 8) below. Execution order: [DAVID_PLAN.md](./DAVID_PLAN.md). **D0-1** added as prerequisite (not in original list).

### D1 — AI training module (11 tasks)

**Status:** ✅

| # | Original task | Status | Where |
|---|---------------|--------|-------|
| 1 | Add "Train Before Apply" button | ✅ | `job_detail_screen.dart` bottom bar |
| 2 | Generate 5 questions via Gemini API | ✅ | `AiService.generateTrainBeforeApplyQuestions` |
| 3 | Build question display UI | ✅ | `train_before_apply_sheet.dart` |
| 4 | Add progress indicator | ✅ | LinearProgressIndicator per question |
| 5 | Build answer input field | ✅ | Multi-line TextField |
| 6 | Send answer to AI for evaluation | ✅ | `AiService.evaluateTrainAnswer` |
| 7 | Display detailed feedback per question | ✅ | Feedback card after each submit |
| 8 | Calculate readiness score | ✅ | Average of 5 question scores |
| 9 | Block apply if score &lt; 60% | ✅ | After completed session &lt; 60 |
| 10 | Allow retry training | ✅ | Retry on result screen |
| 11 | Save training history to Firestore | ✅ | `users/{uid}/training_sessions/{id}` |

**Note:** Dashboard `interview_training_screen.dart` = **Interview Practice** (different feature).

**Firestore:** `users/{uid}/training_sessions/{id}`

#### Implementation log

### D1 — Train Before Apply — 2026-06-04

**Slice:** Full D1 module (model, repo, AI, sheet, job detail gate).

**Files:**
- `lib/data/models/training_session_model.dart`
- `lib/data/repositories/training_repository.dart`
- `lib/core/services/ai_service.dart` — generate + evaluate
- `lib/features/ai_features/data/training_providers.dart`
- `lib/features/job_listing/presentation/widgets/train_before_apply_sheet.dart`
- `lib/features/job_listing/presentation/job_detail_screen.dart`

**Gate:** Apply blocked only if user **completed** training for this job with readiness &lt; 60%. No training → apply still allowed.

**Test:** [TEST_CASES.md](./TEST_CASES.md) D1 — manual + Gemini key required.

### Test record — D1 — 2026-06-04
- Cases: D1 (manual pending)
- Result: code complete
- Firestore: `users/{uid}/training_sessions`

---

### D2 — Apply flow + accept/reject (9 tasks + D0-1)

**Status:** 🟡

| # | Original task | Status | Notes |
|---|---------------|--------|-------|
| — | **D0-1:** Persist `matchScore` on apply | ✅ | `ApplyNotifier` + `ApplicationRepository.apply` |
| 1 | Add "Apply" button on job details | ✅ | `job_detail_screen.dart` |
| 2 | Create application in Firestore | ✅ | `application_repository.apply` |
| 3 | Define states (pending/shortlisted/accepted/rejected) | ✅ | `ApplicationStatus` |
| 4 | Build recruiter accept/reject buttons | ✅ | `applicant_detail_screen`, list cards |
| 5 | Update status in Firestore | ✅ | `updateStatus` |
| 6 | Build application history screen (Candidate) | ✅ | `applications_screen.dart` |
| 7 | Add status badges with colors | ✅ | `application_status_badge.dart` |
| 8 | Add withdraw application feature | ✅ | Deletes doc — may revise to `withdrawn` |
| 9 | Build application timeline view | ✅ | `application_detail_screen.dart` |

**Key files:** `application_repository.dart`, `application_providers.dart`, `applications_screen.dart`, `application_detail_screen.dart`, `job_detail_screen.dart`

#### Implementation log

*D0-1 done 2026-06-04. See D0 implementation log.*

---

### D3 — Notifications system — FCM (8 tasks)

**Status:** 🟡 (~25%)

| # | Original task | Status | Notes |
|---|---------------|--------|-------|
| 1 | Setup Firebase Cloud Messaging | 🟡 | `notification_service.dart` — token only |
| 2 | Request notification permissions | 🟡 | Partial in FCM + local init |
| 3 | Send push on status change | ⬜ | Phase 2: Cloud Function; v1: in-app + local |
| 4 | Send push on new job match | ⬜ | **Replaced:** recruiter alert on new application (TC-N1) |
| 5 | Build in-app notification screen | ⬜ | D3-3 |
| 6 | Add notification badge with unread count | ⬜ | D3-4 |
| 7 | Implement mark as read/unread | ⬜ | D3-5 |
| 8 | Add delete notification feature | ⬜ | D3-5 |

**Firestore (planned):** `users/{uid}/notifications/{id}`

**Tests:** [TEST_CASES.md](./TEST_CASES.md) TC-N1–N4

#### Implementation log

*Baseline 2026-06-04.*

---

### D4 — Settings + dark mode (8 tasks)

**Status:** ⬜

| # | Original task | Status | Plan slice |
|---|---------------|--------|------------|
| 1 | Build settings screen | ⬜ | D4-2 — `AppRoutes.settings` |
| 2 | Add dark mode toggle | ⬜ | D4-2 |
| 3 | Save dark mode to SharedPreferences | ⬜ | D4-1 — `settingsProvider` |
| 4 | Add notification preferences | ⬜ | D4-1 — used by D3 |
| 5 | Build About app screen | ⬜ | D4-4 — section or sub-screen |
| 6 | Build Help/FAQ screen | ⬜ | D4-4 |
| 7 | Add privacy policy link | ⬜ | D4-4 — `url_launcher` or WebView |
| 8 | Add terms of service link | ⬜ | D4-4 |

**Note:** `AppTheme.darkTheme` exists; `main.dart` uses `ThemeMode.light`. Profile Settings/Notifications tiles are empty `onTap`.

#### Implementation log

*Not started.*

---

### D0 — Prerequisite fixes (cross-team)

**Status:** ✅ D0-1 done

| ID | Item | Owner | Status |
|----|------|-------|--------|
| D0-1 | Persist `matchScore` on apply | David | ✅ |
| D0-2 | (Optional) Rahma analytics acceptance rate UI | Rahma | ⬜ |

#### Implementation log

### D0-1 — matchScore on apply — 2026-06-04

**Slice:** On apply, compute embedding match via `JobMatchingService` when CV has skills; persist on `applications` doc.

**Files:**
- `lib/features/applications/data/application_providers.dart` — fetch job, `calculateMatch`, pass score
- `lib/data/repositories/application_repository.dart` — optional `matchScore` param

**How it works:** `ApplyNotifier.apply` → if CV with skills → `fetchJob` → `calculateMatch` → `apply(..., matchScore)`. Failures leave `matchScore` null; apply still succeeds.

**Test:** [TEST_CASES.md](./TEST_CASES.md) D0-1, TC-D0-1-E1 — manual on Chrome + Firestore console.

### Test record — D0-1 — 2026-06-04
- Cases: D0-1, TC-D0-1-E1 (agent: analyze pass; manual UI pending human run)
- Result: code complete / manual pass pending
- Firestore: `applications/{id}.matchScore`

---


---

## Cross-feature index (quick lookup)

| Capability | Primary files | Firestore |
|------------|---------------|-----------|
| Auth + roles | `auth_repository.dart`, `auth_providers.dart` | `users/{uid}` |
| CV pipeline | `cv_parser_service.dart`, `cv_providers.dart` | `cvs/{uid}` |
| Jobs browse | `jobs_screen.dart`, `job_providers.dart` | `jobs` |
| Apply | `application_providers.dart` | `applications` |
| Recruiter applicants | `job_applicants_screen.dart` | `applications` |
| Messaging | `messaging_providers.dart` | `conversations`, `messages` |
| Interviews | `interview_providers.dart` | `interviews` |
| Career coach | `career_coach_providers.dart` | `users/{uid}/coach_chat` |

---

## Session handoff template

Copy at end of session:

```markdown
## Handoff — YYYY-MM-DD — @agent

**Completed:** D0-1 matchScore on apply
**Files touched:** application_providers.dart, application_repository.dart
**Tracker updated:** D0, D2, H2, H3
**Verify:** apply to job → Firestore `applications` has matchScore → recruiter list sorted
**Next:** D1-slice-1 training_sessions model
**Blockers:** none
```
