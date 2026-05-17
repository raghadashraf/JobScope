import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/job_model.dart';
import '../../../data/repositories/job_repository.dart';
import '../../auth/data/auth_providers.dart';

// ─── Repository provider ──────────────────────────────────────────────────────
final jobRepositoryProvider =
    Provider<JobRepository>((_) => JobRepository());

// ─── Real-time jobs stream ────────────────────────────────────────────────────
final jobsStreamProvider = StreamProvider<List<JobModel>>((ref) {
  return ref.read(jobRepositoryProvider).jobsStream();
});

// ─── Bookmarks stream ─────────────────────────────────────────────────────────
final bookmarkedIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return Stream.value({});
  return ref.read(jobRepositoryProvider).bookmarkedJobIdsStream(user.uid);
});

// ─── Search + filter state ────────────────────────────────────────────────────
class JobFilterState {
  final String searchQuery;
  final List<String> selectedSkills;
  final List<String> selectedJobTypes;
  final String locationFilter;
  final double? minSalary;
  final double? maxSalary;

  const JobFilterState({
    this.searchQuery = '',
    this.selectedSkills = const [],
    this.selectedJobTypes = const [],
    this.locationFilter = '',
    this.minSalary,
    this.maxSalary,
  });

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedSkills.isNotEmpty ||
      selectedJobTypes.isNotEmpty ||
      locationFilter.isNotEmpty ||
      minSalary != null ||
      maxSalary != null;

  int get activeFilterCount {
    int count = 0;
    if (locationFilter.isNotEmpty) count++;
    if (selectedSkills.isNotEmpty) count++;
    if (selectedJobTypes.isNotEmpty) count++;
    if (minSalary != null || maxSalary != null) count++;
    return count;
  }

  JobFilterState copyWith({
    String? searchQuery,
    List<String>? selectedSkills,
    List<String>? selectedJobTypes,
    String? locationFilter,
    double? minSalary,
    double? maxSalary,
    bool clearSalary = false,
  }) =>
      JobFilterState(
        searchQuery: searchQuery ?? this.searchQuery,
        selectedSkills: selectedSkills ?? this.selectedSkills,
        selectedJobTypes: selectedJobTypes ?? this.selectedJobTypes,
        locationFilter: locationFilter ?? this.locationFilter,
        minSalary: clearSalary ? null : (minSalary ?? this.minSalary),
        maxSalary: clearSalary ? null : (maxSalary ?? this.maxSalary),
      );
}

// FIXED: Riverpod 3.x uses Notifier instead of StateNotifier
class JobFilterNotifier extends Notifier<JobFilterState> {
  @override
  JobFilterState build() => const JobFilterState();

  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void setLocation(String l) => state = state.copyWith(locationFilter: l);
  void setSkills(List<String> s) => state = state.copyWith(selectedSkills: s);
  void setJobTypes(List<String> t) => state = state.copyWith(selectedJobTypes: t);
  void setSalaryRange(double? min, double? max) =>
      state = state.copyWith(minSalary: min, maxSalary: max);
  void clearAll() => state = const JobFilterState();
}

// FIXED: NotifierProvider instead of StateNotifierProvider
final jobFilterProvider =
    NotifierProvider<JobFilterNotifier, JobFilterState>(JobFilterNotifier.new);

