import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/calendar_view_math.dart';
import '../data/enums.dart';
import '../providers/providers.dart';

export '../data/enums.dart' show CalendarBrowseMode, CalendarMemberFilter;

/// Ephemeral Calendar screen UI (selected day, member filter, browse mode,
/// search). Owns the search [TextEditingController] so the screen can stay a
/// plain [ConsumerWidget].
class CalendarUiState {
  CalendarUiState({
    DateTime? selected,
    this.memberFilter = CalendarMemberFilter.all,
    this.mode = CalendarBrowseMode.month,
    this.searchQuery = '',
    this.searchOpen = false,
  }) : selected = calendarDateOnly(selected ?? DateTime.now());

  final DateTime selected;
  final CalendarMemberFilter memberFilter;
  final CalendarBrowseMode mode;
  final String searchQuery;
  final bool searchOpen;

  CalendarUiState copyWith({
    DateTime? selected,
    CalendarMemberFilter? memberFilter,
    CalendarBrowseMode? mode,
    String? searchQuery,
    bool? searchOpen,
  }) {
    return CalendarUiState(
      selected: selected ?? this.selected,
      memberFilter: memberFilter ?? this.memberFilter,
      mode: mode ?? this.mode,
      searchQuery: searchQuery ?? this.searchQuery,
      searchOpen: searchOpen ?? this.searchOpen,
    );
  }
}

class CalendarUiController extends StateNotifier<CalendarUiState> {
  CalendarUiController() : super(CalendarUiState());

  final searchController = TextEditingController();
  final searchFocus = FocusNode();

  bool _focusDrainScheduled = false;

  void selectDay(DateTime day) {
    state = state.copyWith(selected: calendarDateOnly(day));
  }

  void goToday() {
    state = state.copyWith(selected: calendarDateOnly(DateTime.now()));
  }

  void shiftBrowse(int delta) {
    state = state.copyWith(
      selected: switch (state.mode) {
        CalendarBrowseMode.month => shiftMonth(state.selected, delta),
        CalendarBrowseMode.week => shiftWeek(state.selected, delta),
        CalendarBrowseMode.agenda => shiftDay(state.selected, delta),
      },
    );
  }

  void setMode(CalendarBrowseMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setMemberFilter(CalendarMemberFilter filter) {
    state = state.copyWith(memberFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void openSearch() {
    if (state.searchOpen) {
      searchFocus.requestFocus();
      return;
    }
    state = state.copyWith(searchOpen: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!searchFocus.hasFocus) searchFocus.requestFocus();
    });
  }

  void closeSearch() {
    searchFocus.unfocus();
    searchController.clear();
    state = state.copyWith(searchOpen: false, searchQuery: '');
  }

  void clearSearch() {
    searchController.clear();
    setSearchQuery('');
  }

  /// Moves the selection to [focus]'s day. Returns the event id to open
  /// (if any) so the caller can show the edit sheet.
  String? consumeFocus(CalendarFocus focus) {
    selectDay(focus.day);
    return focus.eventId;
  }

  /// Guards against draining the same pending [CalendarFocus] twice when a
  /// value is already set before this screen's `ref.listen` is registered
  /// (e.g. a deep link that arrives on the very first frame).
  bool beginFocusDrain(CalendarFocus? pending) {
    if (_focusDrainScheduled || pending == null) return false;
    _focusDrainScheduled = true;
    return true;
  }

  void endFocusDrain() {
    _focusDrainScheduled = false;
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }
}

final calendarUiProvider =
    StateNotifierProvider.autoDispose<CalendarUiController, CalendarUiState>((
      ref,
    ) {
      return CalendarUiController();
    });
