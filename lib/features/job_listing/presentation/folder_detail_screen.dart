import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/job_collection_model.dart';
import '../../auth/data/auth_providers.dart';
import '../data/collection_providers.dart';
import '../data/job_providers.dart';
import 'widgets/job_card_widget.dart';
import 'widgets/save_to_folder_sheet.dart';

class FolderDetailScreen extends ConsumerWidget {
  final String collectionId;
  final String collectionName;

  const FolderDetailScreen({
    super.key,
    required this.collectionId,
    required this.collectionName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(folderJobsProvider(collectionId));
    final bookmarkedIds = ref.watch(bookmarkedIdsProvider).value ?? {};
    final user = ref.watch(firebaseUserProvider).value;

    // Keep the live name from stream in case it's renamed
    final collections = ref.watch(collectionsStreamProvider).value ?? [];
    final liveCol = collections.firstWhere(
      (c) => c.id == collectionId,
      orElse: () => JobCollectionModel(
        id: collectionId,
        name: collectionName,
        jobIds: const [],
        createdAt: DateTime.now(),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppColors.textPrimary),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_rounded,
                color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            Text(
              liveCol.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: jobsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text('Error loading jobs',
              style: GoogleFonts.inter(color: AppColors.error)),
        ),
        data: (jobs) {
          if (jobs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.folder_open_rounded,
                          size: 40, color: AppColors.accent),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Folder is empty',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Long-press any job card to add it to this folder.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            itemCount: jobs.length,
            itemBuilder: (_, i) {
              final job = jobs[i];
              final isBookmarked = bookmarkedIds.contains(job.id);
              return Dismissible(
                key: ValueKey(job.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.folder_off_rounded,
                      color: AppColors.error, size: 24),
                ),
                confirmDismiss: (_) async {
                  await _removeFromFolder(ref, user?.uid, job.id);
                  return true;
                },
                child: JobCardWidget(
                  job: job,
                  isBookmarked: isBookmarked,
                  onTap: () =>
                      context.push(AppRoutes.jobDetail, extra: job),
                  onBookmark: () {
                    if (user != null) {
                      ref
                          .read(bookmarkNotifierProvider.notifier)
                          .toggle(job.id, isBookmarked);
                    }
                  },
                  onLongPress: () =>
                      _showSaveToFolder(context, job.id, job.title),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showSaveToFolder(
      BuildContext context, String jobId, String jobTitle) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SaveToFolderSheet(jobId: jobId, jobTitle: jobTitle),
    );
  }

  Future<void> _removeFromFolder(
      WidgetRef ref, String? uid, String jobId) async {
    if (uid == null) return;
    await ref
        .read(collectionRepositoryProvider)
        .removeJob(uid, collectionId, jobId);
  }
}
