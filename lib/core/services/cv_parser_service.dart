import 'dart:typed_data';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/utils/firestore_helpers.dart';
import '../../core/utils/cv_profile_strength.dart';
import '../../core/constants/profile_levels.dart';
import '../../data/models/cv_model.dart';
import '../../data/repositories/user_stats_repository.dart';
import 'ai_service.dart';

const int _maxFileSizeBytes = 25 * 1024 * 1024; // 25 MB

/// One canonical candidate profile doc: users/{uid}/cvs/profile
const String kCandidateProfileDocId = 'profile';

class CvParserService {
  final _ensureLocks = <String, Future<void>>{};
  final FirebaseFirestore _firestore = appFirestore;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AiService _aiService = AiService();
  final UserStatsRepository _userStats = UserStatsRepository();

  CollectionReference _userCvs(String uid) =>
      _firestore.collection('users').doc(uid).collection('cvs');

  /// Stage 1: pick a file and upload it to Storage.
  Future<CvUploadResult> pickAndUploadFile({
    required String uid,
    void Function(double progress)? onUploadProgress,
    bool requireExtractedText = true,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('No file selected');
    }

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) throw Exception('Could not read file bytes');

    if (bytes.length > _maxFileSizeBytes) {
      throw Exception(
          'File is too large (${(bytes.length / 1048576).toStringAsFixed(1)} MB). '
          'Maximum allowed size is 25 MB.');
    }

    final fileName = file.name;
    final extension = file.extension?.toLowerCase() ?? '';

    final cvText = _extractText(bytes, extension);
    if (requireExtractedText && cvText.trim().isEmpty) {
      throw Exception(
        'Could not extract text from the file. '
        'Make sure the PDF is not a scanned image.',
      );
    }

