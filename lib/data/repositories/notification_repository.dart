import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/firestore_helpers.dart';
import '../models/application_model.dart';
import '../models/job_model.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = appFirestore;

  CollectionReference _inbox(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('notifications');

  Stream<List<AppNotificationModel>> notificationsStream(String uid) {
    return _inbox(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AppNotificationModel.fromDoc).toList());
  }

  Stream<int> unreadCountStream(String uid) {
    return _inbox(uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> create(AppNotificationModel notification, String userId) async {
    final ref = notification.id.isEmpty
        ? _inbox(userId).doc()
        : _inbox(userId).doc(notification.id);
    final id = ref.id;
    final data = firestoreEncode({
      ...notification.toMap(),
      'id': id,
      'read': notification.read,
    });
    await firestoreWrite(ref.set(data));
  }

  Future<void> markRead(String userId, String notificationId) async {
    await firestoreWrite(
      _inbox(userId).doc(notificationId).update({'read': true}),
    );
  }

  Future<void> markUnread(String userId, String notificationId) async {
    await firestoreWrite(
      _inbox(userId).doc(notificationId).update({'read': false}),
    );
  }

  Future<void> delete(String userId, String notificationId) async {
    await firestoreWrite(_inbox(userId).doc(notificationId).delete());
  }

  Future<void> markAllRead(String userId) async {
    final snap =
        await _inbox(userId).where('read', isEqualTo: false).get();
    if (snap.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await firestoreWrite(batch.commit());
  }

  Future<void> notifyRecruiterNewApplication({
    required JobModel job,
    required ApplicationModel application,
  }) async {
    await create(
      AppNotificationModel(
        id: '',
        type: NotificationType.newApplication,
        title: 'New application',
        body:
            '${application.candidateName} applied to ${job.title} at ${job.company}.',
        createdAt: DateTime.now(),
        relatedId: application.id,
        applicationId: application.id,
        jobId: job.id,
        jobTitle: job.title,
      ),
      job.recruiterId,
    );
  }

  Future<void> notifyCandidateStatusChange({
    required ApplicationModel application,
    required ApplicationStatus newStatus,
  }) async {
    if (newStatus == ApplicationStatus.pending ||
        newStatus == ApplicationStatus.withdrawn) {
      return;
    }

    final (title, body) = _statusCopy(application, newStatus);
    await create(
      AppNotificationModel(
        id: '',
        type: NotificationType.applicationStatus,
        title: title,
        body: body,
        createdAt: DateTime.now(),
        relatedId: application.id,
        applicationId: application.id,
        jobId: application.jobId,
        jobTitle: application.jobTitle,
      ),
      application.candidateId,
    );
  }

  Future<void> notifyNewMessage({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String conversationId,
    required String messagePreview,
    String? jobTitle,
    String? applicationId,
  }) async {
    final preview = messagePreview.length > 80
        ? '${messagePreview.substring(0, 80)}…'
        : messagePreview;
    await create(
      AppNotificationModel(
        id: '',
        type: NotificationType.newMessage,
        title: 'Message from $senderName',
        body: preview,
        createdAt: DateTime.now(),
        relatedId: conversationId,
        conversationId: conversationId,
        otherUserId: senderId,
        otherUserName: senderName,
        applicationId: applicationId,
        jobTitle: jobTitle,
      ),
      recipientId,
    );
  }

  (String, String) _statusCopy(
      ApplicationModel app, ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.shortlisted:
        return (
          'Shortlisted!',
          'You were shortlisted for ${app.jobTitle} at ${app.company}.',
        );
      case ApplicationStatus.accepted:
        return (
          'Application accepted',
          '${app.company} accepted your application for ${app.jobTitle}.',
        );
      case ApplicationStatus.rejected:
        return (
          'Application update',
          'Your application for ${app.jobTitle} at ${app.company} was not selected.',
        );
      default:
        return (
          'Application update',
          'Your ${app.jobTitle} application at ${app.company} was updated.',
        );
    }
  }
}
