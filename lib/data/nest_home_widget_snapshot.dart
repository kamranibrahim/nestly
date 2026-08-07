/// Pure Casaio Home Widget snapshot helpers (no plugins).
library;

import '../l10n/app_localizations.dart';
import 'enums.dart';

export 'enums.dart' show WidgetHeroKind;

class WidgetHeroSelection {
  const WidgetHeroSelection({
    required this.kind,
    required this.title,
    required this.accent,
  });

  final WidgetHeroKind kind;
  final String title;

  /// UI hint: mint | lavender | teal | peach
  final String accent;

  String get kindKey => kind.name;
}

/// Deterministic hero for the small widget.
WidgetHeroSelection selectWidgetHero({
  required int openTasks,
  required String nextEvent,
  required String dinner,
  AppLocalizations? l10n,
}) {
  final event = nextEvent.trim();
  final meal = dinner.trim();

  if (openTasks > 0) {
    final label = l10n?.widgetOpenTasks(openTasks) ??
        (openTasks == 1 ? '1 open task' : '$openTasks open tasks');
    return WidgetHeroSelection(
      kind: WidgetHeroKind.tasks,
      title: label,
      accent: 'lavender',
    );
  }
  if (event.isNotEmpty) {
    return WidgetHeroSelection(
      kind: WidgetHeroKind.event,
      title: event,
      accent: 'teal',
    );
  }
  if (meal.isNotEmpty) {
    return WidgetHeroSelection(
      kind: WidgetHeroKind.dinner,
      title: meal,
      accent: 'peach',
    );
  }
  return WidgetHeroSelection(
    kind: WidgetHeroKind.quiet,
    title: l10n?.widgetQuietDay ?? 'Quiet day · enjoy it',
    accent: 'mint',
  );
}

String formatWidgetTasksLabel(int openTasks, [AppLocalizations? l10n]) {
  if (openTasks <= 0) return l10n?.widgetAllClear ?? 'All clear';
  return l10n?.widgetOpenShort(openTasks) ??
      (openTasks == 1 ? '1 open' : '$openTasks open');
}

String formatWidgetEventLabel(String nextEvent, [AppLocalizations? l10n]) {
  final t = nextEvent.trim();
  return t.isEmpty ? (l10n?.widgetNothingScheduled ?? 'Nothing scheduled') : t;
}

String formatWidgetDinnerLabel(String dinner, [AppLocalizations? l10n]) {
  final t = dinner.trim();
  return t.isEmpty ? (l10n?.widgetNotPlanned ?? 'Not planned') : t;
}

String shortWidgetText(String value, {int max = 36}) {
  final t = value.trim();
  if (t.length <= max) return t;
  return '${t.substring(0, max - 1)}…';
}

/// Relative age for “Updated …” footers.
String formatWidgetUpdatedAge(
  DateTime updatedAt, {
  DateTime? now,
  AppLocalizations? l10n,
}) {
  final n = now ?? DateTime.now();
  var diff = n.difference(updatedAt);
  if (diff.isNegative) diff = Duration.zero;
  if (diff.inSeconds < 45) return l10n?.widgetJustNow ?? 'just now';
  if (diff.inMinutes < 60) {
    return l10n?.widgetMinutesAgo(diff.inMinutes) ?? '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return l10n?.widgetHoursAgo(diff.inHours) ?? '${diff.inHours}h ago';
  }
  final d = diff.inDays;
  if (d < 7) {
    return l10n?.widgetDaysAgo(d) ?? (d == 1 ? '1d ago' : '${d}d ago');
  }
  return l10n?.widgetEarlier ?? 'earlier';
}
