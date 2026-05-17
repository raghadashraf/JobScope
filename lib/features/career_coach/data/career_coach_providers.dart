import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/cv_model.dart';
import '../../applications/data/application_providers.dart';
import '../../auth/data/auth_providers.dart';
import '../../cv_management/data/cv_providers.dart';
import '../../ai_features/data/ai_providers.dart';

// ─── Firestore chat stream ─────────────────────────────────────────────────────
final coachChatStreamProvider = StreamProvider<List<ChatMessage>>((ref) {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('coach_chat')
      .orderBy('createdAt')
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => ChatMessage.fromMap(d.id, d.data()))
          .toList());
});

// ─── Send message notifier ─────────────────────────────────────────────────────
class CoachChatNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> send(String userMessage) async {
    final firebaseUser = ref.read(firebaseUserProvider).value;
    if (firebaseUser == null || userMessage.trim().isEmpty) return;

    state = true;

    final uid = firebaseUser.uid;
    final chatCol = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('coach_chat');

    await chatCol.add(ChatMessage(
      id: '',
      content: userMessage.trim(),
      role: MessageRole.user,
      createdAt: DateTime.now(),
    ).toMap());

    try {
      final cv = ref.read(cvStreamProvider).value;
      final apps = ref.read(myApplicationsProvider).value ?? [];
      final systemContext = _buildSystemContext(cv, apps);

      final historySnap = await chatCol
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      final history = historySnap.docs.reversed
          .map((d) => {
                'role': d.data()['role'] as String,
                'content': d.data()['content'] as String,
              })
          .toList();

      final reply = await ref
          .read(aiServiceProvider)
          .chatWithCoach(
            history: history,
            userMessage: userMessage.trim(),
            systemContext: systemContext,
          );

      await chatCol.add(ChatMessage(
        id: '',
        content: reply.trim(),
        role: MessageRole.assistant,
        createdAt: DateTime.now(),
      ).toMap());
    } catch (_) {
      await chatCol.add(ChatMessage(
        id: '',
        content: 'Sorry, I ran into an issue. Please try again.',
        role: MessageRole.assistant,
        createdAt: DateTime.now(),
      ).toMap());
    } finally {
      state = false;
    }
  }

  Future<void> clearHistory() async {
    final firebaseUser = ref.read(firebaseUserProvider).value;
    if (firebaseUser == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .collection('coach_chat')
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  String _buildSystemContext(CvModel? cv, List<ApplicationModel> apps) {
    final buffer = StringBuffer();
    buffer.writeln(
        'You are an expert AI career coach for a job-seeking platform called JobScope.');
    buffer.writeln(
        'Be concise, encouraging, and highly specific to the candidate\'s data.');
    buffer.writeln(
        'Give actionable advice. Use bullet points where helpful. Keep answers under 200 words unless asked for detail.');
    buffer.writeln();

    if (cv != null) {
      buffer.writeln('=== CANDIDATE CV PROFILE ===');
      if (cv.skills.isNotEmpty) {
        buffer.writeln('Skills: ${cv.skills.join(', ')}');
      }
      if (cv.workExperience.isNotEmpty) {
        buffer.writeln('Work Experience:');
        for (final w in cv.workExperience) {
          buffer.writeln('  - ${w.title} at ${w.company} (${w.duration})');
        }
      }
      if (cv.education.isNotEmpty) {
        buffer.writeln('Education:');
        for (final e in cv.education) {
          buffer.writeln(
              '  - ${e.degree} in ${e.field} from ${e.institution} (${e.year})');
        }
      }
      buffer.writeln('Profile Strength: ${cv.profileStrength}%');
    } else {
      buffer.writeln('The candidate has not uploaded a CV yet.');
    }

    buffer.writeln();
    if (apps.isNotEmpty) {
      buffer.writeln('=== JOB APPLICATION HISTORY ===');
      for (final a in apps.take(10)) {
        buffer.writeln(
            '  - ${a.jobTitle} at ${a.company} — Status: ${a.status.name}');
      }
    } else {
      buffer.writeln('The candidate has not applied to any jobs yet.');
    }

    return buffer.toString();
  }
}

final coachChatNotifierProvider =
    NotifierProvider<CoachChatNotifier, bool>(CoachChatNotifier.new);
