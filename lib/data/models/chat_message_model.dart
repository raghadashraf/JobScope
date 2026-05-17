import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
  });

  bool get isUser => role == MessageRole.user;

  Map<String, dynamic> toMap() => {
        'content': content,
        'role': role.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) =>
      ChatMessage(
        id: id,
        content: map['content'] as String? ?? '',
        role: MessageRole.values.firstWhere(
          (r) => r.name == map['role'],
          orElse: () => MessageRole.user,
        ),
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  ChatMessage copyWith({String? content}) => ChatMessage(
        id: id,
        content: content ?? this.content,
        role: role,
        createdAt: createdAt,
      );
}
