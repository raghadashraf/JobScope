import 'package:flutter_riverpod/flutter_riverpod.dart';

class CandidateTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final candidateTabProvider =
    NotifierProvider<CandidateTabNotifier, int>(CandidateTabNotifier.new);

class ApplicationsTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final applicationsTabProvider =
    NotifierProvider<ApplicationsTabNotifier, int>(ApplicationsTabNotifier.new);
