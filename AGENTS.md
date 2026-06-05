# JobScope — Agent Onboarding

**Read this first** in every session. Human setup: [SETUP.MD](./SETUP.MD). Product overview: [README.md](./README.md) (feature tables may lag code).

**Building features:** [docs/FEATURE_GUIDE.md](./docs/FEATURE_GUIDE.md) · [docs/FEATURE_TRACKER.md](./docs/FEATURE_TRACKER.md) · [docs/TEST_CASES.md](./docs/TEST_CASES.md) (demo test scripts) · [docs/DAVID_PLAN.md](./docs/DAVID_PLAN.md)

---

## Mandatory rules (all agents)

### No Git — ever

**Agents must not run any Git commands.** This includes (not limited to): `git status`, `git add`, `git commit`, `git push`, `git pull`, `git checkout`, `git branch`, `git merge`, `git rebase`, `git stash`, `git reset`, `gh`, or anything that reads/writes git state.

- **Humans** own version control — see [SETUP.MD](./SETUP.MD) / [README.md](./README.md).
- Agents deliver **file changes only**; update [docs/FEATURE_TRACKER.md](./docs/FEATURE_TRACKER.md) for handoff.
- Do not suggest the agent will commit or push for the user.

### Do not break other features

**Do not disable, delete, or gut existing working behavior** just to ship the new slice.

| Allowed | Not allowed |
|---------|-------------|
| Add fields, providers, routes, screens for **your** task | Rewrite apply/auth/jobs flow when task is only notifications |
| Small fix in shared code that **fixes a real bug** or unblocks the slice | Comment out recruiter shortlist to “make build pass” |
| Refactor **only** if it clearly improves the whole app **and** you re-test affected areas ([TEST_CASES.md](./docs/TEST_CASES.md)) | Change unrelated feature’s Firestore shape without updating models/usages |
| Extend “do not redo” areas per FEATURE_GUIDE | Replace working UI with a stub |

**Before finishing:** run test cases for your slice **and** any related smoke tests you touched (e.g. apply still works after changing `application_repository.dart`).

---

## What this is

Flutter 3 / Dart 3 mobile+web app: **candidates** browse jobs, upload CVs, apply, train with AI; **recruiters** post jobs, rank applicants, schedule interviews, message candidates. Backend: **Firebase** (Auth, Firestore, Storage, FCM). AI: **Google Gemini** via HTTP (`AiService`, `GeminiEmbeddingService`). State: **Riverpod 3** (`Notifier` / `AsyncNotifier` — never `StateNotifier`). Nav: **go_router** with auth + role redirects.

Firebase project: `jobscope-app`.

---

## Local setup (agent must know)

| File | Status | Action |
|------|--------|--------|
| `lib/firebase_options.dart` | Gitignored | `flutterfire configure --project=jobscope-app` |
| `lib/core/constants/secrets.dart` | Gitignored | Copy `secrets.dart.example` → `secrets.dart`, set `geminiApiKey` |
| `.env` | Gitignored, loaded in `main.dart` | Present locally; asset in `pubspec.yaml` |
| `android/app/google-services.json`, iOS plist | Gitignored | From FlutterFire |

Run: `flutter pub get` → `flutter run -d chrome` (fastest). Do **not** commit secrets or Firebase config.

---

## Architecture (feature-first)

```
lib/
├── main.dart                 # dotenv + Firebase init + ProviderScope + MaterialApp.router
├── firebase_options.dart     # generated, local only
├── core/
│   ├── constants/            # app_colors, app_strings, app_sizes, secrets.dart
│   ├── services/             # ai_service, cv_parser, job_matching, embeddings, notifications
│   ├── theme/app_theme.dart  # Material 3 light/dark (ThemeMode.light forced in main)
│   └── utils/app_router.dart # AppRoutes, GoRouter, auth redirect
├── data/
│   ├── models/               # user, job, application, cv, interview, conversation, …
│   └── repositories/         # job, application, collection (shared Firestore access)
└── features/<name>/
    ├── data/                 # *\_providers.dart, feature repos
    └── presentation/         # screens + widgets/
```

**Patterns:** UI → Riverpod provider → repository/service → Firestore/HTTP. Shared models/repos in `lib/data/`; feature-specific providers next to the feature. Real-time data: `StreamProvider` + Firestore `.snapshots()`. Mutations: `Notifier` / `AsyncNotifier` with `.notifier` methods.

