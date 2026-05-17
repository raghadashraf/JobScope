import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { candidate, recruiter }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? photoUrl;
  final String? phone;
  final String? bio;
  final String? headline;
  final String? location;
  final String? linkedinUrl;
  final String? website;
  final String? company;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.photoUrl,
    this.phone,
    this.bio,
    this.headline,
    this.location,
    this.linkedinUrl,
    this.website,
    this.company,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'name': name,
        'role': role.name,
        'photoUrl': photoUrl,
        'phone': phone,
        'bio': bio,
        'headline': headline,
        'location': location,
        'linkedinUrl': linkedinUrl,
        'website': website,
        'company': company,
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
        bio: map['bio'],
        headline: map['headline'],
        location: map['location'],
        linkedinUrl: map['linkedinUrl'],
        website: map['website'],
        company: map['company'],
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}