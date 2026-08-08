import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/providers.dart';
import 'db/app_database.dart';
import 'nest_home_widget.dart';
import 'review_prompt.dart';

/// UI-facing sync state (last sync time, in-flight, last error / soft note).
class SyncUiState {
  const SyncUiState({
    this.isSyncing = false,
    this.lastSyncAt,
    this.lastError,
    this.lastNote,
  });

  final bool isSyncing;
  final DateTime? lastSyncAt;
  final String? lastError;

  /// Soft info after a successful sync (e.g. kept local edits).
  final String? lastNote;

  bool get hasError => lastError != null && lastError!.isNotEmpty;

  SyncUiState copyWith({
    bool? isSyncing,
    DateTime? lastSyncAt,
    String? lastError,
    String? lastNote,
    bool clearError = false,
    bool clearNote = false,
  }) {
    return SyncUiState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastNote: clearNote ? null : (lastNote ?? this.lastNote),
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
  /// shows a SnackBar on failure (and optionally when local edits were kept).
  Future<bool> syncNow({BuildContext? context, bool quiet = false}) {
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

  Future<bool> _run({BuildContext? context, required bool quiet}) async {
    if (!mounted) return false;
    state = state.copyWith(isSyncing: true, clearError: true, clearNote: true);
    try {
      // Storage uploads first so Firestore meta includes storagePath.
      try {
        await _ref.read(vaultServiceProvider).retryAllFailed();
      } catch (e) {
        debugPrint('Vault retry skipped: $e');
      }
      final keptLocal = await _ref.read(syncServiceProvider).syncAll();
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        await _ref.read(timelineRepositoryProvider).deliverLocalMentionNotifications(
              currentMemberId: uid,
              showMention: ({
                required authorName,
                required preview,
              }) =>
                  _ref.read(notificationServiceProvider).showTimelineMention(
                        authorName: authorName,
                        preview: preview,
                      ),
            );
      } catch (e) {
        debugPrint('Mention notify skipped: $e');
      }
      try {
        await _ref.read(notificationServiceProvider).rescheduleReminders();
      } catch (e) {
        debugPrint('Reminder reschedule skipped: $e');
      }
      final at = DateTime.now();
      try {
        final nest = _ref.read(nestInfoProvider).valueOrNull;
        await NestHomeWidget.publishFromDatabase(
          _ref.read(databaseProvider),
          nestName: nest?.name,
        );
        final members =
            _ref.read(membersProvider).valueOrNull ?? const [];
        await maybeRequestStoreReview(
          _ref.read(databaseProvider),
          memberCount: members.length,
          nestCreatedAt: nest?.createdAt,
        );
      } catch (_) {}
      if (!mounted) return true;
      final note = keptLocal > 0
          ? (keptLocal == 1
                ? 'Kept 1 local edit while syncing'
                : 'Kept $keptLocal local edits while syncing')
          : null;
      state = SyncUiState(isSyncing: false, lastSyncAt: at, lastNote: note);
      if (!quiet &&
          note != null &&
          context != null &&
          context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(note), duration: const Duration(seconds: 2)),
        );
      }
      return true;
    } catch (e) {
      final message = _friendlyError(e);
      if (mounted) {
        state = state.copyWith(isSyncing: false, lastError: message);
      }
      if (!quiet && context != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
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
  return ref
      .read(syncControllerProvider.notifier)
      .syncNow(context: context, quiet: quiet);
}

/// Relative label for Nest / banner (“Just now”, “5m ago”, …).
String formatLastSynced(
  DateTime? at, {
  DateTime? now,
  AppLocalizations? l10n,
}) {
  if (at == null) return l10n?.syncNotYet ?? 'Not synced yet';
  final n = now ?? DateTime.now();
  final diff = n.difference(at);
  if (diff.inSeconds < 45) return l10n?.syncJustNow ?? 'Just now';
  if (diff.inMinutes < 60) {
    return l10n?.syncMinutesAgo(diff.inMinutes) ?? '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return l10n?.syncHoursAgo(diff.inHours) ?? '${diff.inHours}h ago';
  }
  if (diff.inDays < 7) {
    return l10n?.syncDaysAgo(diff.inDays) ?? '${diff.inDays}d ago';
  }
  return '${at.month}/${at.day}';
}
