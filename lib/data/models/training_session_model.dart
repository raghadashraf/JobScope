import 'package:cloud_firestore/cloud_firestore.dart';

class TrainQuestion {
  final String question;
  final String scenario;

  const TrainQuestion({required this.question, required this.scenario});

  Map<String, dynamic> toMap() => {
        'question': question,
        'scenario': scenario,
      };

  factory TrainQuestion.fromMap(Map<String, dynamic> map) => TrainQuestion(
        question: map['question'] as String? ?? '',
        scenario: map['scenario'] as String? ?? '',
      );
}

class TrainAnswerRecord {
  final String answer;
  final String feedback;
  final int score;

  const TrainAnswerRecord({
    required this.answer,
    required this.feedback,
    required this.score,
  });

  Map<String, dynamic> toMap() => {
        'answer': answer,
        'feedback': feedback,
        'score': score,
      };

  factory TrainAnswerRecord.fromMap(Map<String, dynamic> map) =>
      TrainAnswerRecord(
        answer: map['answer'] as String? ?? '',
        feedback: map['feedback'] as String? ?? '',
        score: (map['score'] as num?)?.toInt() ?? 0,
      );
}

class TrainingSessionModel {
  final String id;
  final String uid;
  final String jobId;
  final String jobTitle;
  final String company;
  final List<TrainQuestion> questions;
  final List<TrainAnswerRecord> answers;
  final int? readinessScore;
  final bool isComplete;
  final DateTime createdAt;

  const TrainingSessionModel({
    required this.id,
    required this.uid,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.questions,
    required this.answers,
    this.readinessScore,
    required this.isComplete,
    required this.createdAt,
  });

  static const int minReadinessToApply = 60;

  bool get canApply => !isComplete || (readinessScore ?? 0) >= minReadinessToApply;

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'company': company,
        'questions': questions.map((q) => q.toMap()).toList(),
        'answers': answers.map((a) => a.toMap()).toList(),
        'readinessScore': readinessScore,
        'isComplete': isComplete,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory TrainingSessionModel.fromMap(Map<String, dynamic> map,
          {String? docId}) =>
      TrainingSessionModel(
        id: docId ?? map['id'] ?? '',
        uid: map['uid'] ?? '',
        jobId: map['jobId'] ?? '',
        jobTitle: map['jobTitle'] ?? '',
        company: map['company'] ?? '',
        questions: (map['questions'] as List<dynamic>? ?? [])
            .map((e) =>
                TrainQuestion.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        answers: (map['answers'] as List<dynamic>? ?? [])
            .map((e) =>
                TrainAnswerRecord.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        readinessScore: (map['readinessScore'] as num?)?.toInt(),
        isComplete: map['isComplete'] as bool? ?? false,
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  factory TrainingSessionModel.fromDoc(DocumentSnapshot doc) =>
      TrainingSessionModel.fromMap(
        doc.data() as Map<String, dynamic>,
        docId: doc.id,
      );

  TrainingSessionModel copyWith({
    List<TrainAnswerRecord>? answers,
    int? readinessScore,
    bool? isComplete,
  }) =>
      TrainingSessionModel(
        id: id,
        uid: uid,
        jobId: jobId,
        jobTitle: jobTitle,
        company: company,
        questions: questions,
        answers: answers ?? this.answers,
        readinessScore: readinessScore ?? this.readinessScore,
        isComplete: isComplete ?? this.isComplete,
        createdAt: createdAt,
      );
}
