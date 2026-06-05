import 'package:cloud_firestore/cloud_firestore.dart';

const _sentinel = Object();

enum ApplicationStatus {
  pending,
  shortlisted,
  rejected,
  accepted,
  withdrawn,
}

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
  final DateTime? updatedAt;
  final int? matchScore;
  final String? notes;

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
    this.updatedAt,
    this.matchScore,
    this.notes,
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
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'matchScore': matchScore,
        'notes': notes,
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
        status: _parseStatus(map['status']),
        appliedAt:
            (map['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
        matchScore: map['matchScore'],
        notes: map['notes'],
      );

  factory ApplicationModel.fromDoc(DocumentSnapshot doc) =>
      ApplicationModel.fromMap(
        doc.data() as Map<String, dynamic>,
        docId: doc.id,
      );

  ApplicationModel copyWith({
    String? id,
    String? jobId,
    String? jobTitle,
    String? company,
    String? candidateId,
    String? candidateName,
    String? candidateEmail,
    Object? candidatePhotoUrl = _sentinel,
    Object? cvUrl = _sentinel,
    ApplicationStatus? status,
    DateTime? appliedAt,
    Object? updatedAt = _sentinel,
    Object? matchScore = _sentinel,
    Object? notes = _sentinel,
  }) =>
      ApplicationModel(
        id: id ?? this.id,
        jobId: jobId ?? this.jobId,
        jobTitle: jobTitle ?? this.jobTitle,
        company: company ?? this.company,
        candidateId: candidateId ?? this.candidateId,
        candidateName: candidateName ?? this.candidateName,
        candidateEmail: candidateEmail ?? this.candidateEmail,
        candidatePhotoUrl: candidatePhotoUrl == _sentinel
            ? this.candidatePhotoUrl
            : candidatePhotoUrl as String?,
        cvUrl: cvUrl == _sentinel ? this.cvUrl : cvUrl as String?,
        status: status ?? this.status,
        appliedAt: appliedAt ?? this.appliedAt,
        updatedAt:
            updatedAt == _sentinel ? this.updatedAt : updatedAt as DateTime?,
        matchScore:
            matchScore == _sentinel ? this.matchScore : matchScore as int?,
        notes: notes == _sentinel ? this.notes : notes as String?,
      );

  String get statusDisplayName {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Under Review';
      case ApplicationStatus.shortlisted:
        return 'Shortlisted';
      case ApplicationStatus.rejected:
        return 'Not Selected';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  bool get isActive =>
      status != ApplicationStatus.withdrawn;

  /// UI label "Under Review" — Firestore value is still `pending`.
  bool get canWithdraw => status == ApplicationStatus.pending;

  static ApplicationStatus _parseStatus(dynamic raw) {
    final s = (raw?.toString() ?? '').toLowerCase().replaceAll(' ', '_');
    switch (s) {
      case 'pending':
      case 'under_review':
      case 'underreview':
        return ApplicationStatus.pending;
      case 'shortlisted':
        return ApplicationStatus.shortlisted;
      case 'rejected':
      case 'not_selected':
        return ApplicationStatus.rejected;
      case 'accepted':
        return ApplicationStatus.accepted;
      case 'withdrawn':
        return ApplicationStatus.withdrawn;
      default:
        return ApplicationStatus.pending;
    }
  }
}
