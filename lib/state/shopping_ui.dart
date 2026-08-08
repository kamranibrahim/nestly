import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/enums.dart';
import '../data/repositories.dart';

export '../data/enums.dart' show ShoppingCategory, ShoppingListFilter;

/// Ephemeral Shopping screen UI (add-card category, search, filter, bought
/// section expansion). Owns the [TextEditingController]s / [FocusNode] used
/// by the screen so the widget itself can stay a plain [ConsumerWidget].
class ShoppingUiState {
  const ShoppingUiState({
    this.selectedListId = ShoppingRepository.defaultListId,
    this.addCategory = ShoppingCategory.general,
    this.searchQuery = '',
    this.filterCategory = ShoppingListFilter.all,
    this.boughtExpanded = false,
  });

  final String selectedListId;
  final ShoppingCategory addCategory;
  final String searchQuery;
  final ShoppingListFilter filterCategory;
  final bool boughtExpanded;

  ShoppingUiState copyWith({
    String? selectedListId,
    ShoppingCategory? addCategory,
    String? searchQuery,
    ShoppingListFilter? filterCategory,
    bool? boughtExpanded,
  }) {
    return ShoppingUiState(
      selectedListId: selectedListId ?? this.selectedListId,
      addCategory: addCategory ?? this.addCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      filterCategory: filterCategory ?? this.filterCategory,
      boughtExpanded: boughtExpanded ?? this.boughtExpanded,
    );
  }
}

class ShoppingUiController extends StateNotifier<ShoppingUiState> {
  ShoppingUiController() : super(const ShoppingUiState());

  final addController = TextEditingController();
  final searchController = TextEditingController();
  final addFocus = FocusNode();

  void setSelectedListId(String listId) {
    state = state.copyWith(selectedListId: listId);
  }

  void setAddCategory(ShoppingCategory category) {
    state = state.copyWith(addCategory: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilterCategory(ShoppingListFilter category) {
    state = state.copyWith(filterCategory: category);
  }

  void toggleBoughtExpanded() {
    state = state.copyWith(boughtExpanded: !state.boughtExpanded);
  }

  void clearAddField() {
    addController.clear();
  }

  void clearSearch() {
    searchController.clear();
    setSearchQuery('');
  }

  /// Trimmed text currently in the add field, or `null` when empty.
  String? submitName() {
    final name = addController.text.trim();
    return name.isEmpty ? null : name;
  }

  @override
  void dispose() {
    addController.dispose();
    searchController.dispose();
    addFocus.dispose();
    super.dispose();
  }
}

final shoppingUiProvider =
    StateNotifierProvider.autoDispose<ShoppingUiController, ShoppingUiState>((
      ref,
    ) {
      return ShoppingUiController();
    });
