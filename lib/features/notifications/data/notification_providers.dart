import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/firestore_helpers.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/job_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../auth/data/auth_providers.dart';

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

/// Saves FCM token on user doc (mobile; web may return null).
final fcmTokenSyncProvider = FutureProvider<void>((ref) async {
  if (kIsWeb) return;
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return;

  try {
    final service = NotificationService();
    await service.initialize();
    final token = await service.getToken();
    if (token == null) return;
    await firestoreWrite(
      appFirestore.collection('users').doc(user.uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      ),
    );
  } catch (_) {
    // FCM optional until Cloud Function push is deployed.
  }
});

class NotificationActions {
  NotificationActions(this._repo);
  final NotificationRepository _repo;

  Future<void> markRead(String userId, String id) =>
      _repo.markRead(userId, id);

  Future<void> markUnread(String userId, String id) =>
      _repo.markUnread(userId, id);

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
