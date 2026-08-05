import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/enums.dart';

export '../data/enums.dart' show SchoolKind;

/// Ephemeral School screen UI (activity kind filter).
class SchoolUiState {
  const SchoolUiState({this.filter = SchoolKind.all});

  final SchoolKind filter;

  SchoolUiState copyWith({SchoolKind? filter}) {
    return SchoolUiState(filter: filter ?? this.filter);
  }
}

class SchoolUiController extends StateNotifier<SchoolUiState> {
  SchoolUiController() : super(const SchoolUiState());

  void setFilter(SchoolKind filter) {
    state = state.copyWith(filter: filter);
  }
}

final schoolUiProvider =
    StateNotifierProvider.autoDispose<SchoolUiController, SchoolUiState>(
  (ref) => SchoolUiController(),
);
