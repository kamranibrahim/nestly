import 'package:flutter_test/flutter_test.dart';

import 'package:nestly/data/sync_controller.dart';

void main() {
  group('formatLastSynced', () {
    final now = DateTime(2026, 7, 30, 12, 0);

    test('null is not synced yet', () {
      expect(formatLastSynced(null, now: now), 'Not synced yet');
    });

    test('just now under 45 seconds', () {
      expect(
        formatLastSynced(now.subtract(const Duration(seconds: 44)), now: now),
        'Just now',
      );
    });

    test('boundary into minutes', () {
      expect(
        formatLastSynced(now.subtract(const Duration(seconds: 45)), now: now),
        '0m ago',
      );
    });

    test('minutes ago', () {
      expect(
        formatLastSynced(now.subtract(const Duration(minutes: 12)), now: now),
        '12m ago',
      );
    });

    test('hours ago', () {
      expect(
        formatLastSynced(now.subtract(const Duration(hours: 3)), now: now),
        '3h ago',
      );
    });

    test('days ago under a week', () {
      expect(
        formatLastSynced(now.subtract(const Duration(days: 2)), now: now),
        '2d ago',
      );
    });

    test('older than a week uses month/day', () {
      expect(
        formatLastSynced(DateTime(2026, 7, 1, 12), now: now),
        '7/1',
      );
    });
  });

  group('SyncUiState', () {
    test('copyWith clearError drops last error', () {
      const dirty = SyncUiState(isSyncing: false, lastError: 'boom');
      final cleared = dirty.copyWith(clearError: true, isSyncing: true);
      expect(cleared.hasError, isFalse);
      expect(cleared.lastError, isNull);
      expect(cleared.isSyncing, isTrue);
    });

    test('hasError is true only for non-empty messages', () {
      expect(const SyncUiState().hasError, isFalse);
      expect(const SyncUiState(lastError: '').hasError, isFalse);
      expect(const SyncUiState(lastError: 'x').hasError, isTrue);
    });
  });

  test('resume debounce is about 3 seconds', () {
    expect(SyncController.resumeDebounce, const Duration(seconds: 3));
  });
}
