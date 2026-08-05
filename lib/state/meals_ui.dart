import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ephemeral Meals screen UI (focused weekday + one-shot entry handling).
class MealsUiState {
  const MealsUiState({required this.focusWeekday});

  final int focusWeekday;

  MealsUiState copyWith({int? focusWeekday}) {
    return MealsUiState(focusWeekday: focusWeekday ?? this.focusWeekday);
  }
}

class MealsUiController extends StateNotifier<MealsUiState> {
  MealsUiController() : super(MealsUiState(focusWeekday: DateTime.now().weekday));

  bool _entryConsumed = false;

  void setFocusWeekday(int weekday) {
    state = state.copyWith(focusWeekday: weekday);
  }

  /// One-shot gate for `MealsScreen.entry`: returns true exactly once per
  /// controller lifetime so the deep-link sheet (plan week / add dinner)
  /// only opens on the first build, not on every rebuild.
  bool consumeEntry() {
    if (_entryConsumed) return false;
    _entryConsumed = true;
    return true;
  }
}

final mealsUiProvider =
    StateNotifierProvider.autoDispose<MealsUiController, MealsUiState>(
  (ref) => MealsUiController(),
);
