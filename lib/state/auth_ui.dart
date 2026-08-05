import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ephemeral Auth screen UI. Owns the [TextEditingController]s so
/// [AuthScreen] can stay a plain `ConsumerWidget`.
class AuthUiState {
  const AuthUiState({
    this.signUp = false,
    this.busy = false,
    this.obscure = true,
    this.error,
  });

  final bool signUp;
  final bool busy;
  final bool obscure;
  final String? error;

  AuthUiState copyWith({
    bool? signUp,
    bool? busy,
    bool? obscure,
    String? error,
    bool clearError = false,
  }) {
    return AuthUiState(
      signUp: signUp ?? this.signUp,
      busy: busy ?? this.busy,
      obscure: obscure ?? this.obscure,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthUiController extends StateNotifier<AuthUiState> {
  AuthUiController() : super(const AuthUiState());

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  void toggleSignUp() {
    state = state.copyWith(signUp: !state.signUp, clearError: true);
  }

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

  /// Returns a validation message, or `null` when the form is ready to submit.
  String? validate() {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || !email.contains('@')) {
      return 'Enter a valid email address.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (state.signUp && nameController.text.trim().isEmpty) {
      return 'Enter your name.';
    }
    return null;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }
}

final authUiProvider =
    StateNotifierProvider.autoDispose<AuthUiController, AuthUiState>((ref) {
  return AuthUiController();
});

/// Ephemeral Nest-setup screen UI. Owns the [TextEditingController]s so
/// `NestSetupScreen` can stay a plain `ConsumerWidget`.
class NestSetupUiState {
  const NestSetupUiState({
    this.joining = false,
    this.busy = false,
    this.error,
  });

  final bool joining;
  final bool busy;
  final String? error;

  NestSetupUiState copyWith({
    bool? joining,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return NestSetupUiState(
      joining: joining ?? this.joining,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NestSetupUiController extends StateNotifier<NestSetupUiState> {
  NestSetupUiController() : super(const NestSetupUiState());

  final nestNameController = TextEditingController(text: 'Our Nest');
  final memberNameController = TextEditingController();
  final inviteCodeController = TextEditingController();

  void toggleJoining() {
    state = state.copyWith(joining: !state.joining, clearError: true);
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
    nestNameController.dispose();
    memberNameController.dispose();
    inviteCodeController.dispose();
    super.dispose();
  }
}

final nestSetupUiProvider = StateNotifierProvider.autoDispose<
    NestSetupUiController, NestSetupUiState>((ref) {
  return NestSetupUiController();
});
