import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom-nav index for [RecruiterHomeScreen] (0 = Dashboard … 2 = My Jobs).
class RecruiterTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final recruiterTabIndexProvider =
    NotifierProvider<RecruiterTabNotifier, int>(RecruiterTabNotifier.new);
