import 'package:cloud_firestore/cloud_firestore.dart';

class DirectMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;
  final DateTime? readAt;

  const DirectMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'sentAt': Timestamp.fromDate(sentAt),
        'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      };

  factory DirectMessageModel.fromMap(Map<String, dynamic> map,
          {String? docId}) =>
      DirectMessageModel(
        id: docId ?? map['id'] ?? '',
        senderId: map['senderId'] ?? '',
        senderName: map['senderName'] ?? '',
        text: map['text'] ?? '',
        sentAt:
            (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        readAt: (map['readAt'] as Timestamp?)?.toDate(),
      );

  factory DirectMessageModel.fromDoc(DocumentSnapshot doc) =>
      DirectMessageModel.fromMap(
        doc.data() as Map<String, dynamic>,
        docId: doc.id,
      );
}
