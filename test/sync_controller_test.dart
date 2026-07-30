import 'package:flutter_test/flutter_test.dart';

import 'package:nestly/data/sync_controller.dart';

void main() {
  group('formatLastSynced', () {
    final now = DateTime(2026, 7, 30, 12, 0);

    test('null is not synced yet', () {
      expect(formatLastSynced(null, now: now), 'Not synced yet');
    });

    test('just now', () {
      expect(
        formatLastSynced(now.subtract(const Duration(seconds: 10)), now: now),
        'Just now',
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
  });

  test('resume debounce is about 3 seconds', () {
    expect(SyncController.resumeDebounce, const Duration(seconds: 3));
  });
}
