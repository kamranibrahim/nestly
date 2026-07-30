/// Calendar browsing helpers (Sun–Sat weeks to match the month grid DOW row).
library;

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

/// Exclusive end of [day] (midnight of the next calendar day).
DateTime endOfDayExclusive(DateTime day) {
  final d = calendarDateOnly(day);
  return d.add(const Duration(days: 1));
}

bool isSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
