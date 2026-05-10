import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus { pending, shortlisted, rejected, accepted }

class ApplicationModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String company;
  final String candidateId;
  final String candidateName;
  final String candidateEmail;
  final String? candidatePhotoUrl;
  final String? cvUrl;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final int? matchScore; // 0–100, set by AI matching

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.candidateId,
    required this.candidateName,
    required this.candidateEmail,
    this.candidatePhotoUrl,
    this.cvUrl,
    required this.status,
    required this.appliedAt,
    this.matchScore,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'company': company,
        'candidateId': candidateId,
        'candidateName': candidateName,
        'candidateEmail': candidateEmail,
        'candidatePhotoUrl': candidatePhotoUrl,
        'cvUrl': cvUrl,
        'status': status.name,
        'appliedAt': Timestamp.fromDate(appliedAt),
        'matchScore': matchScore,
      };

  factory ApplicationModel.fromMap(Map<String, dynamic> map,
          {String? docId}) =>
      ApplicationModel(
        id: docId ?? map['id'] ?? '',
        jobId: map['jobId'] ?? '',
        jobTitle: map['jobTitle'] ?? '',
        company: map['company'] ?? '',
        candidateId: map['candidateId'] ?? '',
        candidateName: map['candidateName'] ?? '',
        candidateEmail: map['candidateEmail'] ?? '',
        candidatePhotoUrl: map['candidatePhotoUrl'],
        cvUrl: map['cvUrl'],
        status: ApplicationStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => ApplicationStatus.pending,
        ),
        appliedAt:
            (map['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        matchScore: map['matchScore'],
      );

  factory ApplicationModel.fromDoc(DocumentSnapshot doc) =>
      ApplicationModel.fromMap(doc.data() as Map<String, dynamic>,
          docId: doc.id);

  String get statusLabel {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Under Review';
      case ApplicationStatus.shortlisted:
        return 'Shortlisted';
      case ApplicationStatus.rejected:
        return 'Not Selected';
      case ApplicationStatus.accepted:
        return 'Accepted';
    }
  }
}
