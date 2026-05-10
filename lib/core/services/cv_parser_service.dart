import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../data/models/cv_model.dart'; // FIXED: was '../data/models/cv_model.dart'
import 'ai_service.dart';

class CvParserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AiService _aiService = AiService();

  /// Full CV pipeline: pick → upload → extract → parse → save.
  Future<CvModel> pickUploadAndParse({required String uid}) async {
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

    final fileName = file.name;
    final extension = file.extension?.toLowerCase() ?? '';

    final fileUrl = await _uploadToStorage(
      uid: uid,
      bytes: bytes,
      fileName: fileName,
    );

    final cvText = _extractText(bytes, extension);
    if (cvText.trim().isEmpty) {
      throw Exception(
        'Could not extract text from file. Please ensure the PDF is not scanned/image-only.',
      );
    }

    final cvModel = await _aiService.parseCv(
      cvText: cvText,
      uid: uid,
      fileUrl: fileUrl,
      fileName: fileName,
    );

    await _saveToFirestore(cvModel);

    await _firestore.collection('users').doc(uid).update({
      'cvUrl': fileUrl,
      'profileStrength': cvModel.profileStrength,
    });

    return cvModel;
  }

  Future<String> _uploadToStorage({
    required String uid,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage
        .ref()
        .child('cvs')
        .child(uid)
        .child('${timestamp}_$fileName');

    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: _contentTypeFor(fileName)),
    );

    return await uploadTask.ref.getDownloadURL();
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

  Future<void> _saveToFirestore(CvModel cv) async {
    await _firestore
        .collection('cvs')
        .doc(cv.uid)
        .set(cv.toMap(), SetOptions(merge: true));
  }

  Future<CvModel?> getCv(String uid) async {
    final doc = await _firestore.collection('cvs').doc(uid).get();
    if (!doc.exists) return null;
    return CvModel.fromMap(doc.data()!);
  }

  Stream<CvModel?> cvStream(String uid) {
    return _firestore
        .collection('cvs')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? CvModel.fromMap(doc.data()!) : null);
  }
}
