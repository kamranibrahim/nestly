import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/navigation/app_navigator.dart';

void main() {
  group('NotificationIntent.fromPayload', () {
    test('maps bills aliases', () {
      expect(
        NotificationIntent.fromPayload('bills')?.destination,
        NotificationDestination.bills,
      );
      expect(
        NotificationIntent.fromPayload('budget')?.destination,
        NotificationDestination.bills,
      );
    });

    test('maps care and school', () {
      expect(
        NotificationIntent.fromPayload('care')?.destination,
        NotificationDestination.care,
      );
      expect(
        NotificationIntent.fromPayload('SCHOOL')?.destination,
        NotificationDestination.school,
      );
    });

    test('ignores blank and unknown', () {
      expect(NotificationIntent.fromPayload(null), isNull);
      expect(NotificationIntent.fromPayload(''), isNull);
      expect(NotificationIntent.fromPayload('home'), isNull);
    });
  });

  test('fromMessageData prefers nestly_route', () {
    final intent = NotificationIntent.fromMessageData({
      'nestly_route': 'care',
      'route': 'bills',
    });
    expect(intent?.destination, NotificationDestination.care);
  });
}