**Navigation:** Routes in `AppRoutes` (`app_router.dart`). Pass models via `context.push(path, extra: model)` — `JobModel`, `ApplicationModel`, `ChatParams`, `InterviewParams`, `JobModel?` for edit. Routes with `redirect` reject missing `extra`. Tab shells (`CandidateHomeScreen`, `RecruiterHomeScreen`) use `IndexedStack` + bottom nav, not nested GoRoutes.

**Auth:** `currentUserProvider` (`AsyncNotifier<UserModel?>`) drives redirects. After login/signup call `ref.read(currentUserProvider.notifier).setUser(user)` so role is correct before router rebuilds. Role stored in Firestore `users` + `SharedPreferences` fallback (`AuthRepository`). Roles: `UserRole.candidate` | `UserRole.recruiter`.

---

## Firestore schema (source of truth)

**Setup / post-job timeouts:** see [docs/FIRESTORE_SETUP.md](./docs/FIRESTORE_SETUP.md) — project `flutter-ai-playground-2379c`, **database `jobscope`**, deploy `firestore.rules`.

| Path | Purpose |
|------|---------|
| `users/{uid}` | Profile: `role`, `name`, `email`, `photoUrl`, `headline`, `bio`, `location`, `company`, … |
| `users/{uid}/bookmarks/{jobId}` | Legacy quick-save (still used by `JobRepository`) |
| `users/{uid}/collections/{id}` | Named folders: `name`, `jobIds[]` |
| `users/{uid}/coach_chat/{msgId}` | Career coach messages |
| `jobs/{jobId}` | Listing; `isActive`, `recruiterId`, `skills`, salary fields, … |
| `applications/{id}` | Apply flow; `status`: `pending` \| `shortlisted` \| `rejected` \| `accepted` |
| `cvs/{uid}` | Parsed CV: skills, experience, education, `profileStrength` |
| `interviews/{id}` | Recruiter-proposed slots; candidate confirms |
| `conversations/{id}` | DM metadata; subcollection `messages/{id}` |
| `cover_letters/{id}` | Generated cover letter cache |
| `users/{uid}/training_sessions/{id}` | Train-before-apply: questions, answers, readinessScore, isComplete |
| `users/{uid}/notifications/{id}` | In-app inbox: `type`, `title`, `body`, `read`, `createdAt`, `relatedId` |
| `users/{uid}.fcmToken` | FCM device token (mobile; optional until Cloud Function push) |

Enums and field names must match `lib/data/models/*.dart` `toMap()` / `fromMap()`.

---

## Feature map

### Candidate (home: `CandidateHomeScreen` — 4 tabs)

| Tab / route | Implementation |
|-------------|----------------|
| Dashboard | `home/presentation/dashboard_screen.dart` |
| Jobs | `job_listing/presentation/jobs_screen.dart` |
| Applications | `applications/presentation/applications_screen.dart` (**not** `home/.../applications_screen.dart`) |
| Profile | `home/presentation/profile_screen.dart` |

**Routed screens:** `job_detail`, `application_detail`, `cv`, `ai_cv_builder`, `interview_training`, `skill_assessment`, `career_coach`, `candidate_interviews`, `conversations`, `chat`, `edit_profile`, `jobs/:id` (deep link).

**CV:** Upload → Storage → `CvParserService` + `AiService.parseCv` → `cvs/{uid}`. Providers: `cv_providers.dart`.

**Matching:** `JobMatchingService` + `GeminiEmbeddingService`; UI: `match_badge_widget`, `match_reasons_sheet`. Apply: `applyNotifierProvider` in `application_providers.dart` (duplicate apply blocked in repo).

**Job folders:** `collection_repository` + `my_folders_tab` / `save_to_folder_sheet` (separate from bookmarks).

**Cover letters:** `cover_letter_sheet.dart` + `ai_providers` (README may still say “planned”).

**Notifications:** `LocalNotificationService` on application status change in `candidate_home_screen`; FCM wrapper `notification_service.dart` (minimal).

### Recruiter (home: `RecruiterHomeScreen` — 5 tabs)

