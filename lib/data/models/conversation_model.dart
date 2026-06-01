import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String? jobTitle;
  final String? applicationId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCount;

  const ConversationModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    this.jobTitle,
    this.applicationId,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });

  String nameFor(String myUid) {
    final otherId = participantIds.firstWhere(
      (id) => id != myUid,
      orElse: () => '',
    );
    return participantNames[otherId] ?? 'Unknown';
  }

  String otherUid(String myUid) => participantIds.firstWhere(
        (id) => id != myUid,
        orElse: () => '',
      );

  int unreadFor(String myUid) => unreadCount[myUid] ?? 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'participantIds': participantIds,
        'participantNames': participantNames,
        'jobTitle': jobTitle,
        'applicationId': applicationId,
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt != null
            ? Timestamp.fromDate(lastMessageAt!)
            : null,
        'unreadCount': unreadCount,
      };

  factory ConversationModel.fromMap(Map<String, dynamic> map,
          {String? docId}) =>
      ConversationModel(
        id: docId ?? map['id'] ?? '',
        participantIds:
            List<String>.from(map['participantIds'] ?? []),
        participantNames:
            Map<String, String>.from(map['participantNames'] ?? {}),
        jobTitle: map['jobTitle'],
        applicationId: map['applicationId'],
        lastMessage: map['lastMessage'],
        lastMessageAt:
            (map['lastMessageAt'] as Timestamp?)?.toDate(),
        unreadCount:
            Map<String, int>.from(map['unreadCount'] ?? {}),
      );

  factory ConversationModel.fromDoc(DocumentSnapshot doc) =>
      ConversationModel.fromMap(
        doc.data() as Map<String, dynamic>,
        docId: doc.id,
      );
}
