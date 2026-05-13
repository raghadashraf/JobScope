import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_router.dart';
import '../data/job_providers.dart';
import '../../auth/data/auth_providers.dart';
import 'widgets/job_card_widget.dart';
import 'widgets/job_filter_sheet.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredJobsProvider);
    final filter = ref.watch(jobFilterProvider);
    final bookmarkedIds = ref.watch(bookmarkedIdsProvider).value ?? {};
    final user = ref.watch(firebaseUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Browse Jobs',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (filter.hasActiveFilters)
                        GestureDetector(
                          onTap: () =>
                              ref.read(jobFilterProvider.notifier).clearAll(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Clear filters',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search + Filter row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (q) =>
                              ref.read(jobFilterProvider.notifier).setSearch(q),
                          decoration: InputDecoration(
                            hintText: 'Search jobs, companies...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textTertiary,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.textTertiary,
                              size: 20,
                            ),
                            suffixIcon: filter.searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchCtrl.clear();
                                      ref
                                          .read(jobFilterProvider.notifier)
                                          .setSearch('');
                                    },
                                    child: const Icon(Icons.clear_rounded,
                                        size: 18,
                                        color: AppColors.textTertiary),
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _showFilterSheet(context),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: filter.hasActiveFilters
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: filter.hasActiveFilters
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: filter.hasActiveFilters
                                ? Colors.white
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tabs
                  TabBar(
                    controller: _tabCtrl,
                    labelStyle: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    unselectedLabelStyle:
                        GoogleFonts.inter(fontSize: 13),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: AppColors.border,
                    tabs: [
                      Tab(
                        text: filteredAsync.hasValue
                            ? 'All Jobs (${filteredAsync.value!.length})'
                            : 'All Jobs',
                      ),
                      const Tab(text: 'Saved'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Tab content ──────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // All jobs tab
                  filteredAsync.when(
                    data: (jobs) => jobs.isEmpty
                        ? _emptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                            itemCount: jobs.length,
                            itemBuilder: (_, i) {
                              final job = jobs[i];
                              final isBookmarked =
                                  bookmarkedIds.contains(job.id);
                              return JobCardWidget(
                                job: job,
                                isBookmarked: isBookmarked,
                                onTap: () => _openDetail(context, job),
                                onBookmark: () => _toggleBookmark(
                                    job.id, isBookmarked, user?.uid),
                              );
                            },
                          ),
                    loading: () => _shimmerList(),
                    error: (e, _) => _errorState(e.toString()),
                  ),

                  // Saved jobs tab
                  _SavedJobsTab(
                    uid: user?.uid,
                    onTap: (job) => _openDetail(context, job),
                    onBookmark: (jobId) =>
                        _toggleBookmark(jobId, true, user?.uid),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const JobFilterSheet(),
    );
  }

  void _openDetail(BuildContext context, job) {
    context.push(AppRoutes.jobDetail, extra: job);
  }

  void _toggleBookmark(String jobId, bool isBookmarked, String? uid) {
    if (uid == null) return;
    ref
        .read(bookmarkNotifierProvider.notifier)
        .toggle(jobId, isBookmarked);
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.work_off_outlined,
                    size: 40, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 20),
              Text(
                'No jobs found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search or filters to find more opportunities.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _errorState(String msg) => Center(
        child: Text('Error: $msg',
            style: GoogleFonts.inter(color: AppColors.error)));

  Widget _shimmerList() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        itemCount: 5,
        itemBuilder: (_, e) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
}

// ── Saved jobs tab ─────────────────────────────────────────────────────────────
class _SavedJobsTab extends ConsumerWidget {
  final String? uid;
  final void Function(dynamic job) onTap;
  final void Function(String jobId) onBookmark;

  const _SavedJobsTab(
      {this.uid, required this.onTap, required this.onBookmark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (uid == null) {
      return Center(
          child: Text('Sign in to see saved jobs',
              style: GoogleFonts.inter(color: AppColors.textSecondary)));
    }

    return FutureBuilder(
      future: ref.read(jobRepositoryProvider).fetchBookmarkedJobs(uid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final jobs = snapshot.data ?? [];
        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bookmark_border_rounded,
                    size: 60, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                Text('No saved jobs',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    )),
                const SizedBox(height: 8),
                Text('Bookmark jobs to find them here later',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textTertiary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          itemCount: jobs.length,
          itemBuilder: (_, i) => JobCardWidget(
            job: jobs[i],
            isBookmarked: true,
            onTap: () => onTap(jobs[i]),
            onBookmark: () => onBookmark(jobs[i].id),
          ),
        );
      },
    );
  }
}
