import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import 'db/app_database.dart';

/// UI-facing sync state (last sync time, in-flight, last error).
class SyncUiState {
  const SyncUiState({
    this.isSyncing = false,
    this.lastSyncAt,
    this.lastError,
  });

  final bool isSyncing;
  final DateTime? lastSyncAt;
  final String? lastError;

  bool get hasError => lastError != null && lastError!.isNotEmpty;

  SyncUiState copyWith({
    bool? isSyncing,
    DateTime? lastSyncAt,
    String? lastError,
    bool clearError = false,
  }) {
    return SyncUiState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Coalesces sync calls, debounces resume sync, and feeds Nest/Home status UI.
class SyncController extends StateNotifier<SyncUiState> {
  SyncController(this._ref) : super(const SyncUiState()) {
    _hydrateLastSync();
  }

  final Ref _ref;
  Timer? _resumeDebounce;
  Future<bool>? _inFlight;

  static const resumeDebounce = Duration(seconds: 3);

  Future<void> _hydrateLastSync() async {
    final raw = await _ref.read(databaseProvider).getMeta('lastSyncAt');
    if (raw == null || raw.isEmpty) return;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null || !mounted) return;
    state = state.copyWith(lastSyncAt: parsed.toLocal());
  }

  /// Debounced sync when the app returns to foreground (~3s).
  void scheduleResumeSync() {
    _resumeDebounce?.cancel();
    _resumeDebounce = Timer(resumeDebounce, () {
      unawaited(syncNow(quiet: true));
    });
  }

  /// Runs [SyncService.syncAll], coalescing concurrent callers.
  ///
  /// Returns `true` on success. When [quiet] is false and [context] is mounted,
  /// shows a SnackBar on failure.
  Future<bool> syncNow({
    BuildContext? context,
    bool quiet = false,
  }) {
    final existing = _inFlight;
    if (existing != null) return existing;

    final future = _run(context: context, quiet: quiet);
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
  }

  Future<bool> _run({
    BuildContext? context,
    required bool quiet,
  }) async {
    if (!mounted) return false;
    state = state.copyWith(isSyncing: true, clearError: true);
    try {
      await _ref.read(syncServiceProvider).syncAll();
      final at = DateTime.now();
      if (!mounted) return true;
      state = SyncUiState(isSyncing: false, lastSyncAt: at);
      return true;
    } catch (e) {
      final message = _friendlyError(e);
      if (mounted) {
        state = state.copyWith(isSyncing: false, lastError: message);
      }
      if (!quiet && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      return false;
    }
  }

  @override
  void dispose() {
    _resumeDebounce?.cancel();
    super.dispose();
  }

  static String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('unavailable') ||
        text.contains('network') ||
        text.contains('SocketException')) {
      return 'Couldn’t sync — check your connection. Changes stay on this device.';
    }
    return 'Couldn’t sync. Changes stay on this device — retry from Nest.';
  }
}

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncUiState>((ref) {
  return SyncController(ref);
});

/// After a local write: push to cloud and SnackBar on fail (unless [quiet]).
Future<bool> syncAfterWrite(
  WidgetRef ref, {
  BuildContext? context,
  bool quiet = false,
}) {
  return ref.read(syncControllerProvider.notifier).syncNow(
        context: context,
        quiet: quiet,
      );
}

/// Relative label for Nest / banner (“Just now”, “5m ago”, …).
String formatLastSynced(DateTime? at, {DateTime? now}) {
  if (at == null) return 'Not synced yet';
  final n = now ?? DateTime.now();
  final diff = n.difference(at);
  if (diff.inSeconds < 45) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${at.month}/${at.day}';
}
