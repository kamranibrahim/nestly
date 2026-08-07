import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_errors.dart';
import '../data/db/app_database.dart';
import '../data/nest_privacy_service.dart';
import '../l10n/l10n_ext.dart';
import '../state/privacy_ui.dart';
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
      SnackBar(content: Text(context.l10n.privacyNeedSignIn)),
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
    SnackBar(content: Text(context.l10n.privacyDeleting)),
  );

  try {
    await ref.read(nestPrivacyServiceProvider).deleteAccount(password: password);
    messenger.hideCurrentSnackBar();
  } catch (e) {
    messenger.hideCurrentSnackBar();
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(friendlyAuthError(e, context.l10n))),
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
    final l10n = context.l10n;
    final email = FirebaseAuth.instance.currentUser?.email ?? 'your account';

    return AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.privacyDeleteBody(email),
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
                labelText: l10n.privacyConfirmPassword,
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
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _confirm,
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          child: Text(l10n.privacyDeleteForever),
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

Future<void> _export(BuildContext context, WidgetRef ref) async {
  final ctrl = ref.read(privacyUiProvider.notifier);
  ctrl.setBusy(true);
  try {
    await ref.read(nestPrivacyServiceProvider).shareExport(l10n: context.l10n);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.privacyExportReady)),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.privacyExportFailed('$e'))),
    );
  } finally {
    ctrl.setBusy(false);
  }
}

Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
  final ctrl = ref.read(privacyUiProvider.notifier);
  ctrl.setBusy(true);
  try {
    await confirmAndDeleteAccount(context, ref);
  } finally {
    ctrl.setBusy(false);
  }
}

/// In-app privacy summary for store closed testing / review.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(privacyUiProvider).busy;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.screenPrivacyShort)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 36),
        children: [
          NestCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.privacyIntro,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.privacyStoreTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.privacyStoreBody,
                  style: const TextStyle(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.privacySyncTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.privacySyncBody,
                  style: const TextStyle(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.privacyAiTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.privacyAiBody,
                  style: const TextStyle(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.privacyDiagTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.privacyDiagBody,
                  style: const TextStyle(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.privacyResetTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.privacyResetBody,
                  style: const TextStyle(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.privacyNotifTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.privacyNotifBody,
                  style: const TextStyle(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.privacyContactTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.privacyContactBody,
                  style: const TextStyle(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SectionLabel(l10n.privacyControls),
          NestCard(
            onTap: busy ? null : () => _export(context, ref),
            child: Row(
              children: [
                const Icon(Icons.download_rounded, color: AppColors.accentDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.privacyExport,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.privacyExportBody,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (busy)
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
            onTap: busy ? null : () => _deleteAccount(context, ref),
            child: Row(
              children: [
                const Icon(Icons.delete_forever_rounded, color: AppColors.danger),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.deleteAccountTitle.replaceAll('?', ''),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.privacyDeleteHint,
                        style: const TextStyle(
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
