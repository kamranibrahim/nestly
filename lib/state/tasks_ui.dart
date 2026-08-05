import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';

/// Ephemeral Tasks screen UI (assignee filter, search). Owns the search
/// [TextEditingController] so the screen can stay a plain [ConsumerWidget].
class TasksUiState {
  const TasksUiState({this.assigneeFilterId, this.searchQuery = ''});

  /// `null` = all members; otherwise filter by assignee id.
  final String? assigneeFilterId;
  final String searchQuery;

  TasksUiState copyWith({
    String? assigneeFilterId,
    bool clearAssigneeFilter = false,
    String? searchQuery,
  }) {
    return TasksUiState(
      assigneeFilterId: clearAssigneeFilter
          ? null
          : (assigneeFilterId ?? this.assigneeFilterId),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TasksUiController extends StateNotifier<TasksUiState> {
  TasksUiController() : super(const TasksUiState());

  final searchController = TextEditingController();

  void setAssigneeFilter(String? memberId) {
    if (memberId == null) {
      state = state.copyWith(clearAssigneeFilter: true);
      return;
    }
    state = state.copyWith(
      assigneeFilterId: state.assigneeFilterId == memberId ? null : memberId,
      clearAssigneeFilter: state.assigneeFilterId == memberId,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearch() {
    searchController.clear();
    setSearchQuery('');
  }

  /// Drops the assignee filter if that member is no longer in [members].
  void clearAssigneeIfMissing(List<NestMember> members) {
    final id = state.assigneeFilterId;
    if (id == null) return;
    final stillExists = members.any((m) => m.id == id);
    if (!stillExists) {
      state = state.copyWith(clearAssigneeFilter: true);
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

final tasksUiProvider =
    StateNotifierProvider.autoDispose<TasksUiController, TasksUiState>((ref) {
      return TasksUiController();
    });
