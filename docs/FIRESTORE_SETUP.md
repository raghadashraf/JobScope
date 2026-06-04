# Firestore setup (JobScope)

**Project ID:** `flutter-ai-playground-2379c` (console display name may be **JobScope**).

**Database ID:** `jobscope` (not `(default)`). The Flutter app uses `appFirestore` in `lib/core/utils/firestore_helpers.dart`.

## Step 1 — Create the Firestore database (required)

If post job always times out and `firebase deploy` says **Creating the new Firestore database** then fails with **403**:

1. Open [Firebase Console](https://console.firebase.google.com) → project **JobScope** / `flutter-ai-playground-2379c`
2. **Build → Firestore Database → Create database**
3. Mode: **Production** (you will add rules next)
4. Pick a region and finish the wizard

Until this exists, the Flutter app cannot write (SDK retries until timeout).

## Step 2 — Publish security rules

### Option A — CLI (project Owner/Editor)

```bash
firebase login
firebase deploy --only firestore:rules,firestore:indexes
```

### Option B — Console (paste manually)

1. **Firestore → Rules**
2. Replace all text with the contents of repo file `firestore.rules`
3. Click **Publish**

Rules allow **signed-in** users to read jobs and let recruiters **create** jobs when `recruiterId` equals their uid.

## Manual check in console

1. Firebase → **JobScope** (`flutter-ai-playground-2379c`) → Firestore → **Data**
2. Collection `jobs` should get new documents when you post from the app (not only the manual test doc).

## If post job still fails

1. Confirm you are **signed in** as a recruiter in the app.
2. Chrome **F12 → Console** — look for `permission-denied` or `unavailable`.
3. Re-run `firebase deploy --only firestore:rules`.
4. Try without VPN / ad blockers; or run `flutter run` on Android emulator.
