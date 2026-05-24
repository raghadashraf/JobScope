import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/collection_repository.dart';
import '../../data/collection_providers.dart';
import '../../../auth/data/auth_providers.dart';

class SaveToFolderSheet extends ConsumerStatefulWidget {
  final String jobId;
  final String jobTitle;

  const SaveToFolderSheet({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  ConsumerState<SaveToFolderSheet> createState() => _SaveToFolderSheetState();
}

class _SaveToFolderSheetState extends ConsumerState<SaveToFolderSheet> {
  bool _showNewField = false;
  final _newNameCtrl = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _newNameCtrl.dispose();
    super.dispose();
  }

  String? get _uid => ref.read(firebaseUserProvider).value?.uid;
  CollectionRepository get _repo =>
      ref.read(collectionRepositoryProvider);

  Future<void> _toggle(String collectionId, bool isInFolder) async {
    final uid = _uid;
    if (uid == null) return;
    if (isInFolder) {
      await _repo.removeJob(uid, collectionId, widget.jobId);
    } else {
      await _repo.addJob(uid, collectionId, widget.jobId);
    }
  }

  Future<void> _createAndAdd() async {
    final uid = _uid;
    final name = _newNameCtrl.text.trim();
    if (uid == null || name.isEmpty) return;
    setState(() => _creating = true);
    try {
      final created = await _repo.create(uid, name);
      await _repo.addJob(uid, created.id, widget.jobId);
      _newNameCtrl.clear();
      setState(() {
        _creating = false;
        _showNewField = false;
      });
    } catch (_) {
      setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionsStreamProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder_rounded,
                      color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save to Folder',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.jobTitle,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),

          // New folder row
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _showNewField
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: _NewFolderButton(
                onTap: () => setState(() => _showNewField = true)),
            secondChild: _NewFolderField(
              controller: _newNameCtrl,
              creating: _creating,
              onCancel: () {
                _newNameCtrl.clear();
                setState(() => _showNewField = false);
              },
              onCreate: _createAndAdd,
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Collections list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: collectionsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary)),
              ),
              error: (e, s) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Could not load folders'),
              ),
              data: (collections) {
                if (collections.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No folders yet — create one above',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textTertiary),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: collections.length,
                  itemBuilder: (_, i) {
                    final col = collections[i];
                    final inFolder = col.jobIds.contains(widget.jobId);
                    return _FolderTile(
                      name: col.name,
                      jobCount: col.jobCount,
                      inFolder: inFolder,
                      onTap: () => _toggle(col.id, inFolder),
                    );
                  },
                );
              },
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _NewFolderButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NewFolderButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    style: BorderStyle.solid),
              ),
              child: const Icon(Icons.create_new_folder_outlined,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Text(
              'New Folder',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewFolderField extends StatelessWidget {
  final TextEditingController controller;
  final bool creating;
  final VoidCallback onCancel;
  final VoidCallback onCreate;

  const _NewFolderField({
    required this.controller,
    required this.creating,
    required this.onCancel,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              style:
                  GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Folder name',
                hintStyle: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textTertiary),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5)),
              ),
              onSubmitted: (_) => onCreate(),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
            child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13)),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: creating ? null : onCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: creating
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text('Create',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  final String name;
  final int jobCount;
  final bool inFolder;
  final VoidCallback onTap;

  const _FolderTile({
    required this.name,
    required this.jobCount,
    required this.inFolder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.folder_rounded,
              color: inFolder ? AppColors.accent : AppColors.textTertiary,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$jobCount ${jobCount == 1 ? 'job' : 'jobs'}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                inFolder
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                key: ValueKey(inFolder),
                color: inFolder ? AppColors.accent : AppColors.border,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
