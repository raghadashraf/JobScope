import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/utils/firestore_helpers.dart';
import '../../data/models/cv_model.dart';
import '../../data/repositories/user_stats_repository.dart';
import 'ai_service.dart';

const int _maxFileSizeBytes = 25 * 1024 * 1024; // 25 MB

class CvParserService {
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

  /// Stage 2: call Gemini to parse the CV text, then save to Firestore.
  Future<CvModel> parseAndSave(CvUploadResult upload) async {
    final cvModel = await _aiService.parseCv(
      cvText: upload.cvText,
      uid: upload.uid,
      fileUrl: upload.fileUrl,
      fileName: upload.fileName,
    );

    return _insertCv(
      cvModel.copyWith(storagePath: upload.storagePath),
      storagePath: upload.storagePath,
    );
  }

  /// Save uploaded file without AI parsing.
  Future<CvModel> saveBasicUpload(CvUploadResult upload) async {
    final cvModel = CvModel(
      uid: upload.uid,
      fileUrl: upload.fileUrl,
      fileName: upload.fileName,
      storagePath: upload.storagePath,
      uploadedAt: DateTime.now(),
      skills: const [],
      workExperience: const [],
      education: const [],
      profileStrength: 25,
    );

    return _insertCv(cvModel, storagePath: upload.storagePath);
  }

  /// Insert a new CV doc (supports multiple CVs per user).
  Future<CvModel> insertCv(CvModel cv, {String? storagePath}) =>
      _insertCv(cv, storagePath: storagePath);

  Future<CvModel> _insertCv(CvModel cv, {String? storagePath}) async {
    final path = storagePath ?? cv.storagePath;
    CvModel saved;

    try {
      final ref = _userCvs(cv.uid).doc();
      final id = ref.id;
      saved = cv.copyWith(id: id);
      await firestoreWrite(
        ref.set(firestoreEncode({...saved.toMap(), 'id': id})),
      );
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      // Fallback: legacy single-doc path (rules already allow /cvs/{docId}).
      saved = cv.copyWith(id: cv.uid);
      await firestoreWrite(
        _firestore
            .collection('cvs')
            .doc(cv.uid)
            .set(firestoreEncode(saved.toMap()), SetOptions(merge: true)),
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
    await firestoreWrite(
      _firestore.collection('users').doc(uid).update({
        'latestCvId': cv.id,
        'cvUrl': cv.fileUrl,
        'profileStrength': cv.profileStrength,
        if (storagePath.isNotEmpty)
          'cvStoragePaths': FieldValue.arrayUnion([storagePath]),
      }),
    );
  }

  /// Delete a specific CV by id. Legacy doc [cvs/{uid}] is only removed when
  /// that exact document is the one being deleted.
  Future<void> deleteCv(String uid, {String? cvId}) async {
    if (cvId == null || cvId.isEmpty) return;

    final subDoc = await _userCvs(uid).doc(cvId).get();
    if (subDoc.exists) {
      await _deleteCvDocData(subDoc.data() as Map<String, dynamic>);
      await subDoc.reference.delete();
    } else if (cvId == uid) {
      final legacy = await _firestore.collection('cvs').doc(uid).get();
      if (legacy.exists) {
        await _deleteCvDocData(legacy.data()!);
        await legacy.reference.delete();
      }
    }

    final remaining = await _fetchUserCvs(uid);
    if (remaining.isNotEmpty) {
      await _updateUserLatestCv(uid, remaining.first, remaining.first.storagePath);
    } else {
      await firestoreWrite(
        _firestore.collection('users').doc(uid).update({
          'latestCvId': FieldValue.delete(),
          'cvUrl': FieldValue.delete(),
          'profileStrength': 0,
        }),
      );
    }
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
      if ((await _fetchUserCvs(uid)).isNotEmpty) return;

      final legacy = await _firestore.collection('cvs').doc(uid).get();
      if (legacy.exists) {
        final cv = CvModel.fromMap(
          legacy.data() as Map<String, dynamic>,
          docId: uid,
        );
        await _insertCv(cv, storagePath: cv.storagePath);
        return;
      }

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final data = userDoc.data();
      final cvUrl = data?['cvUrl'] as String?;
      if (cvUrl == null || cvUrl.isEmpty) return;

      final fileName = _fileNameFromUrl(cvUrl);
      final strength = (data?['profileStrength'] as num?)?.toInt() ?? 25;
      await _insertCv(
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

  Future<List<CvModel>> _fetchUserCvs(String uid) async {
    final list = <CvModel>[];

    try {
      final snap = await _userCvs(uid).get();
      list.addAll(snap.docs.map(
        (d) => CvModel.fromMap(d.data() as Map<String, dynamic>, docId: d.id),
      ));
    } catch (_) {}

    try {
      final legacy = await _firestore.collection('cvs').doc(uid).get();
      if (legacy.exists) {
        final legacyCv = CvModel.fromMap(
          legacy.data() as Map<String, dynamic>,
          docId: uid,
        );
        final duplicate = list.any(
          (c) =>
              c.fileUrl == legacyCv.fileUrl &&
              c.fileUrl.isNotEmpty,
        );
        if (!duplicate) list.add(legacyCv);
      }
    } catch (_) {}

    list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return list;
  }

  Future<CvModel?> getCv(String uid, {String? cvId}) async {
    if (cvId != null && cvId.isNotEmpty) {
      final doc = await _userCvs(uid).doc(cvId).get();
      if (doc.exists) {
        return CvModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }
      if (cvId == uid) {
        final legacy = await _firestore.collection('cvs').doc(uid).get();
        if (legacy.exists) {
          return CvModel.fromMap(legacy.data() as Map<String, dynamic>, docId: uid);
        }
      }
      return null;
    }
    final all = await _fetchUserCvs(uid);
    return all.isEmpty ? null : all.first;
  }

  /// Latest CV for dashboard evaluation (most recently uploaded).
  Stream<CvModel?> cvStream(String uid) {
    return userCvsStream(uid).map((list) => list.isEmpty ? null : list.first);
  }

  /// All CVs for the user, newest first (subcollection + legacy merged).
  Stream<List<CvModel>> userCvsStream(String uid) {
    return Stream<List<CvModel>>.multi((controller) {
      Future<void> emitMerged() async {
        controller.add(await _fetchUserCvs(uid));
      }

      final subSub = _userCvs(uid).snapshots().listen(
        (_) => emitMerged(),
        onError: (_) => emitMerged(),
      );
      final legacySub = _firestore.collection('cvs').doc(uid).snapshots().listen(
        (_) => emitMerged(),
        onError: (_) => emitMerged(),
      );

      emitMerged();

      controller.onCancel = () async {
        await subSub.cancel();
        await legacySub.cancel();
      };
    });
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
