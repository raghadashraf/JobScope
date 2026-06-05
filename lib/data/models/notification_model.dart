import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  applicationStatus,
  newApplication,
  newMessage,
  newJob,
}

class AppNotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  /// Primary related document id (application, job, or conversation).
  final String? relatedId;
  final String? applicationId;
  final String? jobId;
  final String? conversationId;
  final String? otherUserId;
  final String? otherUserName;
  final String? jobTitle;

  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.read = false,
    required this.createdAt,
    this.relatedId,
    this.applicationId,
    this.jobId,
    this.conversationId,
    this.otherUserId,
    this.otherUserName,
    this.jobTitle,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'read': read,
        'createdAt': Timestamp.fromDate(createdAt),
        if (relatedId != null) 'relatedId': relatedId,
        if (applicationId != null) 'applicationId': applicationId,
        if (jobId != null) 'jobId': jobId,
        if (conversationId != null) 'conversationId': conversationId,
        if (otherUserId != null) 'otherUserId': otherUserId,
        if (otherUserName != null) 'otherUserName': otherUserName,
        if (jobTitle != null) 'jobTitle': jobTitle,
      };

  factory AppNotificationModel.fromMap(Map<String, dynamic> map,
          {String? docId}) =>
      AppNotificationModel(
        id: docId ?? map['id'] ?? '',
        type: _parseType(map['type']),
        title: map['title'] ?? '',
        body: map['body'] ?? '',
        read: map['read'] ?? false,
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        relatedId: map['relatedId'] as String?,
        applicationId: map['applicationId'] as String?,
        jobId: map['jobId'] as String?,
        conversationId: map['conversationId'] as String?,
        otherUserId: map['otherUserId'] as String?,
        otherUserName: map['otherUserName'] as String?,
        jobTitle: map['jobTitle'] as String?,
      );

  factory AppNotificationModel.fromDoc(DocumentSnapshot doc) =>
      AppNotificationModel.fromMap(
        doc.data() as Map<String, dynamic>,
        docId: doc.id,
      );

  static NotificationType _parseType(dynamic raw) {
    final name = raw?.toString() ?? '';
    return NotificationType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => NotificationType.applicationStatus,
    );
  }

  String get applicationIdResolved =>
      applicationId ?? relatedId ?? '';

  String get jobIdResolved => jobId ?? relatedId ?? '';

  String get conversationIdResolved =>
      conversationId ?? relatedId ?? '';
}
