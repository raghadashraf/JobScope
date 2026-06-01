import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/direct_message_model.dart';
import '../../auth/data/auth_providers.dart';

final _db = FirebaseFirestore.instance;

// Deterministic conversation ID — always sorted so it's the same from both sides
String buildConvId(String uid1, String uid2) {
  final ids = [uid1, uid2]..sort();
  return ids.join('_');
}

// Params passed to ChatScreen via GoRouter extra
class ChatParams {
  final String convId;
  final String otherUid;
  final String otherName;
  final String? jobTitle;
  final String? applicationId;

  const ChatParams({
    required this.convId,
    required this.otherUid,
    required this.otherName,
    this.jobTitle,
    this.applicationId,
  });
}

// Stream all conversations for the current user
final conversationsProvider =
    StreamProvider<List<ConversationModel>>((ref) {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return Stream.value([]);
  return _db
      .collection('conversations')
      .where('participantIds', arrayContains: user.uid)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ConversationModel.fromDoc).toList());
});

// Stream messages inside a conversation
final messagesProvider = StreamProvider.autoDispose
    .family<List<DirectMessageModel>, String>((ref, convId) {
  return _db
      .collection('conversations')
      .doc(convId)
      .collection('messages')
      .orderBy('sentAt')
      .snapshots()
      .map((s) => s.docs.map(DirectMessageModel.fromDoc).toList());
});

// Total unread badge count for current user
final totalUnreadProvider = Provider<int>((ref) {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return 0;
  final convs = ref.watch(conversationsProvider).value ?? [];
  return convs.fold(0, (total, c) => total + c.unreadFor(user.uid));
});

class MessagingNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendMessage({
    required String convId,
    required String senderId,
    required String senderName,
    required String recipientId,
    required String text,
    Map<String, String>? participantNames,
    String? jobTitle,
    String? applicationId,
  }) async {
    final convRef = _db.collection('conversations').doc(convId);
    final msgRef = convRef.collection('messages').doc();

    final msg = DirectMessageModel(
      id: msgRef.id,
      senderId: senderId,
      senderName: senderName,
      text: text,
      sentAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(msgRef, msg.toMap());
    batch.set(
      convRef,
      {
        'id': convId,
        'participantIds': ([senderId, recipientId]..sort()),
        'participantNames': participantNames,
        'lastMessage':
            text.length > 60 ? '${text.substring(0, 60)}…' : text,
        'lastMessageAt': Timestamp.fromDate(msg.sentAt),
        'jobTitle': jobTitle,
        'applicationId': applicationId,
        'unreadCount': {recipientId: FieldValue.increment(1)},
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> markRead(String convId, String myUid) async {
    await _db.collection('conversations').doc(convId).set(
      {'unreadCount': {myUid: 0}},
      SetOptions(merge: true),
    );
    // Mark all messages sent by others as read
    final unread = await _db
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .where('readAt', isNull: true)
        .where('senderId', isNotEqualTo: myUid)
        .get();
    if (unread.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'readAt': Timestamp.now()});
    }
    await batch.commit();
  }
}

final messagingNotifierProvider =
    AsyncNotifierProvider<MessagingNotifier, void>(MessagingNotifier.new);
