import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/enums.dart';

/// Ephemeral Vault screen UI (folder, search, multi-select, retry busy).
class VaultUiState {
  const VaultUiState({
    this.category = VaultFolder.allLabel,
    this.query = '',
    this.selecting = false,
    this.selectedIds = const <String>{},
    this.retrying = false,
  });

  final String category;
  final String query;
  final bool selecting;
  final Set<String> selectedIds;
  final bool retrying;

  bool get canPopRoute => !selecting && VaultFolder.isAll(category);

  VaultUiState copyWith({
    String? category,
    String? query,
    bool? selecting,
    Set<String>? selectedIds,
    bool? retrying,
  }) {
    return VaultUiState(
      category: category ?? this.category,
      query: query ?? this.query,
      selecting: selecting ?? this.selecting,
      selectedIds: selectedIds ?? this.selectedIds,
      retrying: retrying ?? this.retrying,
    );
  }
}

class VaultUiController extends StateNotifier<VaultUiState> {
  VaultUiController({String initialCategory = VaultFolder.allLabel})
      : super(VaultUiState(category: initialCategory));

  bool _initialApplied = false;

  /// One-shot: applies a screen-route `initialCategory` argument (e.g. from
  /// deep-linking into a specific folder) without re-applying on every
  /// rebuild once the user has navigated elsewhere.
  void applyInitialCategory(String category) {
    if (_initialApplied) return;
    _initialApplied = true;
    if (!VaultFolder.isAll(category) && category != state.category) {
      setCategory(category);
    }
  }

  void setCategory(String category) {
    state = state.copyWith(category: category);
  }

  void showAllFolders() => setCategory(VaultFolder.allLabel);

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void startSelecting({String? seedId}) {
    final ids = Set<String>.from(state.selectedIds);
    if (seedId != null) ids.add(seedId);
    state = state.copyWith(selecting: true, selectedIds: ids);
  }

  void cancelSelecting() {
    state = state.copyWith(selecting: false, selectedIds: const {});
  }

  void toggleSelected(String id) {
    final ids = Set<String>.from(state.selectedIds);
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    state = state.copyWith(selectedIds: ids);
  }

  void setRetrying(bool value) {
    state = state.copyWith(retrying: value);
  }

  /// System / AppBar back: exit select → folder All → allow route pop.
  bool handleBack() {
    if (state.selecting) {
      cancelSelecting();
      return true;
    }
    if (!VaultFolder.isAll(state.category)) {
      showAllFolders();
      return true;
    }
    return false;
  }
}

final vaultUiProvider =
    StateNotifierProvider.autoDispose<VaultUiController, VaultUiState>((ref) {
  return VaultUiController();
});
