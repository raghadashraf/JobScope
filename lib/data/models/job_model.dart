import 'package:cloud_firestore/cloud_firestore.dart';

const _sentinel = Object();

class JobModel {
  final String id;
  final String recruiterId;
  final String recruiterName;
  final String recruiterPhotoUrl;
  final String title;
  final String company;
  final String location;
  final String jobType; // full-time, part-time, remote, contract
  final String? experienceLevel; // junior, mid, senior, lead
  final String description;
  final List<String> requirements;
  final List<String> skills;
  final double? salaryMin;
  final double? salaryMax;
  final String? salaryCurrency;
  final DateTime postedAt;
  final bool isActive;

  JobModel({
    required this.id,
    required this.recruiterId,
    required this.recruiterName,
    this.recruiterPhotoUrl = '',
    required this.title,
    required this.company,
    required this.location,
    required this.jobType,
    this.experienceLevel,
    required this.description,
    required this.requirements,
    required this.skills,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency = 'USD',
    required this.postedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'recruiterId': recruiterId,
        'recruiterName': recruiterName,
        'recruiterPhotoUrl': recruiterPhotoUrl,
        'title': title,
        'company': company,
        'location': location,
        'jobType': jobType,
        'experienceLevel': experienceLevel,
        'description': description,
        'requirements': requirements,
        'skills': skills,
        'salaryMin': salaryMin,
        'salaryMax': salaryMax,
        'salaryCurrency': salaryCurrency,
        'postedAt': Timestamp.fromDate(postedAt),
        'isActive': isActive,
      };

  factory JobModel.fromMap(Map<String, dynamic> map, {String? docId}) =>
      JobModel(
        id: docId ?? map['id'] ?? '',
        recruiterId: map['recruiterId'] ?? '',
        recruiterName: map['recruiterName'] ?? '',
        recruiterPhotoUrl: map['recruiterPhotoUrl'] ?? '',
        title: map['title'] ?? '',
        company: map['company'] ?? '',
        location: map['location'] ?? '',
        jobType: map['jobType'] ?? 'full-time',
        experienceLevel: map['experienceLevel'],
        description: map['description'] ?? '',
        requirements: List<String>.from(map['requirements'] ?? []),
        skills: List<String>.from(map['skills'] ?? []),
        salaryMin: (map['salaryMin'] as num?)?.toDouble(),
        salaryMax: (map['salaryMax'] as num?)?.toDouble(),
        salaryCurrency: map['salaryCurrency'] ?? 'USD',
        postedAt:
            (map['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isActive: map['isActive'] ?? true,
      );

  factory JobModel.fromDoc(DocumentSnapshot doc) =>
      JobModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);

  JobModel copyWith({
    String? id,
    String? recruiterId,
    String? recruiterName,
    String? recruiterPhotoUrl,
    String? title,
    String? company,
    String? location,
    String? jobType,
    Object? experienceLevel = _sentinel,
    String? description,
    List<String>? requirements,
    List<String>? skills,
    Object? salaryMin = _sentinel,
    Object? salaryMax = _sentinel,
    Object? salaryCurrency = _sentinel,
    DateTime? postedAt,
    bool? isActive,
  }) =>
      JobModel(
        id: id ?? this.id,
        recruiterId: recruiterId ?? this.recruiterId,
        recruiterName: recruiterName ?? this.recruiterName,
        recruiterPhotoUrl: recruiterPhotoUrl ?? this.recruiterPhotoUrl,
        title: title ?? this.title,
        company: company ?? this.company,
        location: location ?? this.location,
        jobType: jobType ?? this.jobType,
        experienceLevel: experienceLevel == _sentinel
            ? this.experienceLevel
            : experienceLevel as String?,
        description: description ?? this.description,
        requirements: requirements ?? this.requirements,
        skills: skills ?? this.skills,
        salaryMin:
            salaryMin == _sentinel ? this.salaryMin : salaryMin as double?,
        salaryMax:
            salaryMax == _sentinel ? this.salaryMax : salaryMax as double?,
        salaryCurrency: salaryCurrency == _sentinel
            ? this.salaryCurrency
            : salaryCurrency as String?,
        postedAt: postedAt ?? this.postedAt,
        isActive: isActive ?? this.isActive,
      );

  String get salaryRange {
    if (salaryMin == null && salaryMax == null) return 'Not specified';
    final currency = salaryCurrency ?? 'USD';
    if (salaryMin != null && salaryMax != null) {
      return '$currency ${_formatNumber(salaryMin!)} – ${_formatNumber(salaryMax!)}';
    }
    if (salaryMin != null) return '$currency ${_formatNumber(salaryMin!)}+';
    return '$currency up to ${_formatNumber(salaryMax!)}';
  }

  String _formatNumber(double n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return n.toStringAsFixed(0);
  }

  String get postedAgo {
    final diff = DateTime.now().difference(postedAt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return '1 day ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }
}
