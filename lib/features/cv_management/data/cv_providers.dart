import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/cv_parser_service.dart';
import '../../../data/models/cv_model.dart';
import '../../auth/data/auth_providers.dart';

// ─── Service provider ─────────────────────────────────────────────────────────
final cvParserServiceProvider =
    Provider<CvParserService>((_) => CvParserService());

// ─── Stream: all CVs for current user (newest first) ─────────────────────────
final userCvsStreamProvider = StreamProvider<List<CvModel>>((ref) {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return Stream.value([]);

  final service = ref.read(cvParserServiceProvider);
  // One-time migration of legacy cvs/{uid} → users/{uid}/cvs/{id}.
  service.migrateLegacyCvIfNeeded(user.uid);

  return service.userCvsStream(user.uid);
});

// ─── Stream: latest CV (dashboard evaluation card) ───────────────────────────
final cvStreamProvider = StreamProvider<CvModel?>((ref) {
  final list = ref.watch(userCvsStreamProvider).value ?? [];
  return Stream.value(list.isEmpty ? null : list.first);
});

final cvByIdProvider =
    FutureProvider.autoDispose.family<CvModel?, ({String uid, String cvId})>(
        (ref, params) {
  return ref
      .read(cvParserServiceProvider)
      .getCv(params.uid, cvId: params.cvId);
});

// ─── State: upload / delete progress & status ────────────────────────────────
enum CvUploadStatus { idle, picking, uploading, parsing, deleting, done, error }

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

class CvUploadNotifier extends Notifier<CvUploadState> {
  @override
  CvUploadState build() => const CvUploadState();

  /// Upload CV file only — no AI parsing (dashboard quick upload).
  Future<void> pickAndUploadBasic() async {
    final service = ref.read(cvParserServiceProvider);
    final user = ref.read(firebaseUserProvider).value;
    final uid = user?.uid ?? '';

    if (uid.isEmpty) {
      state = const CvUploadState(
          status: CvUploadStatus.error,
          errorMessage: 'You must be logged in to upload a CV.');
      return;
    }

    state = state.copyWith(status: CvUploadStatus.picking, uploadProgress: 0);
    try {
      state =
          state.copyWith(status: CvUploadStatus.uploading, uploadProgress: 0);

      final upload = await service.pickAndUploadFile(
        uid: uid,
        requireExtractedText: false,
        onUploadProgress: (p) {
          state = state.copyWith(uploadProgress: p.clamp(0.0, 0.98));
        },
      );

      state = state.copyWith(status: CvUploadStatus.parsing, uploadProgress: 1.0);
      final cv = await service.saveBasicUpload(upload);
      state = CvUploadState(status: CvUploadStatus.done, result: cv);
    } on Exception catch (e) {
      state = CvUploadState(
        status: CvUploadStatus.error,
        errorMessage: _uploadErrorMessage(e),
      );
    }
  }

  Future<void> pickAndUpload() async {
    final service = ref.read(cvParserServiceProvider);
    final user = ref.read(firebaseUserProvider).value;
    final uid = user?.uid ?? '';

    if (uid.isEmpty) {
      state = const CvUploadState(
          status: CvUploadStatus.error,
          errorMessage: 'You must be logged in to upload a CV.');
      return;
    }

    state = state.copyWith(status: CvUploadStatus.picking, uploadProgress: 0);
    try {
      state = state.copyWith(status: CvUploadStatus.uploading, uploadProgress: 0);

      final upload = await service.pickAndUploadFile(
        uid: uid,
        onUploadProgress: (p) {
          // Clamp to 0.95 so the bar doesn't reach 100% before parsing starts.
          state = state.copyWith(uploadProgress: p.clamp(0.0, 0.95));
        },
      );

      state = state.copyWith(status: CvUploadStatus.parsing, uploadProgress: 1.0);
      final cv = await service.parseAndSave(upload);
      state = CvUploadState(status: CvUploadStatus.done, result: cv);
    } on Exception catch (e) {
      state = CvUploadState(
        status: CvUploadStatus.error,
        errorMessage: _uploadErrorMessage(e),
      );
    }
  }

  String _uploadErrorMessage(Exception e) {
    final raw = e.toString();
    if (raw.contains('unauthorized') ||
        raw.contains('permission') ||
        raw.contains('Permission')) {
      return 'Upload failed: storage permission denied. Please contact support.';
    }
    if (raw.contains('no-bucket') ||
        raw.contains('No storage') ||
        raw.contains('no storage')) {
      return 'Upload failed: Firebase Storage is not configured. Please contact support.';
    }
    if (raw.contains('No file selected') || raw.contains('canceled')) {
      return 'No file was selected.';
    }
    if (raw.contains('too large')) {
      return raw.replaceFirst('Exception: ', '');
    }
    if (raw.contains('Could not read')) {
      return 'Could not read the file. Please try again.';
    }
    if (raw.contains('Could not extract')) {
      return 'Could not extract text from file. Make sure it is not a scanned image.';
    }
    return raw.replaceFirst('Exception: ', '');
  }

  Future<void> deleteCv({String? cvId}) async {
    final service = ref.read(cvParserServiceProvider);
    final user = ref.read(firebaseUserProvider).value;
    final uid = user?.uid ?? '';

    if (uid.isEmpty) return;

    state = state.copyWith(status: CvUploadStatus.deleting);
    try {
      await service.deleteCv(uid, cvId: cvId);
      state = const CvUploadState(status: CvUploadStatus.idle);
    } on Exception catch (e) {
      state = CvUploadState(
        status: CvUploadStatus.error,
        errorMessage: 'Failed to delete CV: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  void reset() => state = const CvUploadState();
}

final cvUploadProvider =
    NotifierProvider<CvUploadNotifier, CvUploadState>(CvUploadNotifier.new);
