import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/auth_errors.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/providers.dart';
import '../../state/reset_password_ui.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shimmer.dart';

const _supportEmail = 'support@casaio.app';

Future<void> _send(
  WidgetRef ref,
  AppLocalizations l10n, {
  bool isResend = false,
}) async {
  final ctrl = ref.read(resetPasswordUiProvider.notifier);
  final email = ctrl.emailController.text.trim();
  if (email.isEmpty) {
    ctrl.setError(l10n.resetEnterEmail);
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
    ctrl.setError(friendlyAuthError(e, l10n));
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
      'subject': context.l10n.resetMailSubject,
      if (email.isNotEmpty) 'body': context.l10n.resetMailBody(email),
    },
  );
  final ok = await launchUrl(uri);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.resetEmailSupport)),
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
    final l10n = context.l10n;
    if (initialEmail.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ctrl.applyInitialEmail(initialEmail);
      });
    }
    final wait = ui.secondsUntilResend;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.resetPasswordTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            l10n.resetPasswordIntro,
            style: const TextStyle(
              color: AppColors.inkSecondary,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          if (ui.sent) ...[
            NestStatusCard(
              icon: Icons.mark_email_read_outlined,
              title: l10n.resetCheckInbox,
              body: l10n.resetCheckInboxBody(ctrl.emailController.text.trim()),
            ),
            const SizedBox(height: 12),
            NestStatusCard(
              icon: Icons.markunread_mailbox_outlined,
              title: l10n.resetDontSee,
              body: l10n.resetDontSeeBody,
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
              child: Text(l10n.resetBackToLogin),
            ),
            TextButton(
              onPressed:
                  ui.canResend ? () => _send(ref, l10n, isResend: true) : null,
              child: Text(
                wait > 0 ? l10n.resetResendIn(wait) : l10n.resetResend,
              ),
            ),
            TextButton(
              onPressed: ui.busy ? null : ctrl.useAnotherEmail,
              child: Text(l10n.resetUseOtherEmail),
            ),
            TextButton.icon(
              onPressed: () => _emailSupport(context, ref),
              icon: const Icon(Icons.mail_outline_rounded, size: 18),
              label: Text(l10n.resetEmailSupport),
            ),
          ] else ...[
            TextField(
              controller: ctrl.emailController,
              autofocus: initialEmail.isEmpty,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _send(ref, l10n),
              decoration: InputDecoration(labelText: l10n.authEmailHint),
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
              onPressed: ui.busy ? null : () => _send(ref, l10n),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: ui.busy
                  ? Semantics(
                      label: l10n.authWorking,
                      child: const NestShimmerCircle(size: 22),
                    )
                  : Text(l10n.resetSendLink),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _emailSupport(context, ref),
              icon: const Icon(Icons.mail_outline_rounded, size: 18),
              label: Text(l10n.resetEmailSupport),
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
      SnackBar(content: Text(context.l10n.resetPasswordUpdated)),
    );
  }
}

Future<void> _saveChangedPassword(BuildContext context, WidgetRef ref) async {
  final ctrl = ref.read(changePasswordUiProvider.notifier);
  final current = ctrl.currentController.text;
  final next = ctrl.nextController.text;
  final confirm = ctrl.confirmController.text;
  if (current.isEmpty || next.isEmpty) {
    ctrl.setError(context.l10n.resetFillBoth);
    return;
  }
  if (next != confirm) {
    ctrl.setError(context.l10n.resetMismatch);
    return;
  }
  if (next.trim().length < 6) {
    ctrl.setError(context.l10n.authPasswordTooShort);
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
    ctrl.setError(
      friendlyAuthError(e, context.mounted ? context.l10n : null),
    );
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
    final l10n = context.l10n;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final email = FirebaseAuth.instance.currentUser?.email ?? l10n.yourAccount;

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
          Text(
            l10n.settingsPassword,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
            decoration: InputDecoration(labelText: l10n.authPasswordHint),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: ctrl.nextController,
            obscureText: ui.obscure,
            decoration: InputDecoration(labelText: l10n.authPasswordHint),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: ctrl.confirmController,
            obscureText: ui.obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveChangedPassword(context, ref),
            decoration: InputDecoration(
              labelText: l10n.authPasswordHint,
              suffixIcon: IconButton(
                onPressed: ctrl.toggleObscure,
                tooltip: ui.obscure
                    ? l10n.authShowPassword
                    : l10n.authHidePassword,
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
                    label: l10n.authWorking,
                    child: const NestShimmerCircle(size: 22),
                  )
                : Text(l10n.commonSave),
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
