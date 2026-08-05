import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/enums.dart';
import '../data/locator_models.dart';

export '../data/enums.dart' show LocatorFilter;

/// Ephemeral Locator screen UI (busy/error, my-location toggle, focused
/// member pin, freshness filter, bottom-sheet size, cached device position).
/// The map/sheet controllers themselves stay owned by [LocatorScreen]'s
/// [State] since they have their own animation/scroll lifecycle.
class LocatorUiState {
  const LocatorUiState({
    this.busy = false,
    this.showMyLocation = false,
    this.error,
    this.focusMemberId,
    this.filter = LocatorFilter.all,
    this.me,
    this.sheetSize = 0.36,
  });

  final bool busy;
  final bool showMyLocation;
  final String? error;

  /// `null` = no member pin focused (map shows everyone).
  final String? focusMemberId;
  final LocatorFilter filter;

  /// Cached device position, refreshed opportunistically.
  final ({double lat, double lng})? me;

  /// Current extent of the draggable bottom sheet (0..1).
  final double sheetSize;

  LocatorUiState copyWith({
    bool? busy,
    bool? showMyLocation,
    String? error,
    bool clearError = false,
    String? focusMemberId,
    bool clearFocusMemberId = false,
    LocatorFilter? filter,
    ({double lat, double lng})? me,
    bool clearMe = false,
    double? sheetSize,
  }) {
    return LocatorUiState(
      busy: busy ?? this.busy,
      showMyLocation: showMyLocation ?? this.showMyLocation,
      error: clearError ? null : (error ?? this.error),
      focusMemberId:
          clearFocusMemberId ? null : (focusMemberId ?? this.focusMemberId),
      filter: filter ?? this.filter,
      me: clearMe ? null : (me ?? this.me),
      sheetSize: sheetSize ?? this.sheetSize,
    );
  }
}

class LocatorUiController extends StateNotifier<LocatorUiState> {
  LocatorUiController() : super(const LocatorUiState());

  bool _didAutoFocus = false;

  void setShowMyLocation(bool value) {
    state = state.copyWith(showMyLocation: value);
  }

  void setMe(({double lat, double lng})? me) {
    state =
        me == null ? state.copyWith(clearMe: true) : state.copyWith(me: me);
  }

  /// Marks a share/sharing-toggle action as starting: busy on, clears any
  /// previous error.
  void beginAction() {
    state = state.copyWith(busy: true, clearError: true);
  }

  void setBusy(bool value) {
    state = state.copyWith(busy: value);
  }

  void setError(String message) {
    state = state.copyWith(error: message);
  }

  void setFocusMemberId(String? id) {
    state = id == null
        ? state.copyWith(clearFocusMemberId: true)
        : state.copyWith(focusMemberId: id);
  }

  void setFilter(LocatorFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSheetSize(double size) {
    if ((size - state.sheetSize).abs() <= 0.01) return;
    state = state.copyWith(sheetSize: size);
  }

  /// Auto-focuses the newest pin once, the first time locations arrive.
  void maybeAutoFocus(List<NestLocation> locations) {
    if (_didAutoFocus || state.focusMemberId != null || locations.isEmpty) {
      return;
    }
    _didAutoFocus = true;
    state = state.copyWith(focusMemberId: locations.first.memberId);
  }
}

final locatorUiProvider =
    StateNotifierProvider.autoDispose<LocatorUiController, LocatorUiState>((
  ref,
) {
  return LocatorUiController();
});
