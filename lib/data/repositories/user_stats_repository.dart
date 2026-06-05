import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/firestore_helpers.dart';
import '../models/application_model.dart';
import '../models/user_model.dart';

class UserStatsRepository {
  final FirebaseFirestore _firestore = appFirestore;

  /// Recompute application counts from Firestore and persist on [users/{uid}].
  Future<void> refreshApplicationStats(String uid) async {
    final snap = await _firestore
        .collection('applications')
        .where('candidateId', isEqualTo: uid)
        .get();

    var total = 0;
    final byStatus = <String, int>{
      'pending': 0,
      'shortlisted': 0,
      'rejected': 0,
      'accepted': 0,
      'withdrawn': 0,
    };

    for (final doc in snap.docs) {
      final app = ApplicationModel.fromDoc(doc);
      byStatus[app.status.name] = (byStatus[app.status.name] ?? 0) + 1;
      if (app.isActive) total++;
    }

    await firestoreWrite(
      _firestore.collection('users').doc(uid).update({
        'applicationStats': {
          'total': total,
          ...byStatus,
        },
        'applicationsCount': total,
      }),
    );
  }

  Future<void> appendCvStoragePath(String uid, String storagePath) async {
    if (storagePath.isEmpty) return;
    await firestoreWrite(
      _firestore.collection('users').doc(uid).update({
        'cvStoragePaths': FieldValue.arrayUnion([storagePath]),
      }),
    );
  }

  /// Mirror profile fields the user edits onto their Firestore user doc.
  Future<void> syncProfileFields(UserModel user) async {
    await firestoreWrite(
      _firestore.collection('users').doc(user.uid).update({
        'profile': {
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'bio': user.bio,
          'headline': user.headline,
          'location': user.location,
          'linkedinUrl': user.linkedinUrl,
          'website': user.website,
          'company': user.company,
          'photoUrl': user.photoUrl,
        },
      }),
    );
  }
}
