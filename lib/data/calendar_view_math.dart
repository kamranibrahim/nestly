/// Calendar browsing helpers (Sun–Sat weeks to match the month grid DOW row).
library;

import 'enums.dart';

DateTime calendarDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Sunday of the week that contains [day] (date-only).
DateTime startOfWeekSunday(DateTime day) {
  final d = calendarDateOnly(day);
  // DateTime.weekday: Mon=1 … Sun=7. Offset from Sunday:
  final fromSunday = d.weekday % 7;
  return d.subtract(Duration(days: fromSunday));
}

/// Saturday of the week that contains [day] (date-only).
DateTime endOfWeekSaturday(DateTime day) =>
    startOfWeekSunday(day).add(const Duration(days: 6));

/// Seven date-only days Sun→Sat for the week containing [day].
List<DateTime> weekDaysSunday(DateTime day) {
  final start = startOfWeekSunday(day);
  return List.generate(7, (i) => start.add(Duration(days: i)));
}

DateTime shiftMonth(DateTime day, int deltaMonths) {
  final d = calendarDateOnly(day);
  final totalMonths = d.year * 12 + (d.month - 1) + deltaMonths;
  final year = totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final clampedDay = d.day > lastDay ? lastDay : d.day;
  return DateTime(year, month, clampedDay);
}

DateTime shiftWeek(DateTime day, int deltaWeeks) =>
    calendarDateOnly(day).add(Duration(days: 7 * deltaWeeks));

DateTime shiftDay(DateTime day, int deltaDays) =>
    calendarDateOnly(day).add(Duration(days: deltaDays));

/// Exclusive end of [day] (midnight of the next calendar day).
DateTime endOfDayExclusive(DateTime day) {
  final d = calendarDateOnly(day);
  return d.add(const Duration(days: 1));
}

bool isSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Maximum recurring instances expanded in one range query.
const kMaxRecurrenceExpansions = 366;

/// One occurrence of a recurring (or single) event.
class EventOccurrence {
  const EventOccurrence({required this.startsAt, this.endsAt});

  final DateTime startsAt;
  final DateTime? endsAt;
}

/// Inputs needed to expand recurrence (mirrors calendar event recurrence fields).
class RecurringEventAnchor {
  const RecurringEventAnchor({
    required this.startsAt,
    this.endsAt,
    this.allDay = false,
    this.recurrence = EventRecurrence.none,
    this.recurrenceUntil,
  });

  final DateTime startsAt;
  final DateTime? endsAt;
  final bool allDay;
  final EventRecurrence recurrence;
  final DateTime? recurrenceUntil;
}

bool _occurrenceInRange({
  required DateTime startsAt,
  DateTime? endsAt,
  required bool allDay,
  required DateTime rangeStart,
  required DateTime rangeEnd,
}) {
  final rangeStartDay = calendarDateOnly(rangeStart);
  final rangeEndDay = calendarDateOnly(rangeEnd);
  if (allDay) {
    final day = calendarDateOnly(startsAt);
    return !day.isBefore(rangeStartDay) && !day.isAfter(rangeEndDay);
  }
  final end = endsAt ?? startsAt;
  return startsAt.isBefore(rangeEnd.add(const Duration(microseconds: 1))) &&
      !end.isBefore(rangeStart);
}

DateTime _advanceRecurrence(
  DateTime cursor,
  EventRecurrence recurrence, {
  required bool allDay,
}) {
  return switch (recurrence) {
    EventRecurrence.none => cursor,
    EventRecurrence.daily => allDay
        ? calendarDateOnly(cursor).add(const Duration(days: 1))
        : cursor.add(const Duration(days: 1)),
    EventRecurrence.weekly => allDay
        ? calendarDateOnly(cursor).add(const Duration(days: 7))
        : cursor.add(const Duration(days: 7)),
    EventRecurrence.monthly => _advanceMonthly(cursor, allDay: allDay),
  };
}

DateTime _advanceMonthly(DateTime cursor, {required bool allDay}) {
  if (allDay) {
    return shiftMonth(calendarDateOnly(cursor), 1);
  }
  final nextDate = shiftMonth(calendarDateOnly(cursor), 1);
  return DateTime(
    nextDate.year,
    nextDate.month,
    nextDate.day,
    cursor.hour,
    cursor.minute,
    cursor.second,
    cursor.millisecond,
    cursor.microsecond,
  );
}

/// Expands [anchor] into occurrences that fall within [rangeStart, rangeEnd]
/// (inclusive by calendar day for all-day events).
List<EventOccurrence> expandRecurringEvent(
  RecurringEventAnchor anchor,
  DateTime rangeStart,
  DateTime rangeEnd,
) {
  final rangeStartDay = calendarDateOnly(rangeStart);
  final rangeEndDay = calendarDateOnly(rangeEnd);
  final untilDay = switch (anchor.recurrenceUntil) {
    final u? => calendarDateOnly(u),
    null => null,
  };
  final duration = switch (anchor.endsAt) {
    final end? => end.difference(anchor.startsAt),
    null => null,
  };

  if (anchor.recurrence == EventRecurrence.none) {
    if (_occurrenceInRange(
      startsAt: anchor.startsAt,
      endsAt: anchor.endsAt,
      allDay: anchor.allDay,
      rangeStart: rangeStartDay,
      rangeEnd: rangeEndDay,
    )) {
      return [
        EventOccurrence(startsAt: anchor.startsAt, endsAt: anchor.endsAt),
      ];
    }
    return const [];
  }

  final results = <EventOccurrence>[];
  var cursor = anchor.startsAt;
  for (var i = 0; i < kMaxRecurrenceExpansions; i++) {
    final cursorDay = calendarDateOnly(cursor);
    if (cursorDay.isAfter(rangeEndDay)) break;
    if (untilDay != null && cursorDay.isAfter(untilDay)) break;

    final occEnd = duration != null ? cursor.add(duration) : anchor.endsAt;
    if (_occurrenceInRange(
      startsAt: cursor,
      endsAt: occEnd,
      allDay: anchor.allDay,
      rangeStart: rangeStartDay,
      rangeEnd: rangeEndDay,
    )) {
      results.add(EventOccurrence(startsAt: cursor, endsAt: occEnd));
    }

    final next = _advanceRecurrence(
      cursor,
      anchor.recurrence,
      allDay: anchor.allDay,
    );
    if (next.isAtSameMomentAs(cursor)) break;
    cursor = next;
  }
  return results;
}
