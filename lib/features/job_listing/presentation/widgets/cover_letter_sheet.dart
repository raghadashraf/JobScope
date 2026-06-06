import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/firestore_helpers.dart';
import '../../../../data/models/application_draft_model.dart';
import '../../../../data/models/cv_model.dart';
import '../../../ai_features/data/ai_providers.dart';
import '../../../applications/data/application_draft_providers.dart';
import '../../../auth/data/auth_providers.dart';

class CoverLetterSheet extends ConsumerStatefulWidget {
  final String jobId;
  final String jobTitle;
  final String company;
  final String jobDescription;
  final CvModel selectedCv;

  const CoverLetterSheet({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.jobDescription,
    required this.selectedCv,
  });

  @override
  ConsumerState<CoverLetterSheet> createState() => _CoverLetterSheetState();
}

class _CoverLetterSheetState extends ConsumerState<CoverLetterSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final TextEditingController _controller;
  bool _loaded = false;
  bool _aiRequested = false;
  bool _isSaving = false;
  bool _isUploading = false;
  String? _uploadedFileName;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _controller = TextEditingController();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _controller.dispose();
    super.dispose();
  }

  CoverLetterParams get _aiParams => CoverLetterParams(
        jobTitle: widget.jobTitle,
        company: widget.company,
        jobDescription: widget.jobDescription,
        cvSkills: widget.selectedCv.skills,
        workExperience: widget.selectedCv.workExperience,
      );

  void _loadDraft(ApplicationDraftModel? draft) {
    if (_loaded || draft == null) return;
    if (draft.coverLetterText != null && draft.coverLetterText!.isNotEmpty) {
      _controller.text = draft.coverLetterText!;
    }
    _uploadedFileName = draft.coverLetterFileName;
    if (draft.coverLetterSource == 'ai') _tabs.index = 2;
    if (draft.coverLetterSource == 'upload') _tabs.index = 0;
    if (draft.coverLetterSource == 'manual') _tabs.index = 1;
    _loaded = true;
  }

  void _generateWithAi() {
    setState(() => _aiRequested = true);
    ref.invalidate(coverLetterProvider(_aiParams));
  }

  Future<void> _uploadCoverLetter() async {
    final user = ref.read(firebaseUserProvider).value;
    if (user == null) return;

    setState(() => _isUploading = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) throw Exception('Could not read file');

      final path =
          'cover_letters/${user.uid}/${widget.jobId}_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final refStorage = FirebaseStorage.instance.ref().child(path);
      await refStorage.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: 'application/octet-stream'),
      );
      final url = await refStorage.getDownloadURL();

      setState(() => _uploadedFileName = file.name);

      await ref.read(applicationDraftNotifierProvider.notifier).saveCoverLetter(
            jobId: widget.jobId,
            fileUrl: url,
            fileName: file.name,
            source: 'upload',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cover letter uploaded',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${firestoreErrorMessage(e)}',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveManualOrAi(String source) async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or generate cover letter text')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(applicationDraftNotifierProvider.notifier).saveCoverLetter(
            jobId: widget.jobId,
            letterText: text,
            source: source,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cover letter saved',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: ${firestoreErrorMessage(e)}',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _controller.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(applicationDraftProvider(widget.jobId)).value;
    _loadDraft(draft);

    final aiAsync =
        _aiRequested ? ref.watch(coverLetterProvider(_aiParams)) : null;
    if (_aiRequested && aiAsync != null) {
      aiAsync.whenData((text) {
        if (text.isNotEmpty && _controller.text.isEmpty) {
          _controller.text = text;
        }
      });
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cover Letter',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.jobTitle} · ${widget.company}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded,
                      color: AppColors.textSecondary, size: 20),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Upload'),
              Tab(text: 'Write'),
              Tab(text: 'AI Generate'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // Upload tab
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.upload_file_rounded,
                          size: 48, color: AppColors.primary.withValues(alpha: 0.7)),
                      const SizedBox(height: 16),
                      Text(
                        'Upload a PDF, DOCX, or TXT cover letter',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                      if (_uploadedFileName != null) ...[
                        const SizedBox(height: 12),
                        Text('Current: $_uploadedFileName',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success)),
                      ],
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _uploadCoverLetter,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.upload_rounded),
                          label: Text(_isUploading ? 'Uploading…' : 'Choose File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Write tab
                SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        maxLines: 14,
                        style: GoogleFonts.inter(fontSize: 14, height: 1.6),
                        decoration: InputDecoration(
                          hintText:
                              'Dear Hiring Manager,\n\nI am excited to apply for…',
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  _controller.text.isEmpty ? null : _copy,
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text('Copy'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () => _saveManualOrAi('manual'),
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.save_rounded, size: 16),
                              label: Text(_isSaving ? 'Saving…' : 'Save'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // AI tab
                SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Generate a tailored letter using your CV (${widget.selectedCv.fileName.isNotEmpty ? widget.selectedCv.fileName : 'profile'}) and this job\'s requirements.',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: (aiAsync?.isLoading ?? false)
                            ? null
                            : _generateWithAi,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                        label: Text((aiAsync?.isLoading ?? false)
                            ? 'Generating…'
                            : 'Generate with AI'),
                      ),
                      if (aiAsync?.hasError == true) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _generateWithAi,
                          child: const Text('Retry'),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: _controller,
                        maxLines: 12,
                        enabled: !(aiAsync?.isLoading ?? false),
                        style: GoogleFonts.inter(fontSize: 14, height: 1.6),
                        decoration: InputDecoration(
                          hintText: 'Generated text appears here — edit before saving',
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _saveManualOrAi('ai'),
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: Text(_isSaving ? 'Saving…' : 'Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
