import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_errors.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillFromUser(ref);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(ui.joining ? 'Join nest' : 'Set up in under a minute'),
        actions: [
          TextButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            ui.joining
                ? 'Paste or type the 6-character code from your family.'
                : 'Create your household nest. You can rename it and invite family later.',
            style: const TextStyle(
              color: AppColors.inkSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: ctrl.memberNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your name',
              helperText: 'Shown on shared tasks and timeline',
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
                labelText: 'Invite code',
                hintText: 'ABC123',
                helperText: 'Spaces and dashes are stripped automatically',
                suffixIcon: IconButton(
                  tooltip: 'Paste',
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
              decoration: const InputDecoration(
                labelText: 'Nest name',
                helperText: 'Defaults are fine — you can change this later',
              ),
            ),
          if (!ui.joining) ...[
            const SizedBox(height: 8),
            Text(
              'After you start, Nestly will offer an invite code so someone can join.',
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
                    label: 'Working',
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: NestShimmerCircle(size: 22),
                    ),
                  )
                : Text(ui.joining ? 'Join nest' : 'Start nest'),
          ),
          TextButton(
            onPressed: ui.busy ? null : ctrl.toggleJoining,
            child: Text(
              ui.joining ? 'Create a new nest instead' : 'Have an invite code?',
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
    ).showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
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
    ctrl.setError(friendlyAuthError(e));
  } finally {
    ctrl.setBusy(false);
  }
}
