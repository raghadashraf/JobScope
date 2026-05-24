import 'package:cloud_firestore/cloud_firestore.dart';

class JobCollectionModel {
  final String id;
  final String name;
  final List<String> jobIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const JobCollectionModel({
    required this.id,
    required this.name,
    required this.jobIds,
    required this.createdAt,
    this.updatedAt,
  });

  int get jobCount => jobIds.length;

  Map<String, dynamic> toMap() => {
        'name': name,
        'jobIds': jobIds,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt':
            updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  factory JobCollectionModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobCollectionModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed',
      jobIds: List<String>.from(data['jobIds'] ?? []),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  JobCollectionModel copyWith({String? name, List<String>? jobIds}) =>
      JobCollectionModel(
        id: id,
        name: name ?? this.name,
        jobIds: jobIds ?? this.jobIds,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
