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

    state = state.copyWith(status: CvUploadStatus.picking);
    try {
      state = state.copyWith(
          status: CvUploadStatus.uploading, uploadProgress: 0.3);
      final cv = await service.pickUploadAndParse(uid: uid);
      state = CvUploadState(status: CvUploadStatus.done, result: cv);
    } on Exception catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = CvUploadState(status: CvUploadStatus.error, errorMessage: msg);
    }
  }

  void reset() => state = const CvUploadState();
}

// FIXED: NotifierProvider instead of StateNotifierProvider
final cvUploadProvider =
    NotifierProvider<CvUploadNotifier, CvUploadState>(CvUploadNotifier.new);
