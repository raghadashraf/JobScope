# D3-6 — FCM push (phase 2)

The app **already** delivers notifications via Firestore inbox (`users/{uid}/notifications`).  
This doc describes how to add **push when the app is killed** — requires a **Cloud Function** (not client-only).

## Client (done in app)

| Piece | Location |
|-------|----------|
| Permission + token | `NotificationService.syncTokenForUser` |
| Token on user doc | `users/{uid}.fcmToken` |
| Foreground FCM banner | `fcmListenersProvider` → `LocalNotificationService.showInboxAlert` |
| Background handler | `fcm_background.dart` + `main.dart` |

**Web:** FCM token sync is skipped (`kIsWeb`). In-app inbox still works.

## Deploy checklist (Firebase Console)

1. Enable **Cloud Messaging** for project `flutter-ai-playground-2379c`.
2. Add **Android** `google-services.json` / **iOS** APNs key if testing on device.
3. Deploy a function (example below) when ready.
4. Manual test: kill app on phone → trigger TC-N1 or TC-N2 → expect OS notification.

## Example function (Node 20)

Create `functions/` in repo root (not committed yet) and deploy:

```js
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { initializeApp } = require('firebase-admin/app');

initializeApp();
const db = getFirestore();
db.settings({ databaseId: 'jobscope' });

exports.pushOnInboxNotification = onDocumentCreated(
  'users/{uid}/notifications/{notificationId}',
  async (event) => {
    const uid = event.params.uid;
    const data = event.data?.data();
    if (!data || data.read === true) return;

    const userSnap = await db.collection('users').doc(uid).get();
    const token = userSnap.get('fcmToken');
    if (!token) return;

    await getMessaging().send({
      token,
      notification: {
        title: data.title || 'JobScope',
        body: data.body || '',
      },
      data: {
        type: data.type || '',
        relatedId: data.relatedId || '',
        applicationId: data.applicationId || '',
        jobId: data.jobId || '',
        conversationId: data.conversationId || '',
      },
    });
  }
);
```

Point `firebase.json` at database `jobscope` (same as app). See [FIRESTORE_SETUP.md](./FIRESTORE_SETUP.md).

## Test mapping

| Test | In-app inbox | FCM push |
|------|----------------|----------|
| TC-N1 | ✅ | After function deploy |
| TC-N2 | ✅ | After function deploy |
| TC-N3 | ✅ | N/A |
| TC-N5 | ✅ | After function deploy |

Until the function is deployed, document **FCM: skipped** in TEST_CASES manual records.

---

## Should you add this? (decision guide)

### What you already have (no Function required)

| Scenario | Works today? |
|----------|----------------|
| User opens app → sees inbox, badge, tap to navigate | ✅ Firestore inbox |
| User has app open → status change local banner | ✅ `LocalNotificationService` |
| Recruiter/candidate testing on **Chrome** | ✅ Inbox only (no FCM on web) |
| Demo / class submission focused on apply + notifications list | ✅ Enough |

### What the Cloud Function adds

| Scenario | Needs Function? |
|----------|-----------------|
| Phone **locked or app swiped away** → OS notification appears | ✅ Yes |
| True “push notification” in project rubric | ✅ Often yes |
| Web-only testers | ❌ No benefit |

### Why the app cannot send push by itself

- Your Flutter app can **receive** FCM and save `fcmToken` on `users/{uid}`.
- Sending push **to another user’s device** requires a **server** with Firebase Admin SDK (secret credentials). Putting that secret in the mobile app would be insecure and is not supported.
- Flow: event → write `users/{uid}/notifications/{id}` (already in app) → **Function** reads new doc → `admin.messaging().send({ token: user.fcmToken, ... })`.

### Costs and effort (rough)

| Item | Notes |
|------|--------|
| Firebase Blaze plan | Cloud Functions need billing enabled (free tier often covers class usage) |
| Setup time | ~1–2 hours: `functions/` folder, `firebase deploy --only functions`, Android `google-services.json`, test on **physical device** |
| Maintenance | Function must target database **`jobscope`** (same as app) |
| Duplicate alerts | Inbox write + push can double-notify if app is open; optional: skip FCM when `read: false` and app foreground, or only push when no active session |

### Recommendation for JobScope

- **Skip for now** if graders test on Chrome / in-app inbox and D3 tracker is already ✅ for inbox + client FCM.
- **Add later** if you need a demo video showing a notification on a locked Android phone, or the rubric explicitly requires background push.

### Minimal deploy path (when you choose yes)

1. Firebase Console → upgrade to Blaze (if needed) → enable Cloud Messaging.
2. `firebase init functions` (Node 20) in project root; paste the example trigger above.
3. Set `databaseId: 'jobscope'` in Admin SDK (see example).
4. `firebase deploy --only functions`
5. Install release/debug build on Android, log in, confirm `users/{uid}.fcmToken` in Firestore.
6. Kill app → recruiter shortlists candidate → expect system tray notification.
