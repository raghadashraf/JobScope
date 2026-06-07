# JobScope — Complete Study Handbook

**Read only this file.** You do not need to open the codebase to understand how JobScope works, what libraries it uses, where data flows, or how to answer exam questions.

**Table of contents**

1. [What JobScope is](#1-what-jobscope-is)
2. [Foundation concepts](#2-foundation-concepts-you-must-know-first)
3. [Riverpod — state management (from zero)](#3-riverpod--state-management-from-zero)
4. [Firebase — backend (from zero)](#4-firebase--backend-from-zero)
5. [Navigation — go_router](#5-navigation--go_router)
6. [Architecture — how layers connect](#6-architecture--how-layers-connect)
7. [App startup — what happens when you open the app](#7-app-startup--what-happens-when-you-open-the-app)
8. [Every package / library](#8-every-package--library)
9. [Folder structure](#9-folder-structure)
10. [Firestore database — every collection](#10-firestore-database--every-collection)
11. [Data models — every field explained](#11-data-models--every-field-explained)
12. [Repositories — database operations](#12-repositories--database-operations)
13. [Services — business logic & AI](#13-services--business-logic--ai)
14. [Providers — complete index](#14-providers--complete-index)
15. [Screens — every UI screen](#15-screens--every-ui-screen)
16. [Data flows — step by step](#16-data-flows--step-by-step)
17. [AI & job matching — how scores work](#17-ai--job-matching--how-scores-work)
18. [Notifications — three layers](#18-notifications--three-layers)
19. [Settings & theme](#19-settings--theme)
20. [Exam Q&A — rapid answers](#20-exam-qa--rapid-answers)
21. [Glossary](#21-glossary)
22. [Traps & things that confuse people](#22-traps--things-that-confuse-people)

---

## 1. What JobScope is

JobScope is a **Flutter mobile app** (also runs on web) that connects **job candidates** and **recruiters**.

| Role | What they do in the app |
|------|-------------------------|
| **Candidate** | Upload CV, browse jobs, see AI match scores, apply, track application status, train for interviews, chat with AI coach |
| **Recruiter** | Post jobs, view applicants sorted by match score, shortlist/reject/accept, analytics, schedule interviews, message candidates |

**Backend:** Google **Firebase** (login, database, file storage, push notifications).  
**AI:** Google **Gemini** API (parse CVs, generate questions, embeddings for job matching, cover letters, career coach).

**State management:** **Riverpod** — how screens get data and react to changes.  
**Navigation:** **go_router** — how screens link together and auth redirects work.

---

## 2. Foundation concepts you must know first

### Flutter (one paragraph)

Flutter builds UI with **widgets** (buttons, text, lists). Everything is a widget tree. Screens are widgets. When data changes, Flutter **rebuilds** the parts of the UI that depend on that data.

### Dart (what you see in this project)

| Concept | Meaning | Example in JobScope |
|---------|---------|---------------------|
| `class` | Blueprint for data or behavior | `JobModel`, `AuthRepository` |
| `enum` | Fixed list of options | `ApplicationStatus.pending` |
| `Future` | Async work that completes later | `signIn()` waiting for Firebase |
| `Stream` | Async values over time | Firestore live updates |
| `async` / `await` | Wait for Future without blocking UI | `await repository.apply()` |
| `factory` constructor | Build object from map | `JobModel.fromMap(...)` |
| `copyWith` | Clone object with some fields changed | `user.copyWith(name: 'New')` |

### The four layers in JobScope

```
┌─────────────────────────────────────────┐
│  PRESENTATION — screens & widgets       │  What user sees & taps
├─────────────────────────────────────────┤
│  PROVIDERS — Riverpod (*_providers.dart)│  Holds state, connects UI to data
├─────────────────────────────────────────┤
│  REPOSITORIES + SERVICES                │  Talks to Firestore, Storage, Gemini
├─────────────────────────────────────────┤
│  FIREBASE + GEMINI API                  │  Cloud storage & AI
└─────────────────────────────────────────┘
```

**Rule:** Screens should **not** call Firestore directly. They call a **provider**, which calls a **repository** or **service**.

---

## 3. Riverpod — state management (from zero)

### What is Riverpod?

**Riverpod** is a Flutter package that **stores app data in one place** and **automatically updates the UI** when that data changes.

Without it, every screen would pass data manually (messy). With it:

- Screen says: “I need the current user” → `ref.watch(currentUserProvider)`
- When user logs in, every screen watching that provider **rebuilds automatically**

### Root wrapper: `ProviderScope`

In `main.dart`, the whole app is wrapped in:

```dart
runApp(const ProviderScope(child: JobScopeApp()));
```

`ProviderScope` is the **container** that holds all providers. Nothing Riverpod-related works without it.

### Widget types that use Riverpod

| Widget base | How you get `ref` | Used when |
|-------------|-------------------|-----------|
| `ConsumerWidget` | `build(context, WidgetRef ref)` | Stateless screen |
| `ConsumerStatefulWidget` | `ref` on the State class | Screen with local state (tabs, controllers) |

### The two operations you must know

| Operation | Syntax | When to use |
|-----------|--------|-------------|
| **Watch** | `ref.watch(someProvider)` | Inside `build()` — UI **rebuilds** when data changes |
| **Read** | `ref.read(someProvider)` | Inside button handlers / one-time actions — **no rebuild** |

**Example:**

```dart
// In build — show loading spinner while user loads
final userAsync = ref.watch(currentUserProvider);

// On button press — trigger login once
onPressed: () => ref.read(authRepositoryProvider).signIn(...)
```

### Provider types used in JobScope

#### 1. `Provider<T>` — simple singleton / computed value

Creates one instance or derives a value from other providers.

```dart
final jobRepositoryProvider = Provider<JobRepository>((ref) => JobRepository());
```

- **Does not** auto-refresh UI by itself unless something else triggers rebuild
- Used for repositories, services, computed lists

#### 2. `StreamProvider<T>` — live Firestore / Auth streams

Wraps a Dart `Stream`. When Firestore emits new data, UI updates.

```dart
final jobsStreamProvider = StreamProvider<List<JobModel>>((ref) {
  return ref.read(jobRepositoryProvider).jobsStream();
});
```

Returns `AsyncValue<List<JobModel>>` to UI with states:

| AsyncValue state | Meaning | UI typically shows |
|------------------|---------|-------------------|
| `loading` | Waiting for first data | Spinner / shimmer |
| `data` | Success | The actual list |
| `error` | Failed | Error message |

UI pattern: `.when(data: ..., loading: ..., error: ...)` or check `.hasValue` / `.value`.

#### 3. `FutureProvider<T>` — one-shot async fetch

Like StreamProvider but for a **single** async result (e.g. generate quiz questions).

```dart
final skillQuizProvider = FutureProvider.autoDispose.family<List<QuizQuestion>, List<String>>(...);
```

- `.autoDispose` — disposed when no UI watches it (saves memory)
- `.family` — different cache per parameter (e.g. per `jobId`)

#### 4. `NotifierProvider` — mutable state + methods

For **actions** that change state: apply to job, toggle bookmark, save settings.

```dart
final applyNotifierProvider = NotifierProvider<ApplyNotifier, ApplyState>(ApplyNotifier.new);

// In screen:
ref.read(applyNotifierProvider.notifier).apply(jobId: '...');
final state = ref.watch(applyNotifierProvider); // idle / loading / success / error
```

**Notifier** = class with a `build()` method (initial state) + custom methods like `apply()`.

#### 5. `AsyncNotifierProvider` — Notifier that loads async on start

Used for auth user resolution and settings.

```dart
final currentUserProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);
```

`AuthNotifier.build()` runs when app starts — fetches user from Firestore.

Special method: `setUser(UserModel user)` — called right after login so router gets role **immediately** (before Firebase stream catches up).

#### 6. `Provider<void>` — side-effect bootstrap

Runs code when watched but returns nothing useful.

```dart
ref.watch(fcmBootstrapProvider); // starts FCM when logged in
```

Used in home screens to initialize notifications.

### Other Riverpod patterns in this project

| Pattern | Meaning |
|---------|---------|
| `ref.watch(otherProvider)` | This provider **depends on** other — recomputes when other changes |
| `ref.read(otherProvider)` | One-time access inside a method |
| `ref.listen(provider, (prev, next) {...})` | Run side effect on change (e.g. show snackbar, sync tab index) |
| `ref.onDispose(() => ...)` | Cleanup (cancel timers) |
| `.select((async) => async.value?.uid)` | Watch only part of state — fewer rebuilds |
| `.family` | Parameterized provider — e.g. `hasAppliedProvider(jobId)` |

### Key auth providers (memorize)

| Provider | Type | What it holds |
|----------|------|---------------|
| `firebaseUserProvider` | StreamProvider | Raw Firebase Auth user (email, uid) — **no role** |
| `currentUserProvider` | AsyncNotifierProvider | Full `UserModel` from Firestore — **includes role** (candidate/recruiter) |
| `authRepositoryProvider` | Provider | Object that performs signIn/signUp |

**Why two user providers?** Firebase Auth knows *who* logged in. Firestore `users/{uid}` knows if they are **candidate or recruiter**.

---

## 4. Firebase — backend (from zero)

### What is Firebase?

Google’s backend-as-a-service. JobScope uses four Firebase products:

| Product | Package | What JobScope uses it for |
|---------|---------|---------------------------|
| **Authentication** | `firebase_auth` | Email/password login & signup |
| **Cloud Firestore** | `cloud_firestore` | All structured data (jobs, applications, profiles) |
| **Cloud Storage** | `firebase_storage` | CV PDF files, profile photos |
| **Cloud Messaging (FCM)** | `firebase_messaging` | Push notification tokens (optional server push) |

### Firestore basics

- **Document** — one JSON-like record (e.g. one job)
- **Collection** — folder of documents (e.g. `jobs/`)
- **Path** — e.g. `users/abc123/cvs/profile` = document `profile` inside subcollection `cvs` under user `abc123`

### Named database: `jobscope`

Most Firebase apps use the `(default)` database. JobScope uses a **named database** called **`jobscope`**.

All code accesses it via:

```dart
FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'jobscope')
```

Helper: `appFirestore` in `firestore_helpers.dart`.

### Real-time updates: `.snapshots()`

Repositories return **Streams**. When anyone changes Firestore, your app UI updates without refresh.

Example: recruiter shortlists you → your Applications tab updates live via `myApplicationsProvider`.

### Firebase Storage

Files (not JSON). Paths used:

- `cvs/{uid}/filename.pdf` — uploaded CV
- `profile_photos/{uid}.jpg` — profile picture

Download URLs are stored in Firestore fields like `fileUrl` / `photoUrl`.

### Security

`firestore.rules` in repo root controls who can read/write. App assumes rules are deployed to project `flutter-ai-playground-2379c`.

---

## 5. Navigation — go_router

### What is go_router?

A package that maps **URL paths** to **screens** and handles **redirects** (e.g. send logged-out users to login).

Routes are defined in `app_router.dart` as constants `AppRoutes.*`.

### How navigation works

| Action | Code pattern |
|--------|--------------|
| Go to route | `context.push(AppRoutes.jobDetail, extra: jobModel)` |
| Go back | `context.pop()` |
| Replace stack | `context.go(AppRoutes.candidateHome)` |

**`extra`** — pass objects (JobModel, ApplicationModel) that are too big for URL. Route `redirect` checks `state.extra` exists.

### Global auth redirect logic

1. Auth still loading → stay on current screen (splash)
2. **Not logged in** → only allow onboarding, role selection, login, register; everything else → onboarding
3. **Logged in on public page** → redirect to `/candidate-home` or `/recruiter-home` based on `UserRole`
4. Otherwise → allow navigation

### All routes

| Route constant | Path | Screen | Notes |
|----------------|------|--------|-------|
| `onboarding` | `/onboarding` | Onboarding | First launch intro |
| `roleSelection` | `/role-selection` | Role selection | Pick candidate vs recruiter |
| `login` | `/login` | Login | extra: role string |
| `register` | `/register` | Signup | extra: role string |
| `candidateHome` | `/candidate-home` | Candidate home | 4 bottom tabs |
| `recruiterHome` | `/recruiter-home` | Recruiter home | 5 bottom tabs |
| `jobDetail` | `/job-detail` | Job detail | extra: JobModel OR ?jobId= |
| `applicationDetail` | `/application-detail` | Application detail | extra: ApplicationModel |
| `editProfile` | `/edit-profile` | Edit profile | |
| `cv` | `/cv` | My CV | |
| `editCvProfile` | `/edit-cv-profile` | Edit CV skills/exp | |
| `postJob` | `/post-job` | Post/edit job | extra: JobModel? to edit |
| `jobApplicants` | `/job-applicants` | Applicants list | extra: JobModel |
| `applicantDetail` | `/applicant-detail` | Applicant detail | extra: ApplicationModel |
| `interviewTraining` | `/interview-training` | Interview practice | extra: InterviewParams |
| `skillAssessment` | `/skill-assessment` | Skill quiz | |
| `jobs` | `/jobs` | Jobs list | Standalone route |
| `aiCvBuilder` | `/ai-cv-builder` | AI CV builder | |
| `careerCoach` | `/career-coach` | AI career coach chat | |
| `jobDeepLink` | `/jobs/:id` | Job from link | |
| `candidateInterviews` | `/candidate-interviews` | Interview list | |
| `conversations` | `/conversations` | Message list | |
| `chat` | `/chat` | Chat thread | extra: ChatParams |
| `notifications` | `/notifications` | Notification inbox | |
| `settings` | `/settings` | Settings | |
| `about` | `/about` | About app | |
| `help` | `/help` | FAQ | |
| `privacy` | `/privacy` | Privacy policy | |
| `terms` | `/terms` | Terms of service | |

---

## 6. Architecture — how layers connect

### Example: user taps “Apply” on a job

```
JobDetailScreen (UI)
    │ ref.read(applyNotifierProvider.notifier).apply(jobId)
    ▼
ApplyNotifier (provider)
    │ reads cvStreamProvider, jobRepository, jobMatchingService
    │ calls calculateMatch for matchScore
    ▼
ApplicationRepository.apply()
    │ writes Firestore applications/{newId}
    │ calls NotificationRepository → recruiter inbox
    ▼
Firestore + Notification docs
    │
    ▼ (stream updates)
myApplicationsProvider → ApplicationsScreen rebuilds
hasAppliedProvider(jobId) → JobDetailScreen shows "Applied"
```

### Who talks to whom (rules)

| Layer | Can call | Must NOT call |
|-------|----------|---------------|
| Screen | Providers | Firestore directly, http directly |
| Provider | Repositories, Services, other providers | UI widgets |
| Repository | Firestore (`appFirestore`) | Gemini API |
| Service | HTTP (Gemini), Storage, other services | Widgets |

---

## 7. App startup — what happens when you open the app

**Order in `main()`:**

1. **`WidgetsFlutterBinding.ensureInitialized()`** — Flutter engine ready
2. **`dotenv.load('.env')`** — loads `GEMINI_API_KEY` from `.env` file into environment
3. **`Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`** — connects to Firebase project (config from `firebase_options.dart`)
4. **`configureFirestore()`** — on web, disables IndexedDB persistence (prevents hung writes)
5. **`FirebaseMessaging.onBackgroundMessage(...)`** — register handler for push when app killed (mobile only)
6. **`runApp(ProviderScope → JobScopeApp)`**

**Inside `JobScopeApp`:**

- Watches `routerProvider` (navigation) and `themeModeProvider` (light/dark)
- Builds `MaterialApp.router` with themes from `AppTheme`
- `AppColors.applyBrightness()` updates semantic colors when theme changes

**Auth resolution:**

- `currentUserProvider` loads → if user exists, redirect to correct home
- If not, show onboarding

**On candidate/recruiter home load:**

- `fcmBootstrapProvider` — init push notifications (if enabled)
- `jobMatchNotificationBootstrapProvider` — one-time scan for job/CV skill matches → inbox alerts
- Candidate home also runs `LocalNotificationService().init()`

---

## 8. Every package / library

| Package | Plain English | Used in JobScope for |
|---------|---------------|----------------------|
| `flutter` | UI framework | Everything visible |
| `flutter_riverpod` | State management | All `*_providers.dart` |
| `firebase_core` | Firebase bootstrap | `main.dart` |
| `firebase_auth` | Login/signup | `auth_repository.dart` |
| `cloud_firestore` | NoSQL database | All repositories |
| `firebase_storage` | File cloud storage | CV upload, profile photos |
| `firebase_messaging` | Push notifications | FCM token, background handler |
| `go_router` | Declarative routing | `app_router.dart` |
| `flutter_dotenv` | Load `.env` secrets | Gemini API key |
| `http` | HTTP requests | Gemini REST API |
| `dio` | HTTP client (alt) | Available in project |
| `syncfusion_flutter_pdf` | Read PDF text | Extract CV text before AI parse |
| `file_picker` | Pick files from device | CV upload (PDF/DOCX) |
| `image_picker` | Camera / gallery | Profile photo |
| `shared_preferences` | Key-value local storage | Settings, role cache, embedding cache |
| `flutter_local_notifications` | OS notification banners | Status change alerts when app open |
| `google_fonts` | Download fonts | Plus Jakarta Sans, Inter |
| `shimmer` | Skeleton loading animation | Jobs list loading |
| `fl_chart` | Charts | Recruiter analytics |
| `cached_network_image` | Cache remote images | Avatars, job images |
| `intl` | Format dates/numbers | Various screens |
| `share_plus` | System share sheet | Share job link |
| `add_2_calendar` | Add calendar event | Interview confirmation |
| `url_launcher` | Open URLs in browser | Privacy/terms links |
| `path_provider` | Device filesystem paths | Local photo cache |
| `csv` | CSV parsing | Export features if any |
| `animations` / `lottie` | Motion design | Onboarding, dashboard |
| `flutter_svg` | SVG images | Icons/assets |
| `cupertino_icons` | iOS-style icons | Minor UI |

---

## 9. Folder structure

```
lib/
├── main.dart                    # Entry point
├── firebase_options.dart        # Firebase config (local, gitignored)
├── core/
│   ├── constants/               # Colors, strings, sizes, secrets
│   ├── theme/                   # Light/dark ThemeData
│   ├── utils/                   # Router, Firestore helpers, profile strength
│   ├── services/                # AI, CV parse, matching, notifications
│   └── widgets/                 # Shared UI (avatar, profile level fields)
├── data/
│   ├── models/                  # UserModel, JobModel, ApplicationModel, ...
│   └── repositories/          # Firestore CRUD
└── features/
    ├── auth/                    # Login, signup, profile edit
    ├── home/                    # Dashboards, home shells, post job
    ├── cv_management/           # CV upload, edit, AI builder
    ├── job_listing/             # Jobs browse, detail, filters, folders
    ├── applications/            # Apply flow, application list/detail
    ├── ai_features/             # Interview training, skill quiz, matching providers
    ├── recruiter/               # Applicants, analytics, interviews
    ├── notifications/           # Inbox screen
    ├── messaging/               # DMs
    ├── career_coach/            # AI chat coach
    └── settings/                # Settings, about, help, legal
```

**Feature folder pattern:**

- `data/*_providers.dart` — Riverpod
- `presentation/*.dart` — Screens
- `presentation/widgets/` — Reusable pieces for that feature

---

## 10. Firestore database — every collection

| Path | Stores | Who reads/writes |
|------|--------|------------------|
| `users/{uid}` | Name, email, role, photoUrl, bio, headline, company, fcmToken | Auth, profile |
| `users/{uid}/cvs/profile` | **Canonical CV** — skills, experience, education, file URL | CV features |
| `users/{uid}/bookmarks/{jobId}` | Quick-saved jobs | Jobs bookmark |
| `users/{uid}/collections/{id}` | Named folders with `jobIds[]` | Job folders |
| `users/{uid}/notifications/{id}` | In-app inbox items | Notifications |
| `users/{uid}/training_sessions/{id}` | Train-before-apply sessions | Job detail |
| `users/{uid}/application_drafts/{jobId}` | Draft CV/cover letter per job | Apply flow |
| `users/{uid}/coach_chat/{msgId}` | Career coach messages | Career coach |
| `jobs/{id}` | Job postings | Everyone |
| `applications/{id}` | Job applications | Apply + recruiter |
| `interviews/{id}` | Interview proposals | Recruiter + candidate |
| `conversations/{id}` | DM metadata | Messaging |
| `conversations/{id}/messages/{msgId}` | Chat messages | Messaging |
| `cover_letters/{uid}_{jobId}` | Saved AI cover letters | Job detail |
| `cvs/{uid}` | **Legacy** CV path (migrated to profile doc) | Migration only |

**Storage (not Firestore):**

- `cvs/{uid}/...` — PDF files
- `profile_photos/{uid}.jpg` — profile photos

---

## 11. Data models — every field explained

Models live in `lib/data/models/`. Each has `toMap()` (write Firestore) and `fromMap()` (read Firestore).

### UserModel — `users/{uid}`

| Field | Meaning |
|-------|---------|
| `uid` | Firebase Auth user ID |
| `email` | Login email |
| `name` | Display name |
| `role` | `candidate` or `recruiter` — **decides which home screen** |
| `photoUrl` | Profile picture URL |
| `phone`, `bio`, `headline`, `location` | Profile text |
| `linkedinUrl`, `website` | Links |
| `company` | Recruiter’s company name |
| `createdAt` | Signup date |

### JobModel — `jobs/{id}`

| Field | Meaning |
|-------|---------|
| `recruiterId`, `recruiterName`, `recruiterPhotoUrl` | Who posted |
| `title`, `company`, `location` | Job header info |
| `jobType` | full-time, part-time, remote, contract |
| `experienceLevel` | junior, mid, senior, lead |
| `educationLevel` | High School, Bachelor's, Master's, etc. |
| `description`, `requirements` | Job text |
| `skills` | List for matching |
| `benefits` | Perks list |
| `salaryMin`, `salaryMax`, `salaryCurrency` | Pay range |
| `postedAt` | When posted |
| `isActive` | Visible to candidates if true |
| `isDeleted` | Soft delete — hidden from recruiter UI |

### ApplicationModel — `applications/{id}`

| Field | Meaning |
|-------|---------|
| `jobId`, `jobTitle`, `company` | Which job |
| `candidateId`, `candidateName`, `candidateEmail`, `candidatePhotoUrl` | Who applied |
| `cvUrl`, `cvId`, `cvFileName` | CV snapshot at apply time |
| `coverLetterText`, `coverLetterFileUrl`, ... | Cover letter if attached |
| `status` | See enum below |
| `appliedAt` | When applied |
| `updatedAt` | Last status change |
| `matchScore` | 0–100 AI match at apply time |
| `notes` | Recruiter private notes |

**ApplicationStatus enum:**

| Firestore value | UI label | Meaning |
|-----------------|----------|---------|
| `pending` | **Under Review** | Just applied |
| `shortlisted` | Shortlisted | Recruiter interested |
| `rejected` | Not Selected | Rejected |
| `accepted` | Accepted | Hired / accepted |
| `withdrawn` | Withdrawn | Candidate withdrew (doc kept, can re-apply) |

**Helpers on model:**

- `canWithdraw` — only if `pending`
- `statusDisplayName` — UI string
- `isActive` — not withdrawn

### CvModel — `users/{uid}/cvs/profile`

| Field | Meaning |
|-------|---------|
| `id` | Usually `'profile'` |
| `uid` | Owner |
| `fileUrl`, `fileName`, `storagePath` | Uploaded PDF info |
| `uploadedAt` | Upload time |
| `skills` | String list — **used for matching** |
| `workExperience` | List of company/title/duration/description |
| `education` | List of institution/degree/field/year |
| `experienceLevel` | junior / mid / senior / lead |
| `educationLevel` | Degree level |
| `profileStrength` | 0–100 stored score |
| `effectiveProfileStrength` | **Recalculated** live from fields (preferred in UI) |

### TrainingSessionModel — `users/{uid}/training_sessions/{id}`

| Field | Meaning |
|-------|---------|
| `jobId`, `jobTitle`, `company` | Which job training is for |
| `questions`, `answers` | Q&A pairs |
| `readinessScore` | 0–100 average |
| `isComplete` | Finished all questions |
| Used to **block Apply if score < 60** after completed training |

### AppNotificationModel — inbox

| Field | Meaning |
|-------|---------|
| `type` | e.g. application, status_change, job_match, message |
| `title`, `body` | Display text |
| `read` | false = unread badge |
| `relatedId`, `applicationId`, `jobId` | Deep link targets |

### Other models (shorter)

| Model | Purpose |
|-------|---------|
| `JobCollectionModel` | Folder name + `jobIds[]` |
| `InterviewModel` | Proposed time slots, confirmed slot, status |
| `ConversationModel` | DM thread metadata, unread counts |
| `DirectMessageModel` | Single chat message |
| `ChatMessage` | Career coach user/assistant message |
| `ApplicationDraftModel` | In-progress apply draft |

---

## 12. Repositories — database operations

Repositories = **only Firestore read/write**. No UI.

### ApplicationRepository

| Method | What it does |
|--------|--------------|
| `apply(...)` | Create doc in `applications/`. Checks duplicate first. Optional `matchScore`. |
| `hasApplied` / `hasAppliedStream` | Check if candidate already applied to job |
| `candidateApplicationsStream` | All apps for logged-in candidate |
| `jobApplicationsStream` | All apps for one job (recruiter view) |
| `applicationStream(id)` | Live single application |
| `updateStatus` | Recruiter changes status + sets `updatedAt` + notifies candidate |
| `updateNotes` | Recruiter private notes |
| `withdraw` | Sets status to `withdrawn` (pending only) |
| `fetchApplication` | One-time read |

### JobRepository

| Method | What it does |
|--------|--------------|
| `jobsStream` | Live all active jobs |
| `recruiterJobsStream` | Recruiter’s own jobs |
| `fetchJob` / `jobStream` | Single job |
| `fetchJobs` | Paginated (10 per page) — **UI mostly uses stream instead** |
| `createJob` / `updateJob` | Post or edit job |
| `deactivateJob` / `activateJob` | Toggle visibility |
| `softDeleteJob` | Hide from recruiter (`isDeleted: true`) |
| `deleteJob` | Hard delete (exists but UI uses soft delete) |
| `bookmarkJob` / `removeBookmark` | User bookmarks |
| `bookmarkedJobIdsStream` | Live bookmark IDs |

### NotificationRepository

| Method | What it does |
|--------|--------------|
| `notificationsStream` | Inbox list |
| `unreadCountStream` | Badge number |
| `create` | New notification doc |
| `markRead` / `markUnread` / `markAllRead` / `delete` | Inbox actions |
| `notifyRecruiterNewApplication` | When candidate applies |
| `notifyCandidateStatusChange` | When status changes |
| `notifyCandidateJobMatch` | High match job alert |
| `notifyNewMessage` | New DM |

### CollectionRepository

CRUD for job folders under `users/{uid}/collections/`.

### TrainingRepository

Save/update training sessions; stream latest completed session per job.

### UserStatsRepository

Updates `users/{uid}` stats like application counts after apply.

---

## 13. Services — business logic & AI

Services contain **logic that isn’t just CRUD** — AI calls, PDF parsing, scoring.

### AiService — Gemini text generation

**Model used:** `gemini-2.0-flash-lite`  
**API key:** from `.env` → `Secrets.geminiApiKey`  
**HTTP:** `http` package POST to Google Generative Language API

| Method | Purpose |
|--------|---------|
| `parseCv` | Send CV text → get JSON with skills, jobs, education → `CvModel` |
| `generateInterviewQuestions` | 5 behavioral questions for dashboard practice |
| `generateTrainBeforeApplyQuestions` | 5 job-specific scenario questions |
| `evaluateTrainAnswer` | Score one answer 0–100 + feedback text |
| `generateSkillQuiz` | 5 multiple-choice questions from skills |
| `matchJob` | Quick AI skill overlap score |
| `getMatchReasons` | Matched skills, missing skills, summary paragraph |
| `generateCoverLetter` | Full cover letter text |
| `chatWithCoach` | Career coach reply given chat history + CV context |
| `_callGemini` | Internal — all methods use this to POST prompt |

### GeminiEmbeddingService — semantic similarity

| Method | Purpose |
|--------|---------|
| `getEmbedding` | POST to `text-embedding-004` → list of numbers (vector) |
| `getCachedEmbedding` | Save/load vector in SharedPreferences to avoid repeat API calls |

**Why embeddings?** Convert text to numbers. Similar meanings → similar vectors. Used to compare CV text vs job description text.

### JobMatchingService — match scores

| Method | Purpose |
|--------|---------|
| `skillOverlapScore` | Count overlapping skills (fuzzy match) |
| `structuredMatchScore` | Skills + experience level + education level → 0–100 **sync, no API** |
| `calculateMatch` | Gets embeddings for CV + job, cosine similarity, blends 45% embedding + 55% structured |
| `cosineSimilarity` | Math between two vectors |
| `categorise` | Score → Excellent / Good / Fair / Low |
| `buildCvText` / `buildJobText` | Flatten model to string for embedding |

### CvParserService — CV pipeline

| Method | Purpose |
|--------|---------|
| `pickAndUploadFile` | file_picker → upload to Storage |
| `parseAndSave` | PDF text (Syncfusion) → AiService.parseCv → merge into profile doc |
| `saveProfile` | Manual edit save |
| `profileStream` | Live stream of `users/{uid}/cvs/profile` |
| `ensureSingleProfile` / `consolidateProfiles` | Merge old duplicate CV docs into one `profile` |
| `migrateLegacyCvIfNeeded` | Move `cvs/{uid}` → new path |
| `deleteProfile` | Clear CV data |

**Canonical doc ID:** `kCandidateProfileDocId = 'profile'`

### Notification services

| Service | Role |
|---------|------|
| `NotificationService` | FCM permission, get token, save to `users/{uid}.fcmToken` |
| `LocalNotificationService` | Show OS notification when app is open |
| `JobMatchNotificationService` | Scan jobs vs CV skills → create inbox alerts (≥40% match) |
| `fcm_background.dart` | Handle push when app in background |

### ShareService

`shareJob` — shares deep link `jobscope:///jobs/{id}` via `share_plus`.

---

## 14. Providers — complete index

Grouped by feature. **Type** = Riverpod provider type.

### Auth

| Provider | Type | Purpose |
|----------|------|---------|
| `authRepositoryProvider` | Provider | AuthRepository instance |
| `firebaseUserProvider` | StreamProvider | Firebase Auth user stream |
| `currentUserProvider` | AsyncNotifierProvider | UserModel + `setUser()` |
| `profilePhotoLocalCacheProvider` | NotifierProvider | In-memory photo bytes |
| `profilePhotoBytesProvider` | FutureProvider.family | Download photo from Storage |

### Jobs & bookmarks

| Provider | Type | Purpose |
|----------|------|---------|
| `jobRepositoryProvider` | Provider | JobRepository |
| `jobsStreamProvider` | StreamProvider | All active jobs |
| `jobFilterProvider` | NotifierProvider | Search/filter UI state |
| `filteredJobsProvider` | Provider | Jobs after filters applied |
| `matchSortedJobsProvider` | Provider | Sorted by structuredMatchScore |
| `bookmarkedIdsProvider` | StreamProvider | Bookmark IDs |
| `bookmarkNotifierProvider` | NotifierProvider | Toggle bookmark |
| `savedJobsProvider` | FutureProvider | Full JobModels for bookmarks |
| `singleJobProvider` | StreamProvider.family | One job live |
| `paginatedJobsProvider` | NotifierProvider | Pagination (unused in main UI) |

### Job folders (collections)

| Provider | Type | Purpose |
|----------|------|---------|
| `collectionsStreamProvider` | StreamProvider | User’s folders |
| `folderJobsProvider` | FutureProvider.family | Jobs in one folder |
| `collectionNotifierProvider` | NotifierProvider | Create/rename/delete folder |

### CV

| Provider | Type | Purpose |
|----------|------|---------|
| `cvParserServiceProvider` | Provider | CvParserService |
| `cvProfileMigrationProvider` | FutureProvider | One-time legacy merge |
| `cvStreamProvider` | StreamProvider | **Main CV stream** for UI |
| `cvUploadProvider` | NotifierProvider | Upload/parse/delete file |
| `cvProfileEditProvider` | NotifierProvider | Manual profile save |

### Applications

| Provider | Type | Purpose |
|----------|------|---------|
| `applicationRepositoryProvider` | Provider | ApplicationRepository |
| `myApplicationsProvider` | StreamProvider | Candidate’s applications |
| `hasAppliedProvider` | StreamProvider.family | Applied? per jobId |
| `applicationByIdProvider` | StreamProvider.family | Single app live |
| `applyNotifierProvider` | NotifierProvider | **Submit application** |
| `withdrawNotifierProvider` | NotifierProvider | Withdraw pending |
| `applicationDraftProvider` | StreamProvider.family | Draft per job |
| `applicationDraftNotifierProvider` | NotifierProvider | Save draft |

### AI & matching

| Provider | Type | Purpose |
|----------|------|---------|
| `aiServiceProvider` | Provider | AiService |
| `jobMatchingServiceProvider` | Provider | JobMatchingService |
| `jobMatchResultProvider` | FutureProvider.family | Full embedding match for one job |
| `matchReasonsProvider` | FutureProvider.family | AI “why match” text |
| `coverLetterProvider` | FutureProvider.family | Generate cover letter |
| `saveCoverLetterProvider` | NotifierProvider | Save to Firestore |
| `interviewQuestionsProvider` | FutureProvider.family | Interview practice Qs |
| `skillQuizProvider` | FutureProvider.family | Skill quiz |
| `trainBeforeApplyQuestionsProvider` | FutureProvider.family | Training questions |
| `latestCompletedTrainingProvider` | StreamProvider.family | Gate apply if score < 60 |

### Recruiter

| Provider | Type | Purpose |
|----------|------|---------|
| `recruiterJobsStreamProvider` | StreamProvider | Recruiter’s jobs |
| `jobApplicationsStreamProvider` | StreamProvider.family | Apps per job |
| `sortedApplicantsProvider` | Provider.family | Filtered + sorted by matchScore |
| `applicantFilterProvider` | NotifierProvider | all/pending/shortlisted filter |
| `recruiterAnalyticsProvider` | Provider | Acceptance rate, stats |
| `recruiterApplicantTopSkillsProvider` | FutureProvider | Top skills chart |
| `recruiterStatsProvider` | Provider | Dashboard counts |
| `candidateCvProvider` | FutureProvider.family | Applicant’s CV |
| `recruiterTabIndexProvider` | NotifierProvider | Bottom nav index |

### Interviews

| Provider | Type | Purpose |
|----------|------|---------|
| `candidateInterviewsProvider` | StreamProvider | Candidate’s interviews |
| `recruiterInterviewsProvider` | StreamProvider | Recruiter’s interviews |
| `interviewNotifierProvider` | AsyncNotifierProvider | Propose/confirm/cancel |
| `pendingInterviewsCountProvider` | Provider | Badge count |

### Notifications

| Provider | Type | Purpose |
|----------|------|---------|
| `notificationsStreamProvider` | StreamProvider | Inbox |
| `unreadNotificationsCountProvider` | StreamProvider | Unread badge |
| `fcmBootstrapProvider` | Provider<void> | Start FCM on login |
| `jobMatchNotificationBootstrapProvider` | Provider<void> | One-time job match scan |
| `notificationsEnabledProvider` | Provider | Settings toggle |
| `notificationActionsProvider` | Provider | Mark read, delete helpers |

### Messaging & coach

| Provider | Type | Purpose |
|----------|------|---------|
| `conversationsProvider` | StreamProvider | DM list |
| `messagesProvider` | StreamProvider.family | Messages in thread |
| `messagingNotifierProvider` | AsyncNotifierProvider | Send message |
| `coachChatStreamProvider` | StreamProvider | Coach history |
| `coachChatNotifierProvider` | NotifierProvider | Send coach message |

### Settings & nav

| Provider | Type | Purpose |
|----------|------|---------|
| `settingsProvider` | AsyncNotifierProvider | All prefs |
| `themeModeProvider` | Provider | Light/dark |
| `candidateTabProvider` | NotifierProvider | Candidate tab index |
| `applicationsTabProvider` | NotifierProvider | Applications sub-tabs |

---

## 15. Screens — every UI screen

### Auth flow

| Screen | File | What user does |
|--------|------|----------------|
| Onboarding | `onboarding_screen.dart` | Swipe intro → Get started |
| Role selection | `role_selection_screen.dart` | Pick candidate or recruiter |
| Login | `login_screen.dart` | Email/password → `signIn` → `setUser` |
| Signup | `signup_screen.dart` | Create account |
| Edit profile | `edit_profile_screen.dart` | Name, bio, camera/gallery photo |

### Candidate home (4 tabs) — `candidate_home_screen.dart`

Uses **lazy tabs** — only builds a tab the first time you open it (performance).

| Tab | Screen | Purpose |
|-----|--------|---------|
| Home | `dashboard_screen.dart` | Stats, shortcuts, upload CV, browse jobs |
| Jobs | `jobs_screen.dart` | Search, filter, sorted job list |
| Apply | `applications/presentation/applications_screen.dart` | **Real** applications list |
| Profile | `profile_screen.dart` | Links to CV, settings, notifications |

**FAB:** AI Coach button → `career_coach_screen.dart`

### Job-related screens

| Screen | Purpose |
|--------|---------|
| `job_detail_screen.dart` | Full job info, match badge, apply, train, cover letter |
| `jobs_screen.dart` | List + filters + bookmarks tab |
| `job_deep_link_screen.dart` | Open job from shared link |
| `folder_detail_screen.dart` | Jobs inside a saved folder |
| `job_filter_sheet.dart` | Bottom sheet filters |
| `match_badge_widget.dart` | Colored % badge |
| `match_reasons_sheet.dart` | AI explanation popup |
| `cover_letter_sheet.dart` | Generate/save cover letter |
| `train_before_apply_sheet.dart` | 5 questions + readiness score |
| `job_card_widget.dart` | Single job row in list |

### CV screens

| Screen | Purpose |
|--------|---------|
| `cv_screen.dart` | View profile, upload/replace CV |
| `edit_cv_profile_screen.dart` | Edit skills, experience, education manually |
| `ai_cv_builder_screen.dart` | Gemini generates CV from prompts |

### Application screens

| Screen | Purpose |
|--------|---------|
| `applications_screen.dart` | Tabs: active / withdrawn applications |
| `application_detail_screen.dart` | Timeline, status, withdraw button |
| `application_status_badge.dart` | Colored status chip |
| `application_card_widget.dart` | Row in list |

### AI feature screens

| Screen | Purpose |
|--------|---------|
| `interview_training_screen.dart` | **Dashboard** interview practice (NOT train-before-apply) |
| `skill_assessment_screen.dart` | Quiz from your skills |
| `career_coach_screen.dart` | Chat with AI about career |

### Recruiter home (5 tabs) — `recruiter_home_screen.dart`

| Tab | Screen | Purpose |
|-----|--------|---------|
| Dashboard | `recruiter_dashboard_screen.dart` | Overview stats |
| Post Job | `post_job_screen.dart` | Create/edit job form |
| My Jobs | `recruiter_jobs_screen.dart` | List jobs → tap → applicants |
| Analytics | `recruiter_analytics_screen.dart` | Charts (fl_chart) |
| Profile | `profile_screen.dart` | Shared with candidate |

| Screen | Purpose |
|--------|---------|
| `job_applicants_screen.dart` | List applicants sorted by match |
| `applicant_detail_screen.dart` | View CV, shortlist/reject, message, interview |
| `schedule_interview_sheet.dart` | Propose time slots |

### Other

| Screen | Purpose |
|--------|---------|
| `notifications_screen.dart` | Inbox, mark read, swipe delete |
| `conversations_screen.dart` | DM list |
| `chat_screen.dart` | Single conversation |
| `candidate_interviews_screen.dart` | Confirm interview slots |
| `settings_screen.dart` | Dark mode, notification toggle |
| `about_screen.dart`, `help_screen.dart`, `legal_screen.dart` | Info pages |

### ⚠️ STUBS — not used in navigation (ignore these)

| File | Why confusing |
|------|---------------|
| `home/presentation/applications_screen.dart` | Old stub — **not** the real applications tab |
| `home/presentation/applicants_screen.dart` | Unused stub |

---

## 16. Data flows — step by step

### Flow A — Sign up & login

```
1. User picks role on RoleSelectionScreen
2. SignupScreen collects name, email, password
3. AuthRepository.signUp():
   a. firebase_auth.createUserWithEmailAndPassword
   b. Write users/{uid} with role, name, email
   c. Cache role in SharedPreferences (offline fallback)
4. currentUserProvider.notifier.setUser(userModel)
5. go_router redirect → candidate-home OR recruiter-home
```

**Why `setUser()`?** Router needs role immediately. Waiting only for Firebase stream can show wrong home briefly.

### Flow B — Upload & parse CV

```
1. User opens CvScreen → taps upload
2. cvUploadProvider → CvParserService.pickAndUploadFile()
   a. file_picker opens PDF/DOCX
   b. Upload bytes to Firebase Storage cvs/{uid}/...
3. parseAndSave():
   a. Syncfusion extracts text from PDF
   b. AiService.parseCv(text) → Gemini returns skills, jobs, education JSON
   c. Merge into users/{uid}/cvs/profile (doc id "profile")
4. cvStreamProvider emits new CvModel
5. Dashboard shows updated profile strength & skills
```

### Flow C — Browse jobs & see match

```
1. jobsStreamProvider listens to jobs where isActive=true
2. jobFilterProvider holds search text + filters
3. filteredJobsProvider applies filters client-side
4. If user has CV with skills:
   matchSortedJobsProvider sorts by structuredMatchScore (local, instant)
5. JobsScreen displays list with JobCardWidget
6. Tap job → JobDetailScreen with JobModel in extra
7. jobMatchResultProvider runs calculateMatch (embeddings) for badge on detail
```

### Flow D — Apply to job

```
1. JobDetailScreen → Apply button
2. Optional: Train Before Apply completed with readinessScore < 60 → blocked
3. applyNotifierProvider.apply(jobId):
   a. Read currentUser, cvStreamProvider
   b. Fetch job from JobRepository
   c. JobMatchingService.calculateMatch(cv, job) → matchScore
   d. ApplicationRepository.apply(...) writes applications/{id}
      - status: pending
      - matchScore, cv snapshot, candidate info
   e. NotificationRepository.notifyRecruiterNewApplication
   f. UserStatsRepository.refreshApplicationStats
4. hasAppliedProvider(jobId) → true → UI shows "Applied"
5. myApplicationsProvider stream adds new row
```

### Flow E — Recruiter reviews applicant

```
1. RecruiterJobsScreen → tap job → JobApplicantsScreen
2. sortedApplicantsProvider sorts by matchScore desc
3. Tap applicant → ApplicantDetailScreen
4. Recruiter taps Shortlist:
   ApplicationRepository.updateStatus(shortlisted)
   → updatedAt set
   → NotificationRepository.notifyCandidateStatusChange
5. Candidate ApplicationsScreen updates via stream
6. If app open + notifications on:
   LocalNotificationService.showStatusChange(...)
```

### Flow F — Withdraw application

```
1. ApplicationDetailScreen → Withdraw (only if pending)
2. withdrawNotifierProvider → ApplicationRepository.withdraw
3. status → withdrawn (document NOT deleted)
4. User can apply to same job again (new application doc)
```

### Flow G — Train before apply

```
1. JobDetailScreen → Train Before Apply sheet
2. trainBeforeApplyQuestionsProvider → AiService generates 5 questions
3. User answers each → evaluateTrainAnswer → score per question
4. readinessScore = average of 5 scores
5. TrainingRepository saves to users/{uid}/training_sessions/{id}
6. latestCompletedTrainingProvider watched on detail screen
7. If isComplete && readinessScore < 60 → Apply disabled
```

### Flow H — Notifications inbox

```
Triggers:
- Candidate applies → recruiter inbox doc
- Recruiter changes status → candidate inbox doc
- Job matches CV skills (bootstrap scan) → candidate inbox doc
- New DM → recipient inbox doc

UI:
notificationsStreamProvider → NotificationsScreen
Tap → notification_navigation.dart deep links to job/app/chat
unreadNotificationsCountProvider → badge on profile/dashboard
```

### Flow I — Dark mode

```
1. SettingsScreen toggles switch
2. settingsProvider saves to SharedPreferences
3. themeModeProvider updates
4. JobScopeApp rebuilds with new ThemeMode
5. AppColors.applyBrightness updates semantic colors
```

---

## 17. AI & job matching — how scores work

### Two scoring paths (important for exams)

| Where | Method | Uses Gemini API? | Speed |
|-------|--------|------------------|-------|
| Jobs **list** sort | `structuredMatchScore` | **No** | Instant |
| Job **detail** badge | `calculateMatch` | **Yes** (embeddings) | Slower |
| **Apply** button | `calculateMatch` | **Yes** | Saves to Firestore |

### structuredMatchScore (local)

1. **Skill overlap** — compare CV skills vs job skills (fuzzy, case insensitive)
2. **Experience level** — compare CV level vs job required level
3. **Education level** — compare degrees
4. Blend based on what job requires

### calculateMatch (AI + local)

1. Compute `structuredMatchScore`
2. Get embedding vectors for CV text and job text (cached in SharedPreferences)
3. `cosineSimilarity` → embeddingScore 0–100
4. If structured is 0: use embedding only
5. Else: `0.45 * embedding + 0.55 * structured`
6. If API fails: fallback to structured only

### Profile strength (0–100)

`CvProfileStrength.fromCv(cv)` in `cv_profile_strength.dart` — points for skills count, work history, education, levels, uploaded file. Shown on dashboard and CV screen as completeness meter.

---

## 18. Notifications — three layers

| Layer | Technology | When user sees it |
|-------|------------|-------------------|
| **1. Firestore inbox** | `users/{uid}/notifications/` | Always in app Notifications screen |
| **2. Local OS notification** | `flutter_local_notifications` | App open, status change, foreground FCM |
| **3. FCM push** | `firebase_messaging` + Cloud Function (optional) | App closed/background — needs server deploy |

**Settings toggle** (`notificationsEnabledProvider`) gates layers 2 and 3; inbox (layer 1) still works.

**On login:** `fcmBootstrapProvider` requests permission, saves FCM token to user doc.

---

## 19. Settings & theme

| Setting | Stored in | Provider |
|---------|-----------|----------|
| Dark mode | SharedPreferences | `themeModeProvider` |
| Notifications on/off | SharedPreferences | `notificationsEnabledProvider` |

Screens: Settings → About, Help, Privacy, Terms (legal text + url_launcher for external links).

---

## 20. Exam Q&A — rapid answers

**Q: What is Riverpod?**  
A: Flutter state management. Stores app data in providers; UI watches providers and rebuilds on change.

**Q: ref.watch vs ref.read?**  
A: watch = in build, auto-rebuild; read = one-time in callbacks.

**Q: What wraps the app?**  
A: ProviderScope → JobScopeApp → MaterialApp.router.

**Q: Firestore database name?**  
A: `jobscope` (named database, not default).

**Q: Where is CV stored?**  
A: `users/{uid}/cvs/profile` document id `profile`.

**Q: firebaseUserProvider vs currentUserProvider?**  
A: First = Auth only; second = full profile with role from Firestore.

**Q: Why setUser() after login?**  
A: Router needs role immediately without waiting for stream.

**Q: Real applications screen path?**  
A: `features/applications/presentation/applications_screen.dart`.

**Q: Application status pending shows as?**  
A: "Under Review" in UI.

**Q: Where is matchScore written?**  
A: `applyNotifierProvider` → `ApplicationRepository.apply()` → field on `applications/{id}`.

**Q: Jobs list vs detail matching?**  
A: List uses structuredMatchScore (no API); detail/apply uses calculateMatch with embeddings.

**Q: Train before apply blocks below what score?**  
A: 60 (only after training completed).

**Q: Package for routing / state / PDF / charts?**  
A: go_router / flutter_riverpod / syncfusion_flutter_pdf / fl_chart.

**Q: How is duplicate apply prevented?**  
A: ApplicationRepository checks existing doc for same candidateId + jobId before create.

**Q: Withdraw vs delete?**  
A: Withdraw sets status `withdrawn`, keeps doc; user can re-apply.

**Q: Recruiter applicant sort?**  
A: `sortedApplicantsProvider` by matchScore descending.

**Q: Gemini API key source?**  
A: `.env` file → flutter_dotenv → Secrets.geminiApiKey.

**Q: Three notification types?**  
A: Firestore inbox, local OS notifications, FCM push.

**Q: Interview training vs train before apply?**  
A: Different screens — dashboard practice vs job detail gate before apply.

**Q: What library extracts PDF text?**  
A: syncfusion_flutter_pdf.

**Q: Candidate vs recruiter home routes?**  
A: `/candidate-home` vs `/recruiter-home`.

**Q: How pass JobModel to detail screen?**  
A: `context.push(AppRoutes.jobDetail, extra: jobModel)`.

**Q: What is AsyncValue?**  
A: Wrapper with loading/data/error states from StreamProvider/FutureProvider.

**Q: What is a Notifier?**  
A: Riverpod class holding mutable state + methods like apply(), toggle().

**Q: Legacy CV path?**  
A: `cvs/{uid}` — migrated to profile doc on login.

**Q: Soft delete job?**  
A: `isDeleted: true`, `isActive: false` — hidden from recruiter, doc remains.

**Q: Who notifies recruiter on apply?**  
A: NotificationRepository.notifyRecruiterNewApplication from apply flow.

---

## 21. Glossary

| Term | Definition |
|------|------------|
| **Widget** | UI building block in Flutter |
| **Provider** | Riverpod unit that supplies data to widgets |
| **Repository** | Class that reads/writes Firestore |
| **Service** | Class with business logic (AI, parsing, scoring) |
| **Stream** | Sequence of async values over time |
| **Future** | Single async result |
| **Firestore** | Firebase JSON database |
| **FCM** | Firebase Cloud Messaging — push notifications |
| **Embedding** | Numeric vector representing text meaning |
| **go_router** | URL-based navigation package |
| **extra** | Object passed between routes (not in URL) |
| **AsyncNotifier** | Provider that loads async state on startup |
| **family** | Provider parameterized by ID (e.g. per job) |
| **autoDispose** | Provider destroyed when unused |

---

## 22. Traps & things that confuse people

1. **Two applications screens** — only `features/applications/presentation/applications_screen.dart` is real.

2. **pending ≠ "Pending" in UI** — displays as **"Under Review"**.

3. **Two user providers** — Auth user vs UserModel with role.

4. **Two interview features** — `interview_training_screen` (practice) vs `train_before_apply_sheet` (gate apply).

5. **List match ≠ detail match** — different algorithms for performance.

6. **Firestore DB is `jobscope`** — not default.

7. **CV is one doc `profile`** — not multiple CV docs anymore.

8. **Withdraw doesn't delete** — status changes to withdrawn.

9. **README may say "planned"** for cover letter & career coach — they exist in code.

10. **Debug google-services.json override** — must NOT exist in `android/app/src/debug/` or auth breaks with dummy API key.

11. **AGENTS.md says `cvs/{uid}`** — canonical path is now `users/{uid}/cvs/profile`.

12. **Lazy tabs** — candidate/recruiter home only build tabs when first opened (performance fix).

---

## Quick reference card (print this)

```
STACK:     Screen → Provider → Repository/Service → Firestore/Gemini
STATE:     flutter_riverpod (watch/read, StreamProvider, Notifier)
NAV:       go_router (AppRoutes, extra, auth redirect)
DB:        Firestore database "jobscope"
AUTH:      firebase_auth + users/{uid}.role
CV:        users/{uid}/cvs/profile
APPLY:     applyNotifier → applications/ + matchScore
MATCH:     list=structured | detail=embeddings+calculateMatch
ROLES:     candidate → /candidate-home (4 tabs)
           recruiter → /recruiter-home (5 tabs)
AI:        AiService (text) + GeminiEmbeddingService (vectors)
KEY:       .env GEMINI_API_KEY, firebase_options.dart, google-services.json
```

---

*End of handbook. For feature completion status see FEATURE_TRACKER.md; for manual test scripts see TEST_CASES.md.*
