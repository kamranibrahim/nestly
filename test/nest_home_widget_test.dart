import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/data/nest_home_widget.dart';
import 'package:nestly/data/nest_home_widget_snapshot.dart';

void main() {
  group('selectWidgetHero', () {
    test('prefers tasks when open', () {
      final hero = selectWidgetHero(
        openTasks: 3,
        nextEvent: 'Soccer · Tue · 4:00 PM',
        dinner: 'Pasta',
      );
      expect(hero.kind, WidgetHeroKind.tasks);
      expect(hero.title, '3 open tasks');
      expect(hero.accent, 'lavender');
      expect(hero.kindKey, 'tasks');
    });

    test('singular task label', () {
      final hero = selectWidgetHero(
        openTasks: 1,
        nextEvent: '',
        dinner: '',
      );
      expect(hero.title, '1 open task');
    });

    test('falls back to event', () {
      final hero = selectWidgetHero(
        openTasks: 0,
        nextEvent: 'Dentist · Wed · 9:00 AM',
        dinner: 'Tacos',
      );
      expect(hero.kind, WidgetHeroKind.event);
      expect(hero.accent, 'teal');
    });

    test('falls back to dinner', () {
      final hero = selectWidgetHero(
        openTasks: 0,
        nextEvent: '',
        dinner: 'Pasta night',
      );
      expect(hero.kind, WidgetHeroKind.dinner);
      expect(hero.accent, 'peach');
    });

    test('quiet day', () {
      final hero = selectWidgetHero(
        openTasks: 0,
        nextEvent: '',
        dinner: '',
      );
      expect(hero.kind, WidgetHeroKind.quiet);
      expect(hero.title, contains('Quiet day'));
      expect(hero.accent, 'mint');
    });
  });

  group('labels', () {
    test('tasks label', () {
      expect(formatWidgetTasksLabel(0), 'All clear');
      expect(formatWidgetTasksLabel(1), '1 open');
      expect(formatWidgetTasksLabel(4), '4 open');
    });

    test('event and dinner labels', () {
      expect(formatWidgetEventLabel(''), 'Nothing scheduled');
      expect(formatWidgetEventLabel(' Soccer '), 'Soccer');
      expect(formatWidgetDinnerLabel(''), 'Not planned');
      expect(formatWidgetDinnerLabel('Pasta'), 'Pasta');
    });

    test('shortWidgetText truncates', () {
      expect(shortWidgetText('abc', max: 10), 'abc');
      expect(
        shortWidgetText('abcdefghijklmnopqrstuvwxyz', max: 10),
        'abcdefghi…',
      );
    });
  });

  group('formatWidgetUpdatedAge', () {
    final now = DateTime(2026, 7, 31, 12);

    test('just now and minutes', () {
      expect(
        formatWidgetUpdatedAge(
          now.subtract(const Duration(seconds: 10)),
          now: now,
        ),
        'just now',
      );
      expect(
        formatWidgetUpdatedAge(
          now.subtract(const Duration(minutes: 5)),
          now: now,
        ),
        '5m ago',
      );
    });
  });

  test('deep link constants are unique nestly URIs', () {
    final uris = {
      NestHomeWidget.launchUri,
      NestHomeWidget.tasksUri,
      NestHomeWidget.calendarUri,
      NestHomeWidget.mealsUri,
    };
    expect(uris, hasLength(4));
    for (final u in uris) {
      expect(u.startsWith('casaio://'), isTrue);
    }
  });
}
