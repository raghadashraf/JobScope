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
  final String locationFilter;
  final double? minSalary;
  final double? maxSalary;

  const JobFilterState({
    this.searchQuery = '',
    this.selectedSkills = const [],
    this.locationFilter = '',
    this.minSalary,
    this.maxSalary,
  });

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedSkills.isNotEmpty ||
      locationFilter.isNotEmpty ||
      minSalary != null ||
      maxSalary != null;

  JobFilterState copyWith({
    String? searchQuery,
    List<String>? selectedSkills,
    String? locationFilter,
    double? minSalary,
    double? maxSalary,
    bool clearSalary = false,
  }) =>
      JobFilterState(
        searchQuery: searchQuery ?? this.searchQuery,
        selectedSkills: selectedSkills ?? this.selectedSkills,
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
