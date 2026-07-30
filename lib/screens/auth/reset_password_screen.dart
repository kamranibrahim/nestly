import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_errors.dart';
import '../../providers/providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shimmer.dart';

/// Sends a Firebase password-reset email.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final TextEditingController _email;
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter the email for your Nestly account.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          if (_sent) ...[
            NestStatusCard(
              icon: Icons.mark_email_read_outlined,
              title: 'Check your inbox',
              body:
                  'If an account exists for ${_email.text.trim()}, you’ll get a reset link shortly. Open it on this device or any browser, then log in with your new password.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to log in'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _sent = false;
                        _error = null;
                      }),
              child: const Text('Use a different email'),
            ),
          ] else ...[
            TextField(
              controller: _email,
              autofocus: widget.initialEmail.isEmpty,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _send,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _busy
                  ? const NestShimmerCircle(size: 22)
                  : const Text('Send reset link'),
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

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = _current.text;
    final next = _next.text;
    final confirm = _confirm.text;
    if (current.isEmpty || next.isEmpty) {
      setState(() => _error = 'Fill in your current and new password.');
      return;
    }
    if (next != confirm) {
      setState(() => _error = 'New passwords don’t match.');
      return;
    }
    if (next.trim().length < 6) {
      setState(() => _error = 'Use a password with at least 6 characters.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: current,
            newPassword: next,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            controller: _current,
            obscureText: _obscure,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _next,
            obscureText: _obscure,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirm,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: 'Confirm new password',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const NestShimmerCircle(size: 22)
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
