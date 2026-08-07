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

    test('maps calendar and tasks', () {
      expect(
        NotificationIntent.fromPayload('calendar')?.destination,
        NotificationDestination.calendar,
      );
      expect(
        NotificationIntent.fromPayload('event')?.destination,
        NotificationDestination.calendar,
      );
      expect(
        NotificationIntent.fromPayload('tasks')?.destination,
        NotificationDestination.tasks,
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

  group('openCasaioUri', () {
    tearDown(() {
      nestlyShellTabRequest.value = null;
    });

    test('routes hosts to shell tabs', () {
      openCasaioUri(Uri.parse('casaio://home'));
      expect(nestlyShellTabRequest.value, CasaioShellTab.home);

      openCasaioUri(Uri.parse('casaio://calendar'));
      expect(nestlyShellTabRequest.value, CasaioShellTab.calendar);

      openCasaioUri(Uri.parse('casaio://tasks'));
      expect(nestlyShellTabRequest.value, CasaioShellTab.tasks);
    });

    test('ignores non-nestly schemes', () {
      nestlyShellTabRequest.value = CasaioShellTab.home;
      openCasaioUri(Uri.parse('https://example.com'));
      expect(nestlyShellTabRequest.value, CasaioShellTab.home);
    });
  });
}
