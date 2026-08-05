import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ephemeral Expenses screen UI — just the main-screen search query. Owns
/// the search [TextEditingController] so the screen can stay a plain
/// [ConsumerWidget].
class ExpensesUiState {
  const ExpensesUiState({this.searchQuery = ''});

  final String searchQuery;

  ExpensesUiState copyWith({String? searchQuery}) {
    return ExpensesUiState(searchQuery: searchQuery ?? this.searchQuery);
  }
}

class ExpensesUiController extends StateNotifier<ExpensesUiState> {
  ExpensesUiController() : super(const ExpensesUiState());

  final searchController = TextEditingController();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearch() {
    searchController.clear();
    setSearchQuery('');
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

final expensesUiProvider =
    StateNotifierProvider.autoDispose<ExpensesUiController, ExpensesUiState>((
      ref,
    ) {
      return ExpensesUiController();
    });
