/// Pure Nestly Home Widget snapshot helpers (no plugins).
library;

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
}) {
  final event = nextEvent.trim();
  final meal = dinner.trim();

  if (openTasks > 0) {
    final label = openTasks == 1 ? '1 open task' : '$openTasks open tasks';
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
  return const WidgetHeroSelection(
    kind: WidgetHeroKind.quiet,
    title: 'Quiet day · enjoy it',
    accent: 'mint',
  );
}

String formatWidgetTasksLabel(int openTasks) {
  if (openTasks <= 0) return 'All clear';
  return openTasks == 1 ? '1 open' : '$openTasks open';
}

String formatWidgetEventLabel(String nextEvent) {
  final t = nextEvent.trim();
  return t.isEmpty ? 'Nothing scheduled' : t;
}

String formatWidgetDinnerLabel(String dinner) {
  final t = dinner.trim();
  return t.isEmpty ? 'Not planned' : t;
}

String shortWidgetText(String value, {int max = 36}) {
  final t = value.trim();
  if (t.length <= max) return t;
  return '${t.substring(0, max - 1)}…';
}

/// Relative age for “Updated …” footers.
String formatWidgetUpdatedAge(DateTime updatedAt, {DateTime? now}) {
  final n = now ?? DateTime.now();
  var diff = n.difference(updatedAt);
  if (diff.isNegative) diff = Duration.zero;
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return m == 1 ? '1m ago' : '${m}m ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return h == 1 ? '1h ago' : '${h}h ago';
  }
  final d = diff.inDays;
  if (d < 7) return d == 1 ? '1d ago' : '${d}d ago';
  return 'earlier';
}
