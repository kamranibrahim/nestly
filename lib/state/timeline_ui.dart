import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/timeline_nav.dart';

/// Ephemeral Timeline screen UI (module filter).
class TimelineUiState {
  const TimelineUiState({this.filter = TimelineModule.all});

  final TimelineModule filter;

  TimelineUiState copyWith({TimelineModule? filter}) {
    return TimelineUiState(filter: filter ?? this.filter);
  }
}

class TimelineUiController extends StateNotifier<TimelineUiState> {
  TimelineUiController() : super(const TimelineUiState());

  void setFilter(TimelineModule filter) {
    state = state.copyWith(filter: filter);
  }

  void showAll() => setFilter(TimelineModule.all);
}

final timelineUiProvider =
    StateNotifierProvider.autoDispose<TimelineUiController, TimelineUiState>(
  (ref) => TimelineUiController(),
);
