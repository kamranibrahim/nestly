import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../theme/app_colors.dart';

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
      if (_memberName.text.isEmpty && (user?.displayName?.isNotEmpty ?? false)) {
        _memberName.text = user!.displayName!;
      }
      final email = user?.email;
      if (_nestName.text == 'Our Nest' && email != null && email.contains('@')) {
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
      final nest = _joining
          ? await auth.joinNest(
              inviteCode: _inviteCode.text,
              memberName: name,
            )
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
      await ref.read(notificationServiceProvider).init();
      ref.invalidate(nestInfoProvider);
    } catch (e) {
      setState(() => _error = e.toString());
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
                ? 'Enter the 6-character code from your family.'
                : 'Create your household nest — calendars, lists, and tasks stay in sync.',
            style: const TextStyle(
              color: AppColors.inkSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _memberName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Your name'),
          ),
          const SizedBox(height: 12),
          if (_joining)
            TextField(
              controller: _inviteCode,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(labelText: 'Invite code'),
            )
          else
            TextField(
              controller: _nestName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nest name'),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
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
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
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
              _joining
                  ? 'Create a new nest instead'
                  : 'Have an invite code?',
            ),
          ),
        ],
      ),
    );
  }
}
