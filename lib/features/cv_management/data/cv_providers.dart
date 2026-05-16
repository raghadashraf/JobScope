import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/cv_parser_service.dart';
import '../../../data/models/cv_model.dart';
import '../../auth/data/auth_providers.dart';

// ─── Service provider ─────────────────────────────────────────────────────────
final cvParserServiceProvider =
    Provider<CvParserService>((_) => CvParserService());

// ─── Stream: live CV data for current user ────────────────────────────────────
final cvStreamProvider = StreamProvider<CvModel?>((ref) {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return Stream.value(null);
  return ref.read(cvParserServiceProvider).cvStream(user.uid);
});

// ─── State: upload progress / status ─────────────────────────────────────────
enum CvUploadStatus { idle, picking, uploading, parsing, done, error }

class CvUploadState {
  final CvUploadStatus status;
  final String? errorMessage;
  final CvModel? result;
  final double uploadProgress;

  const CvUploadState({
    this.status = CvUploadStatus.idle,
    this.errorMessage,
    this.result,
    this.uploadProgress = 0,
  });

  CvUploadState copyWith({
    CvUploadStatus? status,
    String? errorMessage,
    CvModel? result,
    double? uploadProgress,
  }) =>
      CvUploadState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        result: result ?? this.result,
        uploadProgress: uploadProgress ?? this.uploadProgress,
      );
}

// FIXED: Riverpod 3.x uses Notifier instead of StateNotifier
class CvUploadNotifier extends Notifier<CvUploadState> {
  @override
  CvUploadState build() => const CvUploadState();

  Future<void> pickAndUpload() async {
    final service = ref.read(cvParserServiceProvider);
    final user = ref.read(firebaseUserProvider).value;
    final uid = user?.uid ?? '';

    if (uid.isEmpty) {
      state = CvUploadState(
          status: CvUploadStatus.error,
          errorMessage: 'You must be logged in to upload a CV.');
      return;
    }

    state = state.copyWith(status: CvUploadStatus.picking);
    try {
      state = state.copyWith(status: CvUploadStatus.uploading, uploadProgress: 0.3);
      final upload = await service.pickAndUploadFile(uid: uid);
      state = state.copyWith(status: CvUploadStatus.parsing, uploadProgress: 0.6);
      final cv = await service.parseAndSave(upload);
      state = CvUploadState(status: CvUploadStatus.done, result: cv);
    } on Exception catch (e) {
      final raw = e.toString();
      final String msg;
      if (raw.contains('unauthorized') || raw.contains('permission') || raw.contains('Permission')) {
        msg = 'Upload failed: storage permission denied. Please contact support.';
      } else if (raw.contains('no-bucket') || raw.contains('No storage') || raw.contains('no storage')) {
        msg = 'Upload failed: Firebase Storage is not configured. Please contact support.';
      } else if (raw.contains('No file selected') || raw.contains('canceled')) {
        msg = 'No file was selected.';
      } else if (raw.contains('Could not read')) {
        msg = 'Could not read the file. Please try again.';
      } else if (raw.contains('Could not extract')) {
        msg = 'Could not extract text from file. Make sure it is not a scanned image.';
      } else {
        msg = raw.replaceFirst('Exception: ', '');
      }
      state = CvUploadState(status: CvUploadStatus.error, errorMessage: msg);
    }
  }

  void reset() => state = const CvUploadState();
}

// FIXED: NotifierProvider instead of StateNotifierProvider
final cvUploadProvider =
    NotifierProvider<CvUploadNotifier, CvUploadState>(CvUploadNotifier.new);
