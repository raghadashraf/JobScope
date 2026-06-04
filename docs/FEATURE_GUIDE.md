# Feature Build Guide (Agent Template)



Use this **before writing code** for any new task. Read [AGENTS.md](../AGENTS.md) for project context. Check status in [FEATURE_TRACKER.md](./FEATURE_TRACKER.md) — no full-codebase search needed.



Log completed work in [FEATURE_TRACKER.md](./FEATURE_TRACKER.md).

---

## Mandatory rules (agents)

1. **No Git** — Do not run any git/gh commands. Humans commit; you edit files and update the tracker.
2. **Protect existing features** — Minimal, scoped diff. Do not break or remove working flows to force the new feature through. Changing shared code is OK only when it **improves the app overall** (bugfix, shared helper)—then re-test affected [TEST_CASES.md](./TEST_CASES.md) flows.

---

## Agile rule



Ship **one thin vertical slice** per PR/session — user-visible, testable, mergeable in hours—not days.



| Good slice | Bad slice |

|------------|-----------|

| “Apply button writes `matchScore` to Firestore” | “Entire notifications system + settings + FCM” |

| “In-app notifications list (read-only)” | “Rebuild auth and add notifications” |



---



## Do not redo — extend instead



Only for areas that are **already implemented**. Read [FEATURE_TRACKER.md](./FEATURE_TRACKER.md) for your task ID (✅/🟡). Full table: [TEST_CASES.md § Do not redo](./TEST_CASES.md#do-not-redo-extend-only).



| Task | Extend these — do not rebuild |

|------|-----------------------------|

| Apply + application states | `applyNotifierProvider`, `application_repository.dart`, `job_detail_screen.dart` |

| Recruiter accept/reject/shortlist | `applicant_detail_screen.dart`, `job_applicants_screen.dart` |

| Candidate applications UI | `features/applications/applications_screen.dart` |

| Match on job cards (candidate) | `jobMatchResultProvider`, `match_badge_widget.dart` |

| Recruiter applicant sort by match | Add `matchScore` on apply (**D0-1**) — list sort already exists |

| Train vs interview | New **Train Before Apply** on job detail — not `interview_training_screen.dart` |

| Notifications | Add Firestore inbox + screen — keep `LocalNotificationService` for foreground alerts |

| Settings / dark mode | Wire `AppTheme.darkTheme` + route — `ThemeMode.light` forced in `main.dart` today |



---



## 1. Intake (5 min)



```

[ ] Task ID from FEATURE_TRACKER (e.g. D0-1)

[ ] Tracker status: not ✅ complete for this slice

[ ] User role: candidate / recruiter / both

[ ] Acceptance criteria (3 bullets max)

[ ] Out of scope for this slice: ...

```



**Stop** if the slice needs unrelated refactors—split the task instead.



---



## 2. Design (10 min)



### Where code lives



| Layer | Path | Add when |

|-------|------|----------|

| Model | `lib/data/models/` | New Firestore entity or new fields on existing doc |

| Repository | `lib/data/repositories/` | Shared CRUD used by 2+ features |

| Service | `lib/core/services/` | External API (Gemini, FCM), no UI |

| Providers | `lib/features/<feature>/data/*_providers.dart` | State, streams, actions |

| UI | `lib/features/<feature>/presentation/` | Screens, sheets, widgets |

| Route | `lib/core/utils/app_router.dart` | New screen needs deep link or auth guard |



**Do not** create parallel folders (`lib/screens/`, `lib/providers/` global dump).



### Firestore changes



1. Extend existing model `toMap()` / `fromMap()` — same field names as DB.

2. Document new paths in [FEATURE_TRACKER.md](./FEATURE_TRACKER.md) and [AGENTS.md](../AGENTS.md) Firestore table.

3. Prefer **subcollections** under `users/{uid}` for user-owned data; top-level for shared entities (`jobs`, `applications`).



### Navigation



- Add `AppRoutes.<name>` constant.

- Register `GoRoute` in `routerProvider`.

- Pass data via `extra` (typed model)—not query strings for complex objects.

- Role-specific UI stays in role’s feature folder; shared profile in `home/`.



### State (Riverpod 3)



```dart

// Read: StreamProvider / FutureProvider

// Write: Notifier or AsyncNotifier — NEVER StateNotifier

final fooProvider = NotifierProvider<FooNotifier, FooState>(FooNotifier.new);

```



- Watch `currentUserProvider` or `firebaseUserProvider` for uid.

- Invalidate with `ref.invalidate(provider)` after profile updates.



### UI consistency



- Colors: `AppColors` — Primary `#0A66C2`, recruiter accent `secondary`

- Copy: `AppStrings` when reused

- Typography: `GoogleFonts.plusJakartaSans` (titles), `GoogleFonts.inter` (body)

- Cards: 16px radius, `AppColors.border`, light shadow

- Errors: `SnackBar` floating, `AppColors.error` / `success`



---



## 3. Implementation order



Always build **bottom → top**:



1. Model fields (if any)

2. Repository method(s) with `.timeout()` on writes

3. Provider / notifier

4. Widget (minimal)

5. Route + entry point (button / nav)

6. **Run test cases** for this slice ([TEST_CASES.md](./TEST_CASES.md)) — do not start next slice until pass

7. `flutter analyze` on touched files



### 3.1 Test after every iteration (required)



1. `flutter analyze` (touched files / project)

2. Run the **matching section(s)** in [TEST_CASES.md](./TEST_CASES.md) (demo accounts + step tables)

3. If the slice touches Firestore, confirm in Firebase Console (`jobscope-app`)

4. Log result in FEATURE_TRACKER handoff (template below)



**Fail criteria** — do not mark slice done if: analyzer errors, happy-path TC failed, duplicate feature path added, tracker not updated.



```markdown

### Test record — [slice ID] — YYYY-MM-DD

- Cases run: e.g. TC-N1, TC-N2

- Result: pass / fail

- Firestore checked: Y/N — path: …

```



| Building… | Test section in TEST_CASES.md |

|-----------|-------------------------------|

| D0-1 matchScore | D0-1 |

| D2 apply / status | D2 |

| D1 train before apply | D1 |

| D3 notifications | TC-N1 … TC-N4 |

| D4 settings | D4 |

| R1 / R2 / H2 / H3 smoke | Bottom of TEST_CASES.md |



---



## 4. Integration checklist (final gate)



```

[ ] TEST_CASES.md scenarios for this slice: pass

[ ] Test record in FEATURE_TRACKER handoff

[ ] No new analyzer errors in touched files

[ ] FEATURE_TRACKER.md updated (required)

[ ] AGENTS.md updated only if routes/collections changed

```



---



## 5. Slice summary (for human commit — agents do not use Git)

Optional text for the **human** to paste into their own commit/PR:

**Title:** `feat(<area>): <one-line outcome>`



**Body:**

- What: user-visible change

- How: files touched (bullet list)

- Firestore: schema change Y/N

- Tested: TC-IDs from TEST_CASES.md



---



## 6. Feature doc entry (copy to FEATURE_TRACKER)



When closing a slice, append:



```markdown

### [FEATURE-ID] Short name — YYYY-MM-DD — @owner



**Status:** done | in-progress | blocked



**Slice:** one sentence of what shipped.



**Files:**

- `path/to/file.dart` — role



**Firestore:** `collection/path` fields added/changed



**Providers:** `fooProvider`, `barNotifier`



**Routes:** `AppRoutes.xyz` (if any)



**How it works:** 2–4 sentences data flow.



**Depends on:** CV, auth, etc.



**Known limits:** what’s intentionally not done yet.



**Challenges/fixes:** optional — for next agent session

```



---



## 7. Example slices (David-scale)



| Task area | Slice 1 | Slice 2 | Slice 3 |

|-----------|---------|---------|---------|

| Apply flow | Persist `matchScore` on apply | — | Withdraw + timeline polish |

| Training | Firestore `training_sessions` model + save | Job-detail gate UI | AI evaluate answer |

| Notifications | Firestore `notifications` + list UI | Unread badge | FCM token + Function doc |

| Settings | `ThemeMode` from SharedPreferences | Settings route + toggle | Notification prefs |



---



## Quick links



- [AGENTS.md](../AGENTS.md) — architecture

- [FEATURE_TRACKER.md](./FEATURE_TRACKER.md) — what’s built

- [TEST_CASES.md](./TEST_CASES.md) — demo scripts per feature

- [DAVID_PLAN.md](./DAVID_PLAN.md) — David’s prioritized backlog


