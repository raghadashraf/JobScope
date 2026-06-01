import 'package:cloud_firestore/cloud_firestore.dart';

enum InterviewStatus { proposed, confirmed, cancelled }

class InterviewModel {
  final String id;
  final String applicationId;
  final String jobId;
  final String jobTitle;
  final String company;
  final String recruiterId;
  final String recruiterName;
  final String candidateId;
  final String candidateName;
  final String candidateEmail;
  final List<DateTime> slots;
  final int? confirmedSlotIndex;
  final InterviewStatus status;
  final DateTime createdAt;

  const InterviewModel({
    required this.id,
    required this.applicationId,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.recruiterId,
    required this.recruiterName,
    required this.candidateId,
    required this.candidateName,
    required this.candidateEmail,
    required this.slots,
    this.confirmedSlotIndex,
    required this.status,
    required this.createdAt,
  });

  DateTime? get confirmedSlot =>
      confirmedSlotIndex != null && confirmedSlotIndex! < slots.length
          ? slots[confirmedSlotIndex!]
          : null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'applicationId': applicationId,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'company': company,
        'recruiterId': recruiterId,
        'recruiterName': recruiterName,
        'candidateId': candidateId,
        'candidateName': candidateName,
        'candidateEmail': candidateEmail,
        'slots': slots.map((d) => Timestamp.fromDate(d)).toList(),
        'confirmedSlotIndex': confirmedSlotIndex,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory InterviewModel.fromMap(Map<String, dynamic> map,
          {String? docId}) =>
      InterviewModel(
        id: docId ?? map['id'] ?? '',
        applicationId: map['applicationId'] ?? '',
        jobId: map['jobId'] ?? '',
        jobTitle: map['jobTitle'] ?? '',
        company: map['company'] ?? '',
        recruiterId: map['recruiterId'] ?? '',
        recruiterName: map['recruiterName'] ?? '',
        candidateId: map['candidateId'] ?? '',
        candidateName: map['candidateName'] ?? '',
        candidateEmail: map['candidateEmail'] ?? '',
        slots: ((map['slots'] as List?) ?? [])
            .map((t) => (t as Timestamp).toDate())
            .toList(),
        confirmedSlotIndex: map['confirmedSlotIndex'] as int?,
        status: InterviewStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => InterviewStatus.proposed,
        ),
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  factory InterviewModel.fromDoc(DocumentSnapshot doc) =>
      InterviewModel.fromMap(doc.data() as Map<String, dynamic>,
          docId: doc.id);

  InterviewModel copyWith({
    String? id,
    int? confirmedSlotIndex,
    InterviewStatus? status,
  }) =>
      InterviewModel(
        id: id ?? this.id,
        applicationId: applicationId,
        jobId: jobId,
        jobTitle: jobTitle,
        company: company,
        recruiterId: recruiterId,
        recruiterName: recruiterName,
        candidateId: candidateId,
        candidateName: candidateName,
        candidateEmail: candidateEmail,
        slots: slots,
        confirmedSlotIndex: confirmedSlotIndex ?? this.confirmedSlotIndex,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
