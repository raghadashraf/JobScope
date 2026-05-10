import 'package:cloud_firestore/cloud_firestore.dart';

class CvModel {
  final String uid;
  final String fileUrl;
  final String fileName;
  final DateTime uploadedAt;
  final List<String> skills;
  final List<WorkExperience> workExperience;
  final List<Education> education;
  final int profileStrength; // 0–100

  CvModel({
    required this.uid,
    required this.fileUrl,
    required this.fileName,
    required this.uploadedAt,
    required this.skills,
    required this.workExperience,
    required this.education,
    required this.profileStrength,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'skills': skills,
        'workExperience': workExperience.map((e) => e.toMap()).toList(),
        'education': education.map((e) => e.toMap()).toList(),
        'profileStrength': profileStrength,
      };

  factory CvModel.fromMap(Map<String, dynamic> map) => CvModel(
        uid: map['uid'] ?? '',
        fileUrl: map['fileUrl'] ?? '',
        fileName: map['fileName'] ?? '',
        uploadedAt:
            (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        skills: List<String>.from(map['skills'] ?? []),
        workExperience: (map['workExperience'] as List<dynamic>? ?? [])
            .map((e) => WorkExperience.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        education: (map['education'] as List<dynamic>? ?? [])
            .map((e) => Education.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        profileStrength: map['profileStrength'] ?? 0,
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
