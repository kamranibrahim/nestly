import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_errors.dart';
import '../../providers/providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/invite_family_sheet.dart';
import '../../widgets/shimmer.dart';

/// Fast onboarding: one screen, sensible defaults, under ~30 seconds.
class NestSetupScreen extends ConsumerStatefulWidget {
  const NestSetupScreen({super.key});

  @override
  ConsumerState<NestSetupScreen> createState() => _NestSetupScreenState();
}

class _NestSetupScreenState extends ConsumerState<NestSetupScreen> {
  final _nestName = TextEditingController(text: 'Our Nest');
  final _memberName = TextEditingController();
  final _inviteCode = TextEditingController();
  bool _joining = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (_memberName.text.isEmpty &&
          (user?.displayName?.isNotEmpty ?? false)) {
        _memberName.text = user!.displayName!;
      }
      final email = user?.email;
      if (_nestName.text == 'Our Nest' &&
          email != null &&
          email.contains('@')) {
        final local = email.split('@').first;
        if (local.isNotEmpty) {
          _nestName.text =
              "${local[0].toUpperCase()}${local.substring(1)}'s Nest";
        }
      }
    });
  }

  @override
  void dispose() {
    _nestName.dispose();
    _memberName.dispose();
    _inviteCode.dispose();
    super.dispose();
  }

  Future<void> _pasteInviteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = data?.text;
    if (pasted == null || pasted.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
      return;
    }
    final code = normalizeInviteCode(pasted);
    setState(() {
      _inviteCode.text = code;
      _inviteCode.selection = TextSelection.collapsed(offset: code.length);
      _error = null;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(authRepositoryProvider);
      final sync = ref.read(syncServiceProvider);
      final name = _memberName.text.trim().isEmpty
          ? 'Parent'
          : _memberName.text.trim();
      final created = !_joining;
      final nest = _joining
          ? await auth.joinNest(inviteCode: _inviteCode.text, memberName: name)
          : await auth.createNest(
              nestName: _nestName.text.trim().isEmpty
                  ? 'Our Nest'
                  : _nestName.text.trim(),
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
      if (created && mounted) {
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
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_joining ? 'Join nest' : 'Set up in under a minute'),
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
            _joining
                ? 'Paste or type the 6-character code from your family.'
                : 'Create your household nest. You can rename it and invite family later.',
            style: const TextStyle(
              color: AppColors.inkSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _memberName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your name',
              helperText: 'Shown on shared tasks and timeline',
            ),
          ),
          const SizedBox(height: 12),
          if (_joining)
            TextField(
              controller: _inviteCode,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (value) {
                final normalized = normalizeInviteCode(value);
                if (normalized == value) return;
                _inviteCode.value = TextEditingValue(
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
                  onPressed: _busy ? null : _pasteInviteCode,
                  icon: const Icon(Icons.content_paste_rounded),
                ),
              ),
            )
          else
            TextField(
              controller: _nestName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nest name',
                helperText: 'Defaults are fine — you can change this later',
              ),
            ),
          if (!_joining) ...[
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
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.primary,
            ),
            child: _busy
                ? Semantics(
                    label: 'Working',
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: NestShimmerCircle(size: 22),
                    ),
                  )
                : Text(_joining ? 'Join nest' : 'Start nest'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _joining = !_joining;
                    _error = null;
                  }),
            child: Text(
              _joining ? 'Create a new nest instead' : 'Have an invite code?',
            ),
          ),
        ],
      ),
    );
  }
}
