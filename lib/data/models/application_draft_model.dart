import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationDraftModel {
  final String jobId;
  final String? cvId;
  final String? cvUrl;
  final String? cvFileName;
  final String? coverLetterText;
  final String? coverLetterFileUrl;
  final String? coverLetterFileName;
  /// `manual`, `ai`, or `upload`
  final String? coverLetterSource;
  final DateTime? updatedAt;

  const ApplicationDraftModel({
    required this.jobId,
    this.cvId,
    this.cvUrl,
    this.cvFileName,
    this.coverLetterText,
    this.coverLetterFileUrl,
    this.coverLetterFileName,
    this.coverLetterSource,
    this.updatedAt,
  });

  bool get hasCv => cvUrl != null && cvUrl!.isNotEmpty;

  bool get hasCoverLetter =>
      (coverLetterText != null && coverLetterText!.trim().isNotEmpty) ||
      (coverLetterFileUrl != null && coverLetterFileUrl!.isNotEmpty);

  Map<String, dynamic> toMap() => {
        'jobId': jobId,
        'cvId': cvId,
        'cvUrl': cvUrl,
        'cvFileName': cvFileName,
        'coverLetterText': coverLetterText,
        'coverLetterFileUrl': coverLetterFileUrl,
        'coverLetterFileName': coverLetterFileName,
        'coverLetterSource': coverLetterSource,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory ApplicationDraftModel.fromMap(Map<String, dynamic> map) =>
      ApplicationDraftModel(
        jobId: map['jobId'] ?? '',
        cvId: map['cvId'],
        cvUrl: map['cvUrl'],
        cvFileName: map['cvFileName'],
        coverLetterText: map['coverLetterText'],
        coverLetterFileUrl: map['coverLetterFileUrl'],
        coverLetterFileName: map['coverLetterFileName'],
        coverLetterSource: map['coverLetterSource'],
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );

  ApplicationDraftModel copyWith({
    String? cvId,
    String? cvUrl,
    String? cvFileName,
    String? coverLetterText,
    String? coverLetterFileUrl,
    String? coverLetterFileName,
    String? coverLetterSource,
  }) =>
      ApplicationDraftModel(
        jobId: jobId,
        cvId: cvId ?? this.cvId,
        cvUrl: cvUrl ?? this.cvUrl,
        cvFileName: cvFileName ?? this.cvFileName,
        coverLetterText: coverLetterText ?? this.coverLetterText,
        coverLetterFileUrl: coverLetterFileUrl ?? this.coverLetterFileUrl,
        coverLetterFileName:
            coverLetterFileName ?? this.coverLetterFileName,
        coverLetterSource: coverLetterSource ?? this.coverLetterSource,
        updatedAt: updatedAt,
      );
}
