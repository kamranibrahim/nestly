import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/auth_errors.dart';
import '../../providers/providers.dart';
import '../../state/reset_password_ui.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shimmer.dart';

const _supportEmail = 'support@nestly.app';

Future<void> _send(WidgetRef ref, {bool isResend = false}) async {
  final ctrl = ref.read(resetPasswordUiProvider.notifier);
  final email = ctrl.emailController.text.trim();
  if (email.isEmpty) {
    ctrl.setError('Enter the email for your Nestly account.');
    return;
  }
  if (isResend && !ref.read(resetPasswordUiProvider).canResend) return;

  ctrl.setBusy(true);
  ctrl.setError(null);
  try {
    await ref.read(authRepositoryProvider).sendPasswordReset(email);
    ctrl.setSent(true);
    ctrl.startCooldown();
  } catch (e) {
    ctrl.setError(friendlyAuthError(e));
  } finally {
    ctrl.setBusy(false);
  }
}

Future<void> _emailSupport(BuildContext context, WidgetRef ref) async {
  final email = ref.read(resetPasswordUiProvider.notifier).emailController.text.trim();
  final uri = Uri(
    scheme: 'mailto',
    path: _supportEmail,
    queryParameters: {
      'subject': 'Nestly password reset help',
      if (email.isNotEmpty) 'body': 'Account email: $email\n\n',
    },
  );
  final ok = await launchUrl(uri);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email support@nestly.app')),
    );
  }
}

/// Sends a Firebase password-reset email.
class ResetPasswordScreen extends ConsumerWidget {
  const ResetPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(resetPasswordUiProvider);
    final ctrl = ref.read(resetPasswordUiProvider.notifier);
    if (initialEmail.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ctrl.applyInitialEmail(initialEmail);
      });
    }
    final wait = ui.secondsUntilResend;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reset password')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text(
            'We’ll email you a secure link to choose a new password.',
            style: TextStyle(
              color: AppColors.inkSecondary,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          if (ui.sent) ...[
            NestStatusCard(
              icon: Icons.mark_email_read_outlined,
              title: 'Check your inbox',
              body:
                  'If an account exists for ${ctrl.emailController.text.trim()}, you’ll get a '
                  'reset link shortly. Open it on this device or any browser, '
                  'then log in with your new password.',
            ),
            const SizedBox(height: 12),
            NestStatusCard(
              icon: Icons.markunread_mailbox_outlined,
              title: 'Don’t see it?',
              body:
                  'Check Spam and Promotions (Gmail often files Firebase emails '
                  'there). Search for “Nestly” or “password”. Still signed in on '
                  'another device? Change your password from Nest → Change password '
                  'instead.',
            ),
            if (ui.error != null) ...[
              const SizedBox(height: 10),
              Text(
                ui.error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to log in'),
            ),
            TextButton(
              onPressed:
                  ui.canResend ? () => _send(ref, isResend: true) : null,
              child: Text(
                wait > 0 ? 'Resend link in ${wait}s' : 'Resend link',
              ),
            ),
            TextButton(
              onPressed: ui.busy ? null : ctrl.useAnotherEmail,
              child: const Text('Use a different email'),
            ),
            TextButton.icon(
              onPressed: () => _emailSupport(context, ref),
              icon: const Icon(Icons.mail_outline_rounded, size: 18),
              label: const Text('Email support'),
            ),
          ] else ...[
            TextField(
              controller: ctrl.emailController,
              autofocus: initialEmail.isEmpty,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _send(ref),
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            if (ui.error != null) ...[
              const SizedBox(height: 10),
              Text(
                ui.error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: ui.busy ? null : () => _send(ref),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: ui.busy
                  ? Semantics(
                      label: 'Sending',
                      child: const NestShimmerCircle(size: 22),
                    )
                  : const Text('Send reset link'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _emailSupport(context, ref),
              icon: const Icon(Icons.mail_outline_rounded, size: 18),
              label: const Text('Email support'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Change password while signed in (Nest → Account).
Future<void> showChangePasswordSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => const _ChangePasswordSheet(),
  );
  if (result == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated')),
    );
  }
}

Future<void> _saveChangedPassword(BuildContext context, WidgetRef ref) async {
  final ctrl = ref.read(changePasswordUiProvider.notifier);
  final current = ctrl.currentController.text;
  final next = ctrl.nextController.text;
  final confirm = ctrl.confirmController.text;
  if (current.isEmpty || next.isEmpty) {
    ctrl.setError('Fill in your current and new password.');
    return;
  }
  if (next != confirm) {
    ctrl.setError('New passwords don’t match.');
    return;
  }
  if (next.trim().length < 6) {
    ctrl.setError('Use a password with at least 6 characters.');
    return;
  }

  ctrl.setBusy(true);
  ctrl.setError(null);
  try {
    await ref.read(authRepositoryProvider).changePassword(
          currentPassword: current,
          newPassword: next,
        );
    if (!context.mounted) return;
    Navigator.pop(context, true);
  } catch (e) {
    ctrl.setError(friendlyAuthError(e));
  } finally {
    ctrl.setBusy(false);
  }
}

class _ChangePasswordSheet extends ConsumerWidget {
  const _ChangePasswordSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(changePasswordUiProvider);
    final ctrl = ref.read(changePasswordUiProvider.notifier);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final email = FirebaseAuth.instance.currentUser?.email ?? 'your account';

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Change password',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl.currentController,
            obscureText: ui.obscure,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: ctrl.nextController,
            obscureText: ui.obscure,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: ctrl.confirmController,
            obscureText: ui.obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveChangedPassword(context, ref),
            decoration: InputDecoration(
              labelText: 'Confirm new password',
              suffixIcon: IconButton(
                onPressed: ctrl.toggleObscure,
                icon: Icon(
                  ui.obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          if (ui.error != null) ...[
            const SizedBox(height: 10),
            Text(
              ui.error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: ui.busy ? null : () => _saveChangedPassword(context, ref),
            child: ui.busy
                ? Semantics(
                    label: 'Working',
                    child: const NestShimmerCircle(size: 22),
                  )
                : const Text('Update password'),
          ),
        ],
      ),
    );
  }
}

class NestStatusCard extends StatelessWidget {
  const NestStatusCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
