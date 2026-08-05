import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ephemeral Privacy screen UI (export/delete busy flag). The delete-account
/// password confirmation dialog stays a local `StatefulWidget` since it only
/// owns a single `TextEditingController` with its own obscure-toggle state.
class PrivacyUiState {
  const PrivacyUiState({this.busy = false});

  final bool busy;

  PrivacyUiState copyWith({bool? busy}) {
    return PrivacyUiState(busy: busy ?? this.busy);
  }
}

class PrivacyUiController extends StateNotifier<PrivacyUiState> {
  PrivacyUiController() : super(const PrivacyUiState());

  void setBusy(bool value) {
    state = state.copyWith(busy: value);
  }
}

final privacyUiProvider =
    StateNotifierProvider.autoDispose<PrivacyUiController, PrivacyUiState>((
  ref,
) {
  return PrivacyUiController();
});
