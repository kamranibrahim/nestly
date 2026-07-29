import 'package:flutter/material.dart';
import '../widgets/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_colors.dart';
import 'app_shell.dart';
import 'auth/auth_screen.dart';
import 'auth/nest_setup_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      loading: () => const Scaffold(
        body: NestLoadingSkeleton(itemCount: 3),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Auth error: $e')),
      ),
      data: (user) {
        if (user == null) return const AuthScreen();
        return const _NestGate();
      },
    );
  }
}

class _NestGate extends ConsumerWidget {
  const _NestGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nest = ref.watch(nestInfoProvider);

    return nest.when(
      loading: () => const Scaffold(
        body: NestLoadingSkeleton(itemCount: 3),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load nest: $e', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(nestInfoProvider),
                  child: const Text('Retry'),
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
      data: (info) {
        if (info == null) return const NestSetupScreen();
        return const _SyncedShell();
      },
    );
  }
}

class _SyncedShell extends ConsumerStatefulWidget {
  const _SyncedShell();

  @override
  ConsumerState<_SyncedShell> createState() => _SyncedShellState();
}

class _SyncedShellState extends ConsumerState<_SyncedShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final nest = await ref.read(nestInfoProvider.future);
    if (nest == null) return;
    final sync = ref.read(syncServiceProvider);
    await sync.bindNest(nest.id);
    try {
      await sync.syncAll();
    } catch (_) {
      // Offline is fine — local Drift data remains usable.
    }
    try {
      await ref.read(notificationServiceProvider).init();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return const AppShell();
  }
}

class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nest = ref.watch(nestInfoProvider).valueOrNull;
    if (nest == null) return const SizedBox.shrink();
    return Material(
      color: AppColors.mint,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.cloud_done_outlined,
                  size: 16, color: AppColors.ink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${nest.name} · code ${nest.inviteCode}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await ref.read(syncServiceProvider).syncAll();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Synced')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sync failed: $e')),
                      );
                    }
                  }
                },
                child: const Text('Sync'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
