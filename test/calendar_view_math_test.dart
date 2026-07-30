import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/data/calendar_view_math.dart';

void main() {
  group('startOfWeekSunday / endOfWeekSaturday', () {
    test('Sunday stays Sunday', () {
      final day = DateTime(2026, 7, 26); // Sunday
      expect(startOfWeekSunday(day), DateTime(2026, 7, 26));
      expect(endOfWeekSaturday(day), DateTime(2026, 8, 1));
    });

    test('Wednesday maps to prior Sunday', () {
      final day = DateTime(2026, 7, 29); // Wednesday
      expect(startOfWeekSunday(day), DateTime(2026, 7, 26));
      expect(endOfWeekSaturday(day), DateTime(2026, 8, 1));
    });

    test('Saturday maps to prior Sunday', () {
      final day = DateTime(2026, 8, 1); // Saturday
      expect(startOfWeekSunday(day), DateTime(2026, 7, 26));
      expect(weekDaysSunday(day), hasLength(7));
      expect(weekDaysSunday(day).first, DateTime(2026, 7, 26));
      expect(weekDaysSunday(day).last, DateTime(2026, 8, 1));
    });
  });

  group('shiftMonth', () {
    test('clamps Jan 31 into February', () {
      expect(shiftMonth(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    });

    test('crosses year boundary backward', () {
      expect(shiftMonth(DateTime(2026, 1, 15), -1), DateTime(2025, 12, 15));
    });
  });

  group('shiftWeek / endOfDayExclusive', () {
    test('shiftWeek moves by seven days', () {
      expect(shiftWeek(DateTime(2026, 7, 29), 1), DateTime(2026, 8, 5));
      expect(shiftWeek(DateTime(2026, 7, 29), -1), DateTime(2026, 7, 22));
    });

    test('endOfDayExclusive is next midnight', () {
      expect(
        endOfDayExclusive(DateTime(2026, 7, 29, 15, 30)),
        DateTime(2026, 7, 30),
      );
    });
  });

  test('isSameCalendarDay ignores time', () {
    expect(
      isSameCalendarDay(
        DateTime(2026, 7, 29, 9),
        DateTime(2026, 7, 29, 23),
      ),
      isTrue,
    );
    expect(
      isSameCalendarDay(DateTime(2026, 7, 29), DateTime(2026, 7, 30)),
      isFalse,
    );
  });
}
