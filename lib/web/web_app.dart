import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_errors.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'companion_store.dart';
import 'web_shell.dart';

final companionStoreProvider = Provider<CompanionStore>((ref) {
  return CompanionStore();
});

class WebCompanionApp extends StatelessWidget {
  const WebCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nestly Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _WebGate(),
    );
  }
}

class _WebGate extends ConsumerWidget {
  const _WebGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (user) {
        if (user == null) return const _WebAuthScreen();
        return const _WebNestGate();
      },
    );
  }
}

class _WebNestGate extends ConsumerStatefulWidget {
  const _WebNestGate();

  @override
  ConsumerState<_WebNestGate> createState() => _WebNestGateState();
}

class _WebNestGateState extends ConsumerState<_WebNestGate> {
  late Future<({String id, String name, String inviteCode})?> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(companionStoreProvider).nestInfo();
  }

  void _reload() {
    setState(() {
      _future = ref.read(companionStoreProvider).nestInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final nest = snap.data;
        if (nest == null) {
          return _WebNestSetup(onReady: _reload);
        }
        return WebShell(nestId: nest.id, nestName: nest.name);
      },
    );
  }
}

class _WebAuthScreen extends ConsumerStatefulWidget {
  const _WebAuthScreen();

  @override
  ConsumerState<_WebAuthScreen> createState() => _WebAuthScreenState();
}

class _WebAuthScreenState extends ConsumerState<_WebAuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _email.text,
            password: _password.text,
          );
    } catch (e) {
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'nestly',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Web companion — calendar, tasks & lists',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkSecondary),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Log in'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create a nest on the Nestly mobile app first, then sign in here with the same account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WebNestSetup extends ConsumerStatefulWidget {
  const _WebNestSetup({required this.onReady});

  final VoidCallback onReady;

  @override
  ConsumerState<_WebNestSetup> createState() => _WebNestSetupState();
}

class _WebNestSetupState extends ConsumerState<_WebNestSetup> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(authRepositoryProvider);
      await auth.joinNest(
        inviteCode: _code.text,
        memberName: _name.text.trim().isEmpty
            ? (auth.currentUser?.displayName ?? 'Parent')
            : _name.text.trim(),
      );
      widget.onReady();
    } catch (e) {
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Join your nest',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the invite code from the Nestly mobile app.',
                    style: TextStyle(color: AppColors.inkSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Your name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Invite code'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _join,
                    child: const Text('Join nest'),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(authRepositoryProvider).signOut(),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
