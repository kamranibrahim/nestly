import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_errors.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/providers.dart';
import '../../state/auth_ui.dart';
import '../../theme/app_colors.dart';
import '../../widgets/invite_family_sheet.dart';
import '../../widgets/shimmer.dart';

/// Fast onboarding: one screen, sensible defaults, under ~30 seconds.
class NestSetupScreen extends ConsumerWidget {
  const NestSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(nestSetupUiProvider);
    final ctrl = ref.read(nestSetupUiProvider.notifier);
    final l10n = context.l10n;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillFromUser(ref);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          ui.joining ? l10n.nestSetupJoinTitle : l10n.nestSetupCreateTitle,
        ),
        actions: [
          TextButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: Text(l10n.commonSignOut),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            ui.joining ? l10n.nestSetupJoinBody : l10n.nestSetupCreateBody,
            style: const TextStyle(
              color: AppColors.inkSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: ctrl.memberNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.authNameHint,
              helperText: l10n.nestSetupNameHelper,
            ),
          ),
          const SizedBox(height: 12),
          if (ui.joining)
            TextField(
              controller: ctrl.inviteCodeController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (value) {
                final normalized = normalizeInviteCode(value);
                if (normalized == value) return;
                ctrl.inviteCodeController.value = TextEditingValue(
                  text: normalized,
                  selection: TextSelection.collapsed(offset: normalized.length),
                );
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                labelText: l10n.nestSetupInviteCode,
                hintText: 'ABC123',
                helperText: l10n.nestSetupInviteHelper,
                suffixIcon: IconButton(
                  tooltip: l10n.commonPaste,
                  onPressed:
                      ui.busy ? null : () => _pasteInviteCode(context, ref),
                  icon: const Icon(Icons.content_paste_rounded),
                ),
              ),
              onSubmitted: (_) {
                if (!ui.busy) _submit(context, ref);
              },
            )
          else
            TextField(
              controller: ctrl.nestNameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.nestSetupNestName,
                helperText: l10n.nestSetupNestHelper,
              ),
            ),
          if (!ui.joining) ...[
            const SizedBox(height: 8),
            Text(
              l10n.nestSetupAfterStart,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
          if (ui.error != null) ...[
            const SizedBox(height: 12),
            Text(
              ui.error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger),
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
                : Text(ui.joining ? l10n.nestSetupJoinTitle : l10n.nestSetupStart),
          ),
          TextButton(
            onPressed: ui.busy ? null : ctrl.toggleJoining,
            child: Text(
              ui.joining
                  ? l10n.nestSetupSwitchCreate
                  : l10n.nestSetupSwitchJoin,
            ),
          ),
        ],
      ),
    );
  }
}

void _prefillFromUser(WidgetRef ref) {
  final ctrl = ref.read(nestSetupUiProvider.notifier);
  final user = ref.read(authRepositoryProvider).currentUser;
  if (ctrl.memberNameController.text.isEmpty &&
      (user?.displayName?.isNotEmpty ?? false)) {
    ctrl.memberNameController.text = user!.displayName!;
  }
  final email = user?.email;
  if (ctrl.nestNameController.text == 'Our Nest' &&
      email != null &&
      email.contains('@')) {
    final local = email.split('@').first;
    if (local.isNotEmpty) {
      ctrl.nestNameController.text =
          "${local[0].toUpperCase()}${local.substring(1)}'s Nest";
    }
  }
}

Future<void> _pasteInviteCode(BuildContext context, WidgetRef ref) async {
  final ctrl = ref.read(nestSetupUiProvider.notifier);
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  final pasted = data?.text;
  if (pasted == null || pasted.trim().isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.clipboardEmpty)));
    return;
  }
  final code = normalizeInviteCode(pasted);
  ctrl.inviteCodeController.text = code;
  ctrl.inviteCodeController.selection =
      TextSelection.collapsed(offset: code.length);
  ctrl.setError(null);
}

Future<void> _submit(BuildContext context, WidgetRef ref) async {
  final ctrl = ref.read(nestSetupUiProvider.notifier);
  ctrl.setBusy(true);
  ctrl.setError(null);
  try {
    final auth = ref.read(authRepositoryProvider);
    final sync = ref.read(syncServiceProvider);
    final name = ctrl.memberNameController.text.trim().isEmpty
        ? 'Parent'
        : ctrl.memberNameController.text.trim();
    final joining = ref.read(nestSetupUiProvider).joining;
    final created = !joining;
    final nest = joining
        ? await auth.joinNest(
            inviteCode: ctrl.inviteCodeController.text,
            memberName: name,
          )
        : await auth.createNest(
            nestName: ctrl.nestNameController.text.trim().isEmpty
                ? 'Our Nest'
                : ctrl.nestNameController.text.trim(),
            memberName: name,
          );
    await sync.bindNest(nest.id);
    await sync.pullMembers(nest.id);
    try {
      await sync.syncAll();
    } catch (_) {}
    try {
      await ref.read(notificationServiceProvider).init();
    } catch (e, st) {
      // Nest is already created — don't block entry on FCM / permission issues.
      debugPrint('Notification init skipped after nest setup: $e\n$st');
    }
    if (created && context.mounted) {
      await showInviteFamilySheet(
        context,
        inviteCode: nest.inviteCode,
        nestName: nest.name,
        isPostCreate: true,
      );
    }
    ref.invalidate(nestInfoProvider);
  } catch (e, st) {
    debugPrint('Nest setup failed: $e\n$st');
    ctrl.setError(
      friendlyAuthError(e, context.mounted ? context.l10n : null),
    );
  } finally {
    ctrl.setBusy(false);
  }
}
