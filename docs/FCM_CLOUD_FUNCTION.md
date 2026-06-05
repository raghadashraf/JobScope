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
