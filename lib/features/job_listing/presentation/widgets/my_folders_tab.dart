import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/job_collection_model.dart';
import '../../data/collection_providers.dart';
import '../folder_detail_screen.dart';

class MyFoldersTab extends ConsumerWidget {
  final String? uid;
  const MyFoldersTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (uid == null) {
      return _signInPrompt();
    }

    final collectionsAsync = ref.watch(collectionsStreamProvider);

    return collectionsAsync.when(
      loading: () => const Center(
          child:
              CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
      error: (e, _) => Center(
        child: Text('Error loading folders',
            style: GoogleFonts.inter(color: AppColors.error)),
      ),
      data: (collections) {
        if (collections.isEmpty) {
          return _emptyState();
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          itemCount: collections.length,
          separatorBuilder: (_, i) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _FolderCard(
            collection: collections[i],
            uid: uid!,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FolderDetailScreen(
                  collectionId: collections[i].id,
                  collectionName: collections[i].name,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
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
              child: const Icon(Icons.folder_outlined,
                  size: 40, color: AppColors.accent),
            ),
            const SizedBox(height: 20),
            Text(
              'No folders yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Long-press any job card to save it\nto a folder.',
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

  Widget _signInPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('Sign in to use folders',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Organise saved jobs into collections',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

// ── Folder card ───────────────────────────────────────────────────────────────

class _FolderCard extends ConsumerWidget {
  final JobCollectionModel collection;
  final String uid;
  final VoidCallback onTap;

  const _FolderCard({
    required this.collection,
    required this.uid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.folder_rounded,
                  color: AppColors.accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${collection.jobCount} ${collection.jobCount == 1 ? 'job' : 'jobs'}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            // Options menu
            PopupMenuButton<_FolderAction>(
              onSelected: (action) =>
                  _onAction(context, ref, action),
              icon: Icon(Icons.more_vert_rounded,
                  color: AppColors.textTertiary, size: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _FolderAction.rename,
                  child: Row(children: [
                    Icon(Icons.drive_file_rename_outline_rounded,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text('Rename',
                        style: GoogleFonts.inter(fontSize: 14)),
                  ]),
                ),
                PopupMenuItem(
                  value: _FolderAction.delete,
                  child: Row(children: [
                    const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.error),
                    const SizedBox(width: 10),
                    Text('Delete',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.error)),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onAction(
      BuildContext context, WidgetRef ref, _FolderAction action) {
    if (action == _FolderAction.rename) {
      _showRenameDialog(context, ref);
    } else {
      _showDeleteDialog(context, ref);
    }
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: collection.name);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rename folder',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Folder name',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await ref
                    .read(collectionNotifierProvider.notifier)
                    .rename(collection.id, ctrl.text.trim());
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Save',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete folder?',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          '"${collection.name}" will be deleted. Your saved jobs won\'t be affected.',
          style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(collectionNotifierProvider.notifier)
                  .delete(collection.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

enum _FolderAction { rename, delete }
