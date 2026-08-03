import 'dart:async';
import 'dart:io' show Platform;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import 'db/app_database.dart';
import 'nest_home_widget_snapshot.dart';

/// Shared App Group + WidgetKit kind for the Nestly Home Screen widget.
abstract final class NestHomeWidget {
  static const appGroupId = 'group.app.nestly.family';
  static const iOSName = 'NestlyHomeWidget';
  static const androidName = 'NestlyHomeWidget';

  static const launchUri = 'nestly://home';
  static const tasksUri = 'nestly://tasks';
  static const calendarUri = 'nestly://calendar';
  static const mealsUri = 'nestly://meals';

  static StreamSubscription<Uri?>? _clickSub;
  static void Function(Uri uri)? _onUri;

  static bool get _supported =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  static Future<void> ensureConfigured() async {
    if (!_supported) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (_) {}
  }

  /// Listen for widget taps (cold + warm). Call once after bindings ready.
  static Future<void> bindLaunchHandling(
    void Function(Uri uri) onUri,
  ) async {
    if (!_supported) return;
    _onUri = onUri;
    await ensureConfigured();
    try {
      final initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initial != null) onUri(initial);
    } catch (e) {
      debugPrint('NestHomeWidget initial launch: $e');
    }
    await _clickSub?.cancel();
    _clickSub = HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) _onUri?.call(uri);
    });
  }

  /// Writes a privacy-safe nest snapshot (no vault) and asks WidgetKit to reload.
  static Future<void> publishFromDatabase(
    AppDatabase db, {
    String? nestName,
  }) async {
    if (!_supported) return;
    try {
      await ensureConfigured();
      final snapshot = await _buildSnapshot(db, nestNameOverride: nestName);
      await Future.wait([
        HomeWidget.saveWidgetData<int>('open_tasks', snapshot.openTasks),
        HomeWidget.saveWidgetData<String>('next_event', snapshot.nextEvent),
        HomeWidget.saveWidgetData<String>('dinner', snapshot.dinner),
        HomeWidget.saveWidgetData<String>('nest_name', snapshot.nestName),
        HomeWidget.saveWidgetData<bool>('has_nest', snapshot.hasNest),
        HomeWidget.saveWidgetData<String>(
          'updated_at',
          DateTime.now().toIso8601String(),
        ),
        HomeWidget.saveWidgetData<String>('hero_kind', snapshot.heroKind),
        HomeWidget.saveWidgetData<String>('hero_title', snapshot.heroTitle),
        HomeWidget.saveWidgetData<String>('tasks_label', snapshot.tasksLabel),
        HomeWidget.saveWidgetData<String>('event_label', snapshot.eventLabel),
        HomeWidget.saveWidgetData<String>('dinner_label', snapshot.dinnerLabel),
        HomeWidget.saveWidgetData<String>('accent', snapshot.accent),
      ]);
      await HomeWidget.updateWidget(
        iOSName: iOSName,
        androidName: androidName,
        name: iOSName,
      );
    } catch (e) {
      // Widget is best-effort — never block app flows.
      assert(() {
        // ignore: avoid_print
        print('NestHomeWidget publish skipped: $e');
        return true;
      }());
    }
  }

  /// Clears shared values when signed out / no nest (privacy).
  static Future<void> clear() async {
    if (!_supported) return;
    try {
      await ensureConfigured();
      await Future.wait([
        HomeWidget.saveWidgetData<int>('open_tasks', 0),
        HomeWidget.saveWidgetData<String>('next_event', ''),
        HomeWidget.saveWidgetData<String>('dinner', ''),
        HomeWidget.saveWidgetData<String>('nest_name', ''),
        HomeWidget.saveWidgetData<bool>('has_nest', false),
        HomeWidget.saveWidgetData<String>('updated_at', ''),
        HomeWidget.saveWidgetData<String>('hero_kind', 'quiet'),
        HomeWidget.saveWidgetData<String>('hero_title', ''),
        HomeWidget.saveWidgetData<String>('tasks_label', 'All clear'),
        HomeWidget.saveWidgetData<String>('event_label', 'Nothing scheduled'),
        HomeWidget.saveWidgetData<String>('dinner_label', 'Not planned'),
        HomeWidget.saveWidgetData<String>('accent', 'mint'),
      ]);
      await HomeWidget.updateWidget(
        iOSName: iOSName,
        androidName: androidName,
        name: iOSName,
      );
    } catch (_) {}
  }

  static Future<_WidgetSnapshot> _buildSnapshot(
    AppDatabase db, {
    String? nestNameOverride,
  }) async {
    final nestId = await db.getMeta('nestId');
    final hasNest = nestId != null && nestId.isNotEmpty;
    final nestLabel = (nestNameOverride ?? '').trim();

    if (!hasNest) {
      return const _WidgetSnapshot(
        openTasks: 0,
        nextEvent: '',
        dinner: '',
        nestName: '',
        hasNest: false,
        heroKind: 'quiet',
        heroTitle: 'Open Nestly to join a nest',
        tasksLabel: 'All clear',
        eventLabel: 'Nothing scheduled',
        dinnerLabel: 'Not planned',
        accent: 'mint',
      );
    }

    final openTasks =
        await (db.select(db.tasks)
              ..where((t) => t.done.equals(false) & t.deleted.equals(false)))
            .get()
            .then((rows) => rows.length);

    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    final endHorizon = startToday.add(const Duration(days: 7));
    final events =
        await (db.select(db.calendarEvents)
              ..where(
                (e) =>
                    e.deleted.equals(false) &
                    e.startsAt.isBiggerOrEqualValue(startToday) &
                    e.startsAt.isSmallerThanValue(endHorizon),
              )
              ..orderBy([(e) => OrderingTerm(expression: e.startsAt)])
              ..limit(1))
            .get();

    var nextEvent = '';
    if (events.isNotEmpty) {
      final e = events.first;
      final when = e.allDay
          ? DateFormat.MMMd().format(e.startsAt)
          : DateFormat('EEE · h:mm a').format(e.startsAt);
      nextEvent = '${shortWidgetText(e.title)} · $when';
    }

    final dinnerRows =
        await (db.select(db.mealPlans)
              ..where(
                (m) =>
                    m.deleted.equals(false) &
                    m.weekday.equals(now.weekday) &
                    m.mealType.equals('Dinner'),
              )
              ..limit(1))
            .get();
    final dinner = dinnerRows.isEmpty
        ? ''
        : shortWidgetText(dinnerRows.first.title.trim());

    final hero = selectWidgetHero(
      openTasks: openTasks,
      nextEvent: nextEvent,
      dinner: dinner,
    );

    return _WidgetSnapshot(
      openTasks: openTasks,
      nextEvent: nextEvent,
      dinner: dinner,
      nestName: nestLabel.isEmpty ? 'Nestly' : shortWidgetText(nestLabel, max: 24),
      hasNest: true,
      heroKind: hero.kindKey,
      heroTitle: shortWidgetText(hero.title, max: 40),
      tasksLabel: formatWidgetTasksLabel(openTasks),
      eventLabel: formatWidgetEventLabel(nextEvent),
      dinnerLabel: formatWidgetDinnerLabel(dinner),
      accent: hero.accent,
    );
  }
}

class _WidgetSnapshot {
  const _WidgetSnapshot({
    required this.openTasks,
    required this.nextEvent,
    required this.dinner,
    required this.nestName,
    required this.hasNest,
    required this.heroKind,
    required this.heroTitle,
    required this.tasksLabel,
    required this.eventLabel,
    required this.dinnerLabel,
    required this.accent,
  });

  final int openTasks;
  final String nextEvent;
  final String dinner;
  final String nestName;
  final bool hasNest;
  final String heroKind;
  final String heroTitle;
  final String tasksLabel;
  final String eventLabel;
  final String dinnerLabel;
  final String accent;
}
