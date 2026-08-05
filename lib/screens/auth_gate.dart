import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/nest_home_widget.dart';
import '../data/sync_controller.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import 'app_shell.dart';
import 'auth/auth_screen.dart';
import 'auth/nest_setup_screen.dart';
import 'onboarding/onboarding_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      loading: () => const BrandLoadingScaffold(),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not check sign-in.\n$e',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(authStateProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (user) {
        if (user == null) return const _PreAuthGate();
        return const _NestGate();
      },
    );
  }
}

class _PreAuthGate extends ConsumerWidget {
  const _PreAuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = ref.watch(onboardingSeenProvider);

    return seen.when(
      loading: () => const BrandLoadingScaffold(),
      error: (_, _) => const AuthScreen(),
      data: (done) => done ? const AuthScreen() : const OnboardingScreen(),
    );
  }
}

class _NestGate extends ConsumerWidget {
  const _NestGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nest = ref.watch(nestInfoProvider);

    return nest.when(
      loading: () => const HomeLoadingSkeleton(),
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
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
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

class _SyncedShellState extends ConsumerState<_SyncedShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(syncControllerProvider.notifier).scheduleResumeSync();
      unawaited(_refreshWidget());
    }
  }

  Future<void> _refreshWidget() async {
    try {
      final nest = ref.read(nestInfoProvider).valueOrNull;
      await NestHomeWidget.publishFromDatabase(
        ref.read(databaseProvider),
        nestName: nest?.name,
      );
    } catch (_) {}
  }

  Future<void> _bootstrap() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    final nest = await ref.read(nestInfoProvider.future);
    if (!mounted || nest == null) return;
    if (FirebaseAuth.instance.currentUser == null) return;
    final sync = ref.read(syncServiceProvider);
    await sync.bindNest(nest.id);
    await ref.read(syncControllerProvider.notifier).syncNow(quiet: true);
    if (!mounted || FirebaseAuth.instance.currentUser == null) return;
    try {
      await ref.read(notificationServiceProvider).init();
    } catch (_) {}
    await _refreshWidget();
  }

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SyncStatusBanner(),
        Expanded(child: AppShell()),
      ],
    );
  }
}

/// Shows only when the last sync failed — Retry + short status.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncControllerProvider);
    if (!sync.hasError) return const SizedBox.shrink();

    return Material(
      color: const Color(0xFFFFE8D6),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 16,
                color: AppColors.ink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sync.isSyncing
                      ? 'Syncing…'
                      : 'Sync failed · tap Retry to try again',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: sync.isSyncing
                    ? null
                    : () => ref
                          .read(syncControllerProvider.notifier)
                          .syncNow(context: context),
                child: Text(sync.isSyncing ? '…' : 'Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
