import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ephemeral Onboarding screen UI (current page index, finishing flag). The
/// [PageController] lives here rather than in the screen so `OnboardingScreen`
/// can stay a plain `ConsumerWidget`; it is disposed with the controller.
class OnboardingUiState {
  const OnboardingUiState({this.index = 0, this.finishing = false});

  final int index;
  final bool finishing;

  OnboardingUiState copyWith({int? index, bool? finishing}) {
    return OnboardingUiState(
      index: index ?? this.index,
      finishing: finishing ?? this.finishing,
    );
  }
}

class OnboardingUiController extends StateNotifier<OnboardingUiState> {
  OnboardingUiController() : super(const OnboardingUiState());

  final pageController = PageController();

  void setIndex(int index) {
    if (index == state.index) return;
    state = state.copyWith(index: index);
  }

  void setFinishing(bool value) {
    state = state.copyWith(finishing: value);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}

final onboardingUiProvider = StateNotifierProvider.autoDispose<
    OnboardingUiController, OnboardingUiState>((ref) {
  return OnboardingUiController();
});
