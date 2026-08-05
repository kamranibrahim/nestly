import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const resetPasswordResendCooldown = Duration(seconds: 45);

/// Ephemeral Reset-password screen UI (busy/sent/error, resend cooldown)
/// plus the email [TextEditingController]. `ResetPasswordScreen` stays a
/// plain `ConsumerWidget`.
class ResetPasswordUiState {
  const ResetPasswordUiState({
    this.busy = false,
    this.sent = false,
    this.error,
    this.nextResendAt,
    this.tick = 0,
  });

  final bool busy;
  final bool sent;
  final String? error;
  final DateTime? nextResendAt;

  /// Bumped by the cooldown ticker so the countdown label rebuilds every
  /// second even though [nextResendAt] itself doesn't change.
  final int tick;

  int get secondsUntilResend {
    final until = nextResendAt;
    if (until == null) return 0;
    final left = until.difference(DateTime.now()).inSeconds;
    return left < 0 ? 0 : left;
  }

  bool get canResend => secondsUntilResend == 0 && !busy;

  ResetPasswordUiState copyWith({
    bool? busy,
    bool? sent,
    String? error,
    bool clearError = false,
    DateTime? nextResendAt,
    bool clearNextResendAt = false,
    int? tick,
  }) {
    return ResetPasswordUiState(
      busy: busy ?? this.busy,
      sent: sent ?? this.sent,
      error: clearError ? null : (error ?? this.error),
      nextResendAt:
          clearNextResendAt ? null : (nextResendAt ?? this.nextResendAt),
      tick: tick ?? this.tick,
    );
  }
}

class ResetPasswordUiController extends StateNotifier<ResetPasswordUiState> {
  ResetPasswordUiController() : super(const ResetPasswordUiState());

  final emailController = TextEditingController();
  Timer? _cooldownTicker;
  bool _initialEmailApplied = false;

  /// One-shot: seeds the email field from a route argument (carried over
  /// from the log-in screen) without clobbering later user edits.
  void applyInitialEmail(String email) {
    if (_initialEmailApplied) return;
    _initialEmailApplied = true;
    if (email.isNotEmpty) emailController.text = email;
  }

  void setBusy(bool value) {
    state = state.copyWith(busy: value);
  }

  void setError(String? error) {
    state = error == null
        ? state.copyWith(clearError: true)
        : state.copyWith(error: error);
  }

  void setSent(bool value) {
    state = state.copyWith(sent: value);
  }

  /// Resets to the "enter email" step, e.g. after "Use a different email".
  void useAnotherEmail() {
    _cooldownTicker?.cancel();
    state = state.copyWith(
      sent: false,
      clearError: true,
      clearNextResendAt: true,
    );
  }

  void startCooldown() {
    _cooldownTicker?.cancel();
    state = state.copyWith(
      nextResendAt: DateTime.now().add(resetPasswordResendCooldown),
    );
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.secondsUntilResend == 0) {
        _cooldownTicker?.cancel();
      }
      state = state.copyWith(tick: state.tick + 1);
    });
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    emailController.dispose();
    super.dispose();
  }
}

final resetPasswordUiProvider = StateNotifierProvider.autoDispose<
    ResetPasswordUiController, ResetPasswordUiState>((ref) {
  return ResetPasswordUiController();
});

/// Ephemeral Change-password sheet UI (busy/obscure/error) plus its three
/// password [TextEditingController]s, so the sheet can stay a plain
/// `ConsumerWidget` instead of owning `State`.
class ChangePasswordUiState {
  const ChangePasswordUiState({
    this.busy = false,
    this.obscure = true,
    this.error,
  });

  final bool busy;
  final bool obscure;
  final String? error;

  ChangePasswordUiState copyWith({
    bool? busy,
    bool? obscure,
    String? error,
    bool clearError = false,
  }) {
    return ChangePasswordUiState(
      busy: busy ?? this.busy,
      obscure: obscure ?? this.obscure,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChangePasswordUiController extends StateNotifier<ChangePasswordUiState> {
  ChangePasswordUiController() : super(const ChangePasswordUiState());

  final currentController = TextEditingController();
  final nextController = TextEditingController();
  final confirmController = TextEditingController();

  void toggleObscure() {
    state = state.copyWith(obscure: !state.obscure);
  }

  void setBusy(bool value) {
    state = state.copyWith(busy: value);
  }

  void setError(String? error) {
    state = error == null
        ? state.copyWith(clearError: true)
        : state.copyWith(error: error);
  }

  @override
  void dispose() {
    currentController.dispose();
    nextController.dispose();
    confirmController.dispose();
    super.dispose();
  }
}

final changePasswordUiProvider = StateNotifierProvider.autoDispose<
    ChangePasswordUiController, ChangePasswordUiState>((ref) {
  return ChangePasswordUiController();
});