// ─── Filtered jobs (derived from stream + filters) ────────────────────────────
final filteredJobsProvider = Provider<AsyncValue<List<JobModel>>>((ref) {
  final jobsAsync = ref.watch(jobsStreamProvider);
  final filter = ref.watch(jobFilterProvider);

  return jobsAsync.whenData((jobs) {
    var result = jobs;

    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      result = result
          .where((j) =>
              j.title.toLowerCase().contains(q) ||
              j.company.toLowerCase().contains(q) ||
              j.location.toLowerCase().contains(q))
          .toList();
    }

    if (filter.locationFilter.isNotEmpty) {
      final l = filter.locationFilter.toLowerCase();
      result =
          result.where((j) => j.location.toLowerCase().contains(l)).toList();
    }

    if (filter.selectedSkills.isNotEmpty) {
      result = result.where((j) {
        final jobSkills = j.skills.map((s) => s.toLowerCase()).toSet();
        return filter.selectedSkills
            .any((s) => jobSkills.contains(s.toLowerCase()));
      }).toList();
    }

    if (filter.selectedJobTypes.isNotEmpty) {
      result = result
          .where((j) => filter.selectedJobTypes.contains(j.jobType))
          .toList();
    }

    if (filter.minSalary != null) {
      result = result
          .where(
              (j) => j.salaryMin == null || j.salaryMin! >= filter.minSalary!)
          .toList();
    }

    if (filter.maxSalary != null) {
      result = result
          .where(
              (j) => j.salaryMax == null || j.salaryMax! <= filter.maxSalary!)
          .toList();
    }

    return result;
  });
});

// ─── Bookmark toggle action ───────────────────────────────────────────────────
// FIXED: Riverpod 3.x uses Notifier instead of StateNotifier
class BookmarkNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> toggle(String jobId, bool currentlyBookmarked) async {
    state = true; // loading
    try {
      final repo = ref.read(jobRepositoryProvider);
      final user = ref.read(firebaseUserProvider).value;
      final uid = user?.uid ?? '';
      if (currentlyBookmarked) {
        await repo.removeBookmark(uid, jobId);
      } else {
        await repo.bookmarkJob(uid, jobId);
      }
    } finally {
      state = false;
    }
  }
}

// FIXED: NotifierProvider instead of StateNotifierProvider
final bookmarkNotifierProvider =
    NotifierProvider<BookmarkNotifier, bool>(BookmarkNotifier.new);

// ─── Saved jobs (reactive to bookmark changes) ────────────────────────────────
// Re-fetches the full JobModel list whenever the bookmarked IDs stream emits.
final savedJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return [];
  // Watching the IDs stream means this provider re-runs whenever bookmarks change.
  final ids = ref.watch(bookmarkedIdsProvider).value ?? {};
  if (ids.isEmpty) return [];
  final results = await Future.wait(
    ids.map((id) => ref.read(jobRepositoryProvider).fetchJob(id)),
  );
  return results.whereType<JobModel>().toList()
    ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
});

// ─── Single job real-time stream ──────────────────────────────────────────────
final singleJobProvider =
    StreamProvider.autoDispose.family<JobModel?, String>((ref, jobId) {
  return ref.read(jobRepositoryProvider).jobStream(jobId);
});

// ─── Paginated jobs state ─────────────────────────────────────────────────────
class PaginatedJobsState {
  final List<JobModel> jobs;
  final DocumentSnapshot? lastDoc;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const PaginatedJobsState({
    this.jobs = const [],
    this.lastDoc,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  PaginatedJobsState copyWith({
    List<JobModel>? jobs,
    DocumentSnapshot? lastDoc,
    bool? isLoading,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) =>
      PaginatedJobsState(
        jobs: jobs ?? this.jobs,
        lastDoc: lastDoc ?? this.lastDoc,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
      );
}

class PaginatedJobsNotifier extends Notifier<PaginatedJobsState> {
  @override
  PaginatedJobsState build() {
    loadFirstPage();
    return const PaginatedJobsState(isLoading: true);
  }

  Future<void> loadFirstPage() async {
    state = const PaginatedJobsState(isLoading: true);
    try {
      final page = await ref.read(jobRepositoryProvider).fetchJobs();
      state = PaginatedJobsState(
        jobs: page.jobs,
        lastDoc: page.lastDoc,
        hasMore: page.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = PaginatedJobsState(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await ref
          .read(jobRepositoryProvider)
          .fetchJobs(lastDoc: state.lastDoc);
      state = state.copyWith(
        jobs: [...state.jobs, ...page.jobs],
        lastDoc: page.lastDoc,
        hasMore: page.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void refresh() => loadFirstPage();
}

final paginatedJobsProvider =
    NotifierProvider<PaginatedJobsNotifier, PaginatedJobsState>(
        PaginatedJobsNotifier.new);
