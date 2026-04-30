import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { candidate, recruiter }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? photoUrl;
  final String? phone;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.photoUrl,
    this.phone,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'name': name,
        'role': role.name,
        'photoUrl': photoUrl,
        'phone': phone,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] ?? '',
        email: map['email'] ?? '',
        name: map['name'] ?? '',
        role: UserRole.values.firstWhere(
          (e) => e.name == map['role'],
          orElse: () => UserRole.candidate,
        ),
        photoUrl: map['photoUrl'],
        phone: map['phone'],
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}