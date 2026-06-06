import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/job_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../core/services/job_match_notification_service.dart';
import '../../auth/data/auth_providers.dart';
import '../../cv_management/data/cv_providers.dart';
import '../../job_listing/data/job_providers.dart';
import '../../settings/data/settings_providers.dart';

final notificationRepositoryProvider =
    Provider<NotificationRepository>((_) => NotificationRepository());

final notificationsStreamProvider =
    StreamProvider<List<AppNotificationModel>>((ref) {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.read(notificationRepositoryProvider).notificationsStream(user.uid);
});

final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return Stream.value(0);
  return ref.read(notificationRepositoryProvider).unreadCountStream(user.uid);
});

/// Saves FCM token on user doc (mobile; skipped on web).
final fcmTokenSyncProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return;
  await NotificationService.syncTokenForUser(user.uid);
});

/// Foreground FCM + token refresh (mobile only).
final fcmListenersProvider = Provider<void>((ref) {
  if (kIsWeb) return;

  StreamSubscription<String>? tokenRefreshSub;
  StreamSubscription<RemoteMessage>? messageSub;

  void attach(String uid) {
    tokenRefreshSub?.cancel();
    messageSub?.cancel();

    tokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      NotificationService.saveTokenForUser(uid, token);
    });

    messageSub = FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ??
          message.data['title'] as String? ??
          'JobScope';
      final body = message.notification?.body ??
          message.data['body'] as String? ??
          '';
      LocalNotificationService().showInboxAlert(title: title, body: body);
    });
  }

  ref.listen(firebaseUserProvider, (_, next) {
    final uid = next.value?.uid;
    if (uid == null) {
      tokenRefreshSub?.cancel();
      messageSub?.cancel();
      tokenRefreshSub = null;
      messageSub = null;
      return;
    }
    attach(uid);
  });

  final uid = ref.read(firebaseUserProvider).value?.uid;
  if (uid != null) attach(uid);

  ref.onDispose(() {
    tokenRefreshSub?.cancel();
    messageSub?.cancel();
  });
});

/// Call from home shells: token sync + FCM listeners (respects settings).
final fcmBootstrapProvider = Provider<void>((ref) {
  if (!ref.watch(notificationsEnabledProvider)) return;
  ref.watch(fcmTokenSyncProvider);
  ref.watch(fcmListenersProvider);
});

class NotificationActions {
  NotificationActions(this._repo);
  final NotificationRepository _repo;

  Future<void> markRead(String userId, String id) =>
      _repo.markRead(userId, id);

  Future<void> markUnread(String userId, String id) =>
      _repo.markUnread(userId, id);

  Future<void> markAllRead(String userId) => _repo.markAllRead(userId);

  Future<void> delete(String userId, String id) => _repo.delete(userId, id);

  Future<void> notifyRecruiterNewApplication({
    required JobModel job,
    required ApplicationModel application,
  }) =>
      _repo.notifyRecruiterNewApplication(job: job, application: application);

  Future<void> notifyCandidateStatusChange({
    required ApplicationModel application,
    required ApplicationStatus newStatus,
  }) =>
      _repo.notifyCandidateStatusChange(
        application: application,
        newStatus: newStatus,
      );

  Future<void> notifyNewMessage({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String conversationId,
    required String messagePreview,
    String? jobTitle,
    String? applicationId,
  }) =>
      _repo.notifyNewMessage(
        recipientId: recipientId,
        senderId: senderId,
        senderName: senderName,
        conversationId: conversationId,
        messagePreview: messagePreview,
        jobTitle: jobTitle,
        applicationId: applicationId,
      );
}

final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref.read(notificationRepositoryProvider));
});

final jobMatchNotificationServiceProvider =
    Provider<JobMatchNotificationService>(
        (_) => JobMatchNotificationService());

bool _jobMatchNotificationsSynced = false;

/// Scans active jobs vs candidate CV skills and creates inbox alerts (once per job).
final jobMatchNotificationBootstrapProvider = Provider<void>((ref) {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) {
    _jobMatchNotificationsSynced = false;
    return;
  }

  Timer? debounce;

  Future<void> sync() async {
    if (_jobMatchNotificationsSynced) return;
    if (!ref.read(notificationsEnabledProvider)) return;
    final cv = ref.read(cvStreamProvider).value;
    final jobs = ref.read(jobsStreamProvider).value ?? [];
    if (jobs.isEmpty) return;

    _jobMatchNotificationsSynced = true;
    await ref.read(jobMatchNotificationServiceProvider).syncMatchNotifications(
          candidateId: user.uid,
          cv: cv,
          jobs: jobs,
          notifications: ref.read(notificationRepositoryProvider),
        );
  }

  void scheduleSync() {
    if (_jobMatchNotificationsSynced) return;
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 800), sync);
  }

  ref.onDispose(() => debounce?.cancel());
  ref.listen(jobsStreamProvider, (_, next) {
    if (next.hasValue) scheduleSync();
  });
  ref.listen(cvStreamProvider, (_, next) {
    if (next.hasValue) scheduleSync();
  });
  scheduleSync();
});