    final storagePath = 'cvs/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final fileUrl = await _uploadToStorage(
      storagePath: storagePath,
      bytes: bytes,
      fileName: fileName,
      onProgress: onUploadProgress,
    );

    return CvUploadResult(
      uid: uid,
      fileUrl: fileUrl,
      fileName: fileName,
      cvText: cvText,
      storagePath: storagePath,
    );
  }

  /// Stage 2: parse CV text and merge into the single candidate profile.
  Future<CvModel> parseAndSave(CvUploadResult upload) async {
    final existing = await fetchProfile(upload.uid);
    final parsed = await _aiService.parseCv(
      cvText: upload.cvText,
      uid: upload.uid,
      fileUrl: upload.fileUrl,
      fileName: upload.fileName,
    );

    final merged = _mergeProfiles(
      existing,
      parsed.copyWith(storagePath: upload.storagePath),
    );
    return _saveProfileDoc(merged, storagePath: upload.storagePath);
  }

  /// Attach a file to the single profile without AI parsing.
  Future<CvModel> saveBasicUpload(CvUploadResult upload) async {
    final existing = await fetchProfile(upload.uid);
    final base = existing ??
        CvModel(
          uid: upload.uid,
          fileUrl: '',
          fileName: 'My Profile',
          uploadedAt: DateTime.now(),
          skills: const [],
          workExperience: const [],
          education: const [],
          profileStrength: 0,
        );

    final withFile = base.copyWith(
      fileUrl: upload.fileUrl,
      fileName: upload.fileName,
      storagePath: upload.storagePath,
      uploadedAt: DateTime.now(),
    );
    return _saveProfileDoc(
      withFile.copyWith(profileStrength: CvProfileStrength.fromCv(withFile)),
      storagePath: upload.storagePath,
    );
  }

  /// Upsert skills / experience / education on the single profile.
  Future<CvModel> saveProfile({
    required String uid,
    required List<String> skills,
    required List<WorkExperience> workExperience,
    required List<Education> education,
    String? experienceLevel,
    String? educationLevel,
  }) async {
    final existing = await fetchProfile(uid);
    final base = existing ??
        CvModel(
          uid: uid,
          fileUrl: '',
          fileName: 'My Profile',
          uploadedAt: DateTime.now(),
          skills: const [],
          workExperience: const [],
          education: const [],
          profileStrength: 0,
        );

    final resolvedExp = experienceLevel ??
        ProfileLevels.inferExperienceLevel(workExperience.length) ??
        base.experienceLevel;
    final resolvedEdu = educationLevel ??
        ProfileLevels.inferEducationLevel(education) ??
        base.educationLevel;

    final draft = base.copyWith(
      skills: skills,
      workExperience: workExperience,
      education: education,
      experienceLevel: resolvedExp,
      educationLevel: resolvedEdu,
    );
    final updated =
        draft.copyWith(profileStrength: CvProfileStrength.fromCv(draft));
    return _saveProfileDoc(updated);
  }

  /// Merge into the single profile (AI builder and legacy callers).
  Future<CvModel> insertCv(CvModel cv, {String? storagePath}) async {
    final existing = await fetchProfile(cv.uid);
    return _saveProfileDoc(
      _mergeProfiles(existing, cv),
      storagePath: storagePath ?? cv.storagePath,
    );
  }

  /// Remove attached PDF/DOCX but keep profile skills and experience.
  Future<CvModel?> removeAttachedFile(String uid) async {
    final existing = await fetchProfile(uid);
    if (existing == null || !existing.hasFile) return existing;

    if (existing.storagePath.isNotEmpty) {
      try {
        await _storage.ref().child(existing.storagePath).delete();
      } catch (_) {}
    } else if (existing.fileUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(existing.fileUrl).delete();
      } catch (_) {}
    }

    final cleared = existing.copyWith(
      fileUrl: '',
      fileName: existing.fileName == 'My Profile' ? 'My Profile' : 'My Profile',
      storagePath: '',
    );
    final updated =
        cleared.copyWith(profileStrength: CvProfileStrength.fromCv(cleared));
    return _saveProfileDoc(updated);
  }

  Future<CvModel?> fetchProfile(String uid) async {
    try {
      final doc = await _userCvs(uid).doc(kCandidateProfileDocId).get();
      if (doc.exists) {
        return CvModel.fromMap(
          doc.data() as Map<String, dynamic>,
          docId: kCandidateProfileDocId,
        );
      }
    } catch (_) {}

    try {
      final legacy = await _firestore.collection('cvs').doc(uid).get();
      if (legacy.exists) {
        return CvModel.fromMap(
          legacy.data() as Map<String, dynamic>,
          docId: uid,
        );
      }
    } catch (_) {}

    return null;
  }

  Stream<CvModel?> profileStream(String uid) {
    CvModel? previous;
    var hasEmitted = false;
    return _userCvs(uid)
        .doc(kCandidateProfileDocId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return CvModel.fromMap(
        doc.data() as Map<String, dynamic>,
        docId: kCandidateProfileDocId,
      );
    }).where((cv) {
      if (!hasEmitted) {
        hasEmitted = true;
        previous = cv;
        return true;
      }
      if (previous != null &&
          cv != null &&
          _profileContentEquals(previous!, cv)) {
        return false;
      }
      if (previous == null && cv == null) {
        return false;
      }
      previous = cv;
      return true;
    });
  }

  /// Migrate legacy data and merge duplicate profile docs into one.
  Future<void> ensureSingleProfile(String uid) {
    return _ensureLocks.putIfAbsent(uid, () async {
      try {
        await migrateLegacyCvIfNeeded(uid);
        await consolidateProfiles(uid);
      } finally {
        _ensureLocks.remove(uid);
      }
    });
  }

  Future<void> consolidateProfiles(String uid) async {
    final all = await _fetchAllCvDocs(uid);
    if (all.isEmpty) return;

    if (all.length == 1 && all.first.id == kCandidateProfileDocId) return;

    final extras = all.where((c) => c.id != kCandidateProfileDocId).toList();
    CvModel? canonical;
    for (final cv in all) {
      if (cv.id == kCandidateProfileDocId) {
        canonical = cv;
        break;
      }
    }

    if (canonical != null && extras.isEmpty) return;

    all.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    var merged = canonical ?? all.first;
    final mergeSources = canonical == null ? all.skip(1) : extras;
    for (final extra in mergeSources) {
      merged = _mergeProfiles(merged, extra);
    }

    final latestFile = all.firstWhere((c) => c.hasFile, orElse: () => all.first);
    merged = merged.copyWith(
      id: kCandidateProfileDocId,
      fileUrl: latestFile.fileUrl,
      fileName: latestFile.hasFile ? latestFile.fileName : merged.fileName,
      storagePath: latestFile.storagePath,
      uploadedAt: latestFile.hasFile ? latestFile.uploadedAt : merged.uploadedAt,
      profileStrength: CvProfileStrength.fromCv(merged),
    );

    final base = canonical ?? merged;
    if (!_profileContentEquals(base, merged)) {
      await _saveProfileDoc(merged, storagePath: merged.storagePath);
    }

    for (final cv in all) {
      if (cv.id == kCandidateProfileDocId) continue;
      try {
        if (cv.id == uid) {
          final legacy = await _firestore.collection('cvs').doc(uid).get();
          if (legacy.exists) {
            await _deleteCvDocData(legacy.data()!);
            await legacy.reference.delete();
          }
        } else {
          final doc = await _userCvs(uid).doc(cv.id).get();
          if (doc.exists) {
            if (cv.hasFile && cv.fileUrl != merged.fileUrl) {
              await _deleteCvDocData(doc.data() as Map<String, dynamic>);
            }
            await doc.reference.delete();
          }
        }
      } catch (_) {}
    }
  }

  CvModel _mergeProfiles(CvModel? existing, CvModel incoming) {
    if (existing == null) {
      return incoming.copyWith(
        id: kCandidateProfileDocId,
        fileName: incoming.fileName.isNotEmpty ? incoming.fileName : 'My Profile',
      );
    }

    final mergedSkills = _mergeStringLists(existing.skills, incoming.skills);
    final mergedEducation =
        _mergeEducationLists(existing.education, incoming.education);
    final mergedExperience = _mergeWorkExperienceLists(
      existing.workExperience,
      incoming.workExperience,
    );

    return existing.copyWith(
      id: kCandidateProfileDocId,
      fileUrl: incoming.fileUrl.isNotEmpty ? incoming.fileUrl : existing.fileUrl,
      fileName: incoming.fileName.isNotEmpty ? incoming.fileName : existing.fileName,
      storagePath:
          incoming.storagePath.isNotEmpty ? incoming.storagePath : existing.storagePath,
      uploadedAt: incoming.hasFile ? incoming.uploadedAt : existing.uploadedAt,
      skills: mergedSkills,
      workExperience: mergedExperience,
      education: mergedEducation,
      experienceLevel: incoming.experienceLevel ?? existing.experienceLevel,
      educationLevel: incoming.educationLevel ?? existing.educationLevel,
      profileStrength: CvProfileStrength.fromCv(
        existing.copyWith(
          skills: mergedSkills,
          workExperience: mergedExperience,
          education: mergedEducation,
          experienceLevel: incoming.experienceLevel ?? existing.experienceLevel,
          educationLevel: incoming.educationLevel ?? existing.educationLevel,
          fileUrl: incoming.fileUrl.isNotEmpty ? incoming.fileUrl : existing.fileUrl,
        ),
      ),
    );
  }

  List<String> _mergeStringLists(List<String> a, List<String> b) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in [...a, ...b]) {
      final key = raw.toLowerCase().trim();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      out.add(raw.trim());
    }
    return out;
  }

  List<WorkExperience> _mergeWorkExperienceLists(
    List<WorkExperience> a,
    List<WorkExperience> b,
  ) {
    final out = List<WorkExperience>.from(a);
    for (final item in b) {
      final key =
          '${item.title.toLowerCase().trim()}|${item.company.toLowerCase().trim()}';
      if (out.any((x) =>
          '${x.title.toLowerCase().trim()}|${x.company.toLowerCase().trim()}' ==
          key)) {
        continue;
      }
      out.add(item);
    }
    return out;
  }

  List<Education> _mergeEducationLists(List<Education> a, List<Education> b) {
    final out = List<Education>.from(a);
    for (final item in b) {
      final key =
          '${item.degree.toLowerCase().trim()}|${item.institution.toLowerCase().trim()}';
      if (out.any((x) =>
          '${x.degree.toLowerCase().trim()}|${x.institution.toLowerCase().trim()}' ==
          key)) {
        continue;
      }
      out.add(item);
    }
    return out;
  }

  bool _profileContentEquals(CvModel a, CvModel b) {
    if (a.fileUrl != b.fileUrl ||
        a.fileName != b.fileName ||
        a.storagePath != b.storagePath ||
        a.experienceLevel != b.experienceLevel ||
        a.educationLevel != b.educationLevel) {
      return false;
    }
    if (a.skills.length != b.skills.length ||
        a.workExperience.length != b.workExperience.length ||
        a.education.length != b.education.length) {
      return false;
    }
    for (var i = 0; i < a.skills.length; i++) {
      if (a.skills[i] != b.skills[i]) return false;
    }
    for (var i = 0; i < a.workExperience.length; i++) {
      final x = a.workExperience[i];
      final y = b.workExperience[i];
      if (x.title != y.title ||
          x.company != y.company ||
          x.duration != y.duration ||
          x.description != y.description) {
        return false;
      }
    }
    for (var i = 0; i < a.education.length; i++) {
      final x = a.education[i];
      final y = b.education[i];
      if (x.degree != y.degree ||
          x.field != y.field ||
          x.institution != y.institution ||
          x.year != y.year) {
        return false;
      }
    }
    return true;
  }

  Future<CvModel> _saveProfileDoc(CvModel cv, {String? storagePath}) async {
    final path = storagePath ?? cv.storagePath;
    final saved = cv.copyWith(id: kCandidateProfileDocId);

    try {
      await firestoreWrite(
        _userCvs(cv.uid).doc(kCandidateProfileDocId).set(
              firestoreEncode({...saved.toMap(), 'id': kCandidateProfileDocId}),
              SetOptions(merge: true),
            ),
      );
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      await firestoreWrite(
        _firestore.collection('cvs').doc(cv.uid).set(
              firestoreEncode(saved.toMap()),
              SetOptions(merge: true),
            ),
      );
    }

    await _updateUserLatestCv(cv.uid, saved, path);
    if (path.isNotEmpty) {
      try {
        await _userStats.appendCvStoragePath(cv.uid, path);
      } catch (_) {}
    }
    return saved;
  }

  Future<void> _updateUserLatestCv(
      String uid, CvModel cv, String storagePath) async {
    final updates = <String, dynamic>{
      'latestCvId': kCandidateProfileDocId,
      'cvUrl': cv.fileUrl,
      'profileStrength': cv.profileStrength,
    };
    if (storagePath.isNotEmpty) {
      updates['cvStoragePaths'] = FieldValue.arrayUnion([storagePath]);
    }

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final data = userDoc.data();
      if (data != null) {
        final sameMeta = data['latestCvId'] == kCandidateProfileDocId &&
            (data['cvUrl'] as String? ?? '') == cv.fileUrl &&
            (data['profileStrength'] as num?)?.toInt() == cv.profileStrength;
        if (sameMeta && storagePath.isEmpty) return;
      }
    } catch (_) {}

    await firestoreWrite(
      _firestore.collection('users').doc(uid).update(updates),
    );
  }

  /// Clears the entire candidate profile (rare — prefer [removeAttachedFile]).
  Future<void> deleteProfile(String uid) async {
    final profile = await fetchProfile(uid);
    if (profile == null) return;

    if (profile.hasFile) {
      await _deleteCvDocData(profile.toMap());
    }

    try {
      await _userCvs(uid).doc(kCandidateProfileDocId).delete();
    } catch (_) {}

    try {
      await _firestore.collection('cvs').doc(uid).delete();
    } catch (_) {}

    await firestoreWrite(
      _firestore.collection('users').doc(uid).update({
        'latestCvId': FieldValue.delete(),
        'cvUrl': FieldValue.delete(),
        'profileStrength': 0,
      }),
    );
  }

  @Deprecated('Use removeAttachedFile or deleteProfile')
  Future<void> deleteCv(String uid, {String? cvId}) async {
    await deleteProfile(uid);
  }

  Future<void> _deleteCvDocData(Map<String, dynamic> data) async {
    final fileUrl = data['fileUrl'] as String?;
    if (fileUrl != null && fileUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(fileUrl).delete();
      } catch (_) {}
    }
  }

  /// Copy legacy [cvs/{uid}] into the subcollection if not migrated yet.
  /// If the legacy doc was removed but [users.cvUrl] still exists, rebuild from that.
  Future<void> migrateLegacyCvIfNeeded(String uid) async {
    try {
      final profile = await _userCvs(uid).doc(kCandidateProfileDocId).get();
      if (profile.exists) return;

      final legacy = await _firestore.collection('cvs').doc(uid).get();
      if (legacy.exists) {
        final cv = CvModel.fromMap(
          legacy.data() as Map<String, dynamic>,
          docId: uid,
        );
        await _saveProfileDoc(cv.copyWith(id: kCandidateProfileDocId));
        return;
      }

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final data = userDoc.data();
      final cvUrl = data?['cvUrl'] as String?;
      if (cvUrl == null || cvUrl.isEmpty) return;

      final fileName = _fileNameFromUrl(cvUrl);
      final strength = (data?['profileStrength'] as num?)?.toInt() ?? 10;
      await _saveProfileDoc(
        CvModel(
          uid: uid,
          fileUrl: cvUrl,
          fileName: fileName,
          uploadedAt: DateTime.now(),
          skills: const [],
          workExperience: const [],
          education: const [],
          profileStrength: strength,
        ),
      );
    } catch (_) {
      // Rules may not be deployed yet; legacy doc remains readable.
    }
  }

  String _fileNameFromUrl(String url) {
    try {
      final segment = Uri.parse(url).pathSegments.last;
      if (segment.contains('_')) {
        return Uri.decodeComponent(segment.split('_').skip(1).join('_'));
      }
      return Uri.decodeComponent(segment);
    } catch (_) {
      return 'CV.pdf';
    }
  }

  Future<List<CvModel>> _fetchAllCvDocs(String uid) async {
    final list = <CvModel>[];

    try {
      final snap = await _userCvs(uid).get();
      list.addAll(snap.docs.map(
        (d) => CvModel.fromMap(d.data() as Map<String, dynamic>, docId: d.id),
      ));
    } catch (_) {}

    final hasCanonical =
        list.any((c) => c.id == kCandidateProfileDocId);

    if (!hasCanonical) {
      try {
        final legacy = await _firestore.collection('cvs').doc(uid).get();
        if (legacy.exists) {
          final legacyCv = CvModel.fromMap(
            legacy.data() as Map<String, dynamic>,
            docId: uid,
          );
          final duplicate = list.any(
            (c) => c.fileUrl == legacyCv.fileUrl && c.fileUrl.isNotEmpty,
          );
          if (!duplicate) list.add(legacyCv);
        }
      } catch (_) {}
    }

    list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return list;
  }

  Future<CvModel?> getCv(String uid, {String? cvId}) async {
    if (cvId != null && cvId.isNotEmpty) {
      if (cvId == kCandidateProfileDocId || cvId == uid) {
        return fetchProfile(uid);
      }
      final doc = await _userCvs(uid).doc(cvId).get();
      if (doc.exists) {
        return CvModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }
      return null;
    }
    return fetchProfile(uid);
  }

  Stream<CvModel?> cvStream(String uid) => profileStream(uid);

  Stream<List<CvModel>> userCvsStream(String uid) {
    return profileStream(uid).map((profile) => profile == null ? [] : [profile]);
  }

  Future<String> _uploadToStorage({
    required String storagePath,
    required Uint8List bytes,
    required String fileName,
    void Function(double)? onProgress,
  }) async {
    final ref = _storage.ref().child(storagePath);

    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(contentType: _contentTypeFor(fileName)),
    );

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });
    }

    final taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  String _contentTypeFor(String fileName) {
    if (fileName.endsWith('.pdf')) return 'application/pdf';
    if (fileName.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return 'application/octet-stream';
  }

  String _extractText(Uint8List bytes, String extension) {
    if (extension == 'pdf') return _extractFromPdf(bytes);
    return _extractFromDocx(bytes);
  }

  String _extractFromPdf(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final text = extractor.extractText();
    document.dispose();
    return text;
  }

  String _extractFromDocx(Uint8List bytes) {
    try {
      final raw = String.fromCharCodes(bytes);
      final textBuffer = StringBuffer();
      final regex = RegExp(r'<w:t[^>]*>([^<]*)</w:t>');
      for (final match in regex.allMatches(raw)) {
        final text = match.group(1);
        if (text != null && text.trim().isNotEmpty) {
          textBuffer.write('$text ');
        }
      }
      return textBuffer.toString();
    } catch (_) {
      return '';
    }
  }
}

class CvUploadResult {
  final String uid;
  final String fileUrl;
  final String fileName;
  final String cvText;
  final String storagePath;
  const CvUploadResult({
    required this.uid,
    required this.fileUrl,
    required this.fileName,
    required this.cvText,
    this.storagePath = '',
  });
}
