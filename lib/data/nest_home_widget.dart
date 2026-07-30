import 'dart:io' show Platform;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import 'db/app_database.dart';

/// Shared App Group + WidgetKit kind for the Nestly Home Screen widget.
abstract final class NestHomeWidget {
  static const appGroupId = 'group.app.nestly.family';
  static const iOSName = 'NestlyHomeWidget';
  static const androidName = 'NestlyHomeWidget';
  static const launchUri = 'nestly://home';

  static bool get _supported =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  static Future<void> ensureConfigured() async {
    if (!_supported) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (_) {}
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
      nextEvent = '${_short(e.title)} · $when';
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
        : _short(dinnerRows.first.title.trim());

    return _WidgetSnapshot(
      openTasks: openTasks,
      nextEvent: nextEvent,
      dinner: dinner,
      nestName: nestLabel.isEmpty ? 'Nestly' : _short(nestLabel, max: 24),
      hasNest: true,
    );
  }

  static String _short(String value, {int max = 36}) {
    final t = value.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max - 1)}…';
  }
}

class _WidgetSnapshot {
  const _WidgetSnapshot({
    required this.openTasks,
    required this.nextEvent,
    required this.dinner,
    required this.nestName,
    required this.hasNest,
  });

  final int openTasks;
  final String nextEvent;
  final String dinner;
  final String nestName;
  final bool hasNest;
}
