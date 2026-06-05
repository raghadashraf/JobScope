import 'package:flutter_riverpod/flutter_riverpod.dart';

class _TabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

/// Write to switch the candidate bottom-nav tab from anywhere in the tree.
final candidateTabProvider =
    NotifierProvider<_TabNotifier, int>(_TabNotifier.new);

class _RecruiterTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

/// Write to switch the recruiter bottom-nav tab from anywhere in the tree.
final recruiterTabProvider =
    NotifierProvider<_RecruiterTabNotifier, int>(_RecruiterTabNotifier.new);
