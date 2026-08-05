import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/enums.dart';

export '../data/enums.dart' show CareCategory, CareViewMode;

/// Ephemeral Care screen UI (category filter, due/category view mode).
class CareUiState {
  const CareUiState({
    this.filter = CareCategory.all,
    this.viewMode = CareViewMode.due,
  });

  final CareCategory filter;
  final CareViewMode viewMode;

  CareUiState copyWith({CareCategory? filter, CareViewMode? viewMode}) {
    return CareUiState(
      filter: filter ?? this.filter,
      viewMode: viewMode ?? this.viewMode,
    );
  }
}

class CareUiController extends StateNotifier<CareUiState> {
  CareUiController() : super(const CareUiState());

  void setFilter(CareCategory filter) {
    state = state.copyWith(filter: filter);
  }

  void setViewMode(CareViewMode viewMode) {
    state = state.copyWith(viewMode: viewMode);
  }
}

final careUiProvider =
    StateNotifierProvider.autoDispose<CareUiController, CareUiState>(
  (ref) => CareUiController(),
);
