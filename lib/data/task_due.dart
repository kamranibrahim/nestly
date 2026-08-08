import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'enums.dart';

/// Advances a due date by [cadenceDays] from calendar midnight of [from].
DateTime advanceDueAt(DateTime from, int cadenceDays) {
  final day = DateTime(from.year, from.month, from.day);
  return day.add(Duration(days: cadenceDays.clamp(1, 365)));
}

/// Resolves the calendar day a task is due, preferring [dueAt] over [dueLabel].
DateTime resolveTaskDueAt({
  DateTime? dueAt,
  String? dueLabel,
  required DateTime now,
}) {
  if (dueAt != null) {
    return DateTime(dueAt.year, dueAt.month, dueAt.day);
  }
  return TaskDueLabel.dueDateFor(
        dueLabel ?? TaskDueLabel.today.label,
        now: now,
      ) ??
      DateTime(now.year, now.month, now.day);
}

/// Short relative label for search / legacy [dueLabel] cache.
String dueLabelForDueAt(DateTime dueAt, {required DateTime now}) {
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(dueAt.year, dueAt.month, dueAt.day);
  final diff = due.difference(today).inDays;
  if (diff == 0) return TaskDueLabel.today.label;
  if (diff == 1) return TaskDueLabel.tomorrow.label;
  if (diff == 7) return TaskDueLabel.in7Days.label;
  if (diff >= 0 && diff <= 6) {
    return DateFormat('EEE').format(dueAt);
  }
  return DateFormat('MMM d').format(dueAt);
}

/// Localized due string for task list / sheets.
String formatTaskDue(DateTime dueAt, AppLocalizations l10n, {required DateTime now}) {
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(dueAt.year, dueAt.month, dueAt.day);
  final diff = due.difference(today).inDays;
  if (diff == 0) return l10n.taskDueToday;
  if (diff == 1) return l10n.taskDueTomorrow;
  if (diff == 7) return l10n.taskDueIn7Days;
  return DateFormat.yMMMd(l10n.localeName).format(dueAt);
}

/// Localized cadence label for recurring tasks.
String formatTaskCadence(int cadenceDays, AppLocalizations l10n) {
  return switch (cadenceDays) {
    1 => l10n.taskCadenceDaily,
    7 => l10n.taskCadenceWeekly,
    14 => l10n.taskCadenceBiweekly,
    30 => l10n.taskCadenceMonthly,
    _ => l10n.taskCadenceEveryDays(cadenceDays),
  };
}

/// Effective cadence when recurring is enabled (defaults to weekly).
int effectiveTaskCadenceDays({required bool recurring, required int cadenceDays}) {
  if (!recurring) return 0;
  return cadenceDays >= 1 ? cadenceDays : 7;
}
