import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_errors.dart';
import '../data/db/app_database.dart';
import '../data/nest_privacy_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/shimmer.dart';

final nestPrivacyServiceProvider = Provider<NestPrivacyService>((ref) {
  return NestPrivacyService(ref.watch(databaseProvider));
});

/// Confirms deletion with password, then removes the Firebase account + local data.
Future<void> confirmAndDeleteAccount(
  BuildContext context,
  WidgetRef ref,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You need to be signed in.')),
    );
    return;
  }

  final password = await showDialog<String>(
    context: context,
    builder: (context) => const _DeleteAccountDialog(),
  );
  if (password == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    const SnackBar(content: Text('Deleting account…')),
  );

  try {
    await ref.read(nestPrivacyServiceProvider).deleteAccount(password: password);
    messenger.hideCurrentSnackBar();
  } catch (e) {
    messenger.hideCurrentSnackBar();
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(friendlyAuthError(e))),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'your account';

    return AlertDialog(
      title: const Text('Delete account?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This removes $email from your nest, deletes your Nestly '
              'account, and clears data on this device. Other family members '
              'keep the nest. This cannot be undone.',
              style: const TextStyle(height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: _obscure,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _confirm(),
              decoration: InputDecoration(
                labelText: 'Confirm with password',
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _confirm,
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Delete forever'),
        ),
      ],
    );
  }

  void _confirm() {
    final password = _password.text;
    if (password.isEmpty) return;
    Navigator.pop(context, password);
  }
}

/// In-app privacy summary for store closed testing / review.
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await ref.read(nestPrivacyServiceProvider).shareExport();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export ready to share')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    setState(() => _busy = true);
    try {
      await confirmAndDeleteAccount(context, ref);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 24),
        children: [
          const NestCard(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nestly keeps household data private by default.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'What we store',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Account email, nest membership, tasks, lists, calendar, '
                  'expenses, bills, emergency notes, vault file metadata, and '
                  'family timeline events. Vault files upload to Firebase Storage '
                  'under your nest when you are online.',
                  style: TextStyle(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'How it syncs',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Nestly is offline-first. Data lives on your device in SQLite '
                  '(Drift) and syncs to Firebase when signed in and connected. '
                  'Only nest members can read or write nest data.',
                  style: TextStyle(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Quiet AI (optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Document scan sends the photo or PDF you choose to Google’s '
                  'Gemini models through Firebase AI Logic (Vertex AI) so Nestly '
                  'can draft an event, expense, bill, or task. You review before '
                  'anything is saved. Nestly stays free — there is no paywall '
                  'for core family features.',
                  style: TextStyle(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'We may register a push token for reminders (for example bills). '
                  'You can revoke notification permission in system settings.',
                  style: TextStyle(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Contact',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Questions: privacy@nestly.app — or open '
                  'https://glowing-strudel-442ff8.netlify.app/privacy',
                  style: TextStyle(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const SectionLabel('Your controls'),
          NestCard(
            onTap: _busy ? null : _export,
            child: Row(
              children: [
                const Icon(Icons.download_rounded, color: AppColors.accentDeep),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Export nest data',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: NestShimmerCircle(size: 18),
                  )
                else
                  const Icon(
                    Icons.ios_share_rounded,
                    color: AppColors.inkMuted,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          NestCard(
            onTap: _busy ? null : _deleteAccount,
            child: const Row(
              children: [
                Icon(Icons.delete_forever_rounded, color: AppColors.danger),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete account',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Requires your password. Cannot be undone.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.inkMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
