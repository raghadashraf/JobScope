import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/cv_profile_strength.dart';

class CvModel {
  /// Firestore doc id in `users/{uid}/cvs/{id}`.
  final String id;
  final String uid;
  final String fileUrl;
  final String fileName;
  final String storagePath;
  final DateTime uploadedAt;
  final List<String> skills;
  final List<WorkExperience> workExperience;
  final List<Education> education;
  /// Canonical ids: junior | mid | senior | lead
  final String? experienceLevel;
  /// Canonical labels: High School, Bachelor's, Master's, PhD, …
  final String? educationLevel;
  final int profileStrength; // 0–100

  CvModel({
    this.id = '',
    required this.uid,
    required this.fileUrl,
    required this.fileName,
    this.storagePath = '',
    required this.uploadedAt,
    required this.skills,
    required this.workExperience,
    required this.education,
    this.experienceLevel,
    this.educationLevel,
    required this.profileStrength,
  });

  bool get hasFile => fileUrl.isNotEmpty;

  /// Live score from current fields (fixes stale stored values in UI).
  int get effectiveProfileStrength => CvProfileStrength.fromCv(this);

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'storagePath': storagePath,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'skills': skills,
        'workExperience': workExperience.map((e) => e.toMap()).toList(),
        'education': education.map((e) => e.toMap()).toList(),
        'experienceLevel': experienceLevel,
        'educationLevel': educationLevel,
        'profileStrength': profileStrength,
      };

  factory CvModel.fromMap(Map<String, dynamic> map, {String? docId}) =>
      CvModel(
        id: docId ?? map['id'] ?? '',
        uid: map['uid'] ?? '',
        fileUrl: map['fileUrl'] ?? '',
        fileName: map['fileName'] ?? '',
        storagePath: map['storagePath'] ?? '',
        uploadedAt:
            (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        skills: List<String>.from(map['skills'] ?? []),
        workExperience: (map['workExperience'] as List<dynamic>? ?? [])
            .map((e) => WorkExperience.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        education: (map['education'] as List<dynamic>? ?? [])
            .map((e) => Education.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        experienceLevel: map['experienceLevel'],
        educationLevel: map['educationLevel'],
        profileStrength: map['profileStrength'] ?? 0,
      );

  CvModel copyWith({
    String? id,
    String? fileUrl,
    String? fileName,
    String? storagePath,
    DateTime? uploadedAt,
    List<String>? skills,
    List<WorkExperience>? workExperience,
    List<Education>? education,
    String? experienceLevel,
    String? educationLevel,
    int? profileStrength,
  }) =>
      CvModel(
        id: id ?? this.id,
        uid: uid,
        fileUrl: fileUrl ?? this.fileUrl,
        fileName: fileName ?? this.fileName,
        storagePath: storagePath ?? this.storagePath,
        uploadedAt: uploadedAt ?? this.uploadedAt,
        skills: skills ?? this.skills,
        workExperience: workExperience ?? this.workExperience,
        education: education ?? this.education,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        educationLevel: educationLevel ?? this.educationLevel,
        profileStrength: profileStrength ?? this.profileStrength,
      );
}

class WorkExperience {
  final String company;
  final String title;
  final String duration;
  final String description;

  WorkExperience({
    required this.company,
    required this.title,
    required this.duration,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
        'company': company,
        'title': title,
        'duration': duration,
        'description': description,
      };

  factory WorkExperience.fromMap(Map<String, dynamic> map) => WorkExperience(
        company: map['company'] ?? '',
        title: map['title'] ?? '',
        duration: map['duration'] ?? '',
        description: map['description'] ?? '',
      );
}

class Education {
  final String institution;
  final String degree;
  final String field;
  final String year;

  Education({
    required this.institution,
    required this.degree,
    required this.field,
    required this.year,
  });

  Map<String, dynamic> toMap() => {
        'institution': institution,
        'degree': degree,
        'field': field,
        'year': year,
      };

  factory Education.fromMap(Map<String, dynamic> map) => Education(
        institution: map['institution'] ?? '',
        degree: map['degree'] ?? '',
        field: map['field'] ?? '',
        year: map['year'] ?? '',
      );
}