| Tab | Screen |
|-----|--------|
| Dashboard | `recruiter_dashboard_screen.dart` |
| Post Job | `post_job_screen.dart` (`extra`: `JobModel` to edit) |
| My Jobs | `recruiter_jobs_screen.dart` → `job_applicants` |
| Analytics | `recruiter_analytics_screen.dart` (fl_chart) |
| Profile | shared `profile_screen.dart` |

**Applicants:** `job_applicants_screen`, `applicant_detail_screen`; filters `recruiter_providers.dart`. **Interviews:** `schedule_interview_sheet` + `interview_providers.dart`. **Messaging:** start from applicant detail → `ChatParams`.

---

## AI layer

| Service | File | Model / notes |
|---------|------|----------------|
| Text generation | `core/services/ai_service.dart` | `gemini-2.0-flash-lite` |
| Embeddings | `core/services/gemini_embedding_service.dart` | Same API key |
| CV PDF text | `core/services/cv_parser_service.dart` | Syncfusion PDF |
| Match scoring | `core/services/job_matching_service.dart` | Uses embeddings |

API key: `Secrets.geminiApiKey` only (not inline in services). Feature prompts live in `AiService` methods; providers in `features/ai_features/data/ai_providers.dart`, `career_coach_providers.dart`.

---

## UI conventions

- Colors: `AppColors` (`#0A66C2` primary). Typography: Plus Jakarta Sans headings, Inter body via `google_fonts`.
- Strings: prefer `AppStrings` in `core/constants/`.
- Spacing: `AppSizes`.
- Theme: `AppTheme.lightTheme` / `darkTheme`; dark not wired to settings yet.
- Loading: `shimmer` where used; charts: `fl_chart`.

---

## Adding code (avoid clashes)

| Task | Where |
|------|--------|
| New screen | `features/<feature>/presentation/`, register in `app_router.dart` + `AppRoutes` |
| New Firestore entity | `data/models/`, `data/repositories/` or feature `data/`, update this doc |
| New global service | `core/services/` |
| New provider | `features/<feature>/data/*_providers.dart` |
| Candidate-only UI | Under `home/`, `job_listing/`, `applications/`, `cv_management/`, `ai_features/`, `career_coach/`, `messaging/` |
| Recruiter-only UI | Under `recruiter/`, `home/post_job`, `home/recruiter_*` |

**Do:** Match existing provider naming (`fooProvider`, `FooNotifier`). Use `ConsumerWidget` / `ConsumerStatefulWidget`. Pass `docId` into `fromMap` where applicable. Use `.timeout()` on Firestore writes like existing repos.

**Don’t:** Add `StateNotifier`. Use `FilePicker.platform` (use `FilePicker.pickFiles()`). Create parallel models for existing collections. Wire placeholder screens in `home/presentation/applications_screen.dart` or `applicants_screen.dart` — they are **stubs**, unused by nav.

**Withdraw:** `withdrawNotifierProvider` — only pending applications.

**Application status UI:** `ApplicationStatus.pending` displays as “Under Review”.

---

## Key providers (quick index)

- Auth: `currentUserProvider`, `firebaseUserProvider`, `authRepositoryProvider`
- Jobs: `jobsStreamProvider`, `jobFilterProvider`, `paginatedJobsProvider`, `bookmarkedIdsProvider`, `bookmarkNotifierProvider`
- Applications: `myApplicationsProvider`, `hasAppliedProvider`, `applyNotifierProvider`
- CV: `cvStreamProvider` / related in `cv_providers.dart`
- Recruiter: `recruiterJobsProvider`, `jobApplicantsProvider`, `ApplicantFilterNotifier`
- Messaging: `messaging_providers.dart` (`ChatParams` for chat route)
- Interviews: `interviewNotifierProvider`, `candidateInterviewsProvider`

---

## README / SETUP drift

Trust **this file and the codebase** over README status tables:

- Implemented but README may say “planned”: career coach, cover letter generator, messaging, interview scheduling, job collections/folders.
- `SETUP.MD` tree omits: `recruiter/`, `messaging/`, `career_coach/`, `applications/`, `ai_features/`.
- README cites Gemini 1.5; code uses **2.0-flash-lite**.
- Salary “intelligence” AI not found — only job salary fields + filter UI.

---

## Verify changes

```bash
flutter analyze
flutter run -d chrome
```

Test both roles: signup → role selection → home → one feature touch per area changed.

---

*Last updated: June 2026 — update Firestore table and feature map when adding collections or routes.*
