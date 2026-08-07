import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_errors.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/providers.dart';
import '../../state/auth_ui.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../widgets/motion.dart';
import '../../widgets/shimmer.dart';
import 'reset_password_screen.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(authUiProvider);
    final ctrl = ref.read(authUiProvider.notifier);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
          children: [
            Appear(
              duration: AppMotion.slow,
              curve: AppMotion.springy,
              child: Center(
                child: Semantics(
                  label: l10n.appName,
                  image: true,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/brand/logos/casaio-logo-mark-plain.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            Appear(
              delay: const Duration(milliseconds: 60),
              child: Text(
                l10n.appName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Appear(
              delay: const Duration(milliseconds: 100),
              child: Text(
                ui.signUp ? l10n.authCreateAccount : l10n.authWelcomeBack,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Appear(
              delay: const Duration(milliseconds: 140),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (ui.signUp) ...[
                      TextField(
                        controller: ctrl.nameController,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                        decoration:
                            InputDecoration(labelText: l10n.authNameHint),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: ctrl.emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: l10n.authEmailHint),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ctrl.passwordController,
                      obscureText: ui.obscure,
                      autofillHints: [
                        ui.signUp
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.authPasswordHint,
                        suffixIcon: IconButton(
                          tooltip: ui.obscure
                              ? l10n.authShowPassword
                              : l10n.authHidePassword,
                          onPressed: ctrl.toggleObscure,
                          icon: Icon(
                            ui.obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _submit(context, ref),
                    ),
                    if (!ui.signUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: ui.busy
                              ? null
                              : () => _openResetPassword(context, ref),
                          child: Text(l10n.authForgotPassword),
                        ),
                      ),
                    if (ui.error != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        ui.error!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: ui.busy ? null : () => _submit(context, ref),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppColors.primary,
                      ),
                      child: ui.busy
                          ? Semantics(
                              label: l10n.authWorking,
                              child: const SizedBox(
                                width: 22,
                                height: 22,
                                child: NestShimmerCircle(size: 22),
                              ),
                            )
                          : Text(ui.signUp ? l10n.authSignUpShort : l10n.authLogIn),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: ui.busy ? null : ctrl.toggleSignUp,
                      child: Text(
                        ui.signUp
                            ? l10n.authHaveAccountLogin
                            : l10n.authNeedAccountSignup,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _submit(BuildContext context, WidgetRef ref) async {
  final ctrl = ref.read(authUiProvider.notifier);
  if (kDebugMode && ctrl.emailController.text.isEmpty) {
    ctrl.emailController.text = 'devtime3@gmail.com';
    ctrl.passwordController.text = '12345678';
  }
  final validation = ctrl.validate(context.l10n);
  if (validation != null) {
    ctrl.setError(validation);
    return;
  }
  ctrl.setBusy(true);
  ctrl.setError(null);
  try {
    final auth = ref.read(authRepositoryProvider);
    final signUp = ref.read(authUiProvider).signUp;
    if (signUp) {
      await auth.signUp(
        email: ctrl.emailController.text.trim(),
        password: ctrl.passwordController.text,
        displayName: ctrl.nameController.text.trim().isEmpty
            ? 'Parent'
            : ctrl.nameController.text.trim(),
      );
    } else {
      await auth.signIn(
        email: ctrl.emailController.text.trim(),
        password: ctrl.passwordController.text,
      );
    }
  } catch (e) {
    if (context.mounted) {
      ctrl.setError(friendlyAuthError(e, context.l10n));
    } else {
      ctrl.setError(friendlyAuthError(e));
    }
  } finally {
    ctrl.setBusy(false);
  }
}

void _openResetPassword(BuildContext context, WidgetRef ref) {
  final email = ref.read(authUiProvider.notifier).emailController.text.trim();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ResetPasswordScreen(initialEmail: email),
    ),
  );
}
