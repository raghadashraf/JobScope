import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String recruiterId;
  final String recruiterName;
  final String recruiterPhotoUrl;
  final String title;
  final String company;
  final String location;
  final String jobType; // full-time, part-time, remote, contract
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
