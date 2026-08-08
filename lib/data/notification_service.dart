import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';
import '../navigation/app_navigator.dart';
import 'app_l10n.dart';
import 'db/app_database.dart';
import 'enums.dart';
import 'repositories.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.messageId}');
}

class NotificationService {
  NotificationService(this._db);

  final AppDatabase _db;
  final _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) {
      await _consumeLaunchIntents();
      return;
    }
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Simulator / first launch often has no APNS token yet — don't fail init.
    try {
      final token = await _messaging.getToken();
      debugPrint('Firebase Token : $token');
      await _saveToken(token);
    } catch (e) {
      final text = e.toString();
      if (text.contains('apns-token-not-set') ||
          text.contains('APNS token has not been received')) {
        debugPrint('FCM token deferred until APNS is ready');
      } else {
        debugPrint('FCM getToken skipped: $e');
      }
    }
    _messaging.onTokenRefresh.listen(_saveToken);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteTap);

    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification == null) return;
      final payload = NotificationIntent.fromMessageData(message.data)?.payload;
      final l10n = await resolvedAppLocalizations(_db);
      await _local.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'nestly_general',
            l10n.notifChannelGeneral,
            channelDescription: l10n.notifChannelGeneralDesc,
            importance: Importance.defaultImportance,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: payload,
      );
    });

    _ready = true;
    // Handle notification taps before the slow cancel/reschedule pass so cold
    // starts from a reminder open the destination immediately.
    await _consumeLaunchIntents();
    unawaited(rescheduleReminders());
  }

  Future<void> _saveToken(String? token) async {
    if (token == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Immediate local alert when the signed-in member is @mentioned.
  Future<void> showTimelineMention({
    required String authorName,
    required String preview,
  }) async {
    if (!_ready) return;
    final l10n = await resolvedAppLocalizations(_db);
    final body = preview.length > 120 ? '${preview.substring(0, 117)}…' : preview;
    await _local.show(
      id: preview.hashCode,
      title: l10n.notifTimelineMentionTitle(authorName),
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'nestly_timeline',
          l10n.notifChannelTimeline,
          channelDescription: l10n.notifChannelTimelineDesc,
          importance: Importance.defaultImportance,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: const NotificationIntent(
        NotificationDestination.timeline,
      ).payload,
    );
  }

  /// Bills + care + school + events + tasks — prefer this after any schedule change.
  Future<void> rescheduleReminders() async {
    if (!_ready) return;
    await _local.cancelAll();
    final l10n = await resolvedAppLocalizations(_db);
    await _scheduleBillReminders(l10n);
    await _scheduleCareReminders(l10n);
    await _scheduleSchoolReminders(l10n);
    await _scheduleEventReminders(l10n);
    await _scheduleTaskReminders(l10n);
    await _scheduleTomorrowPreview(l10n);
  }

  /// Kept for existing call sites.
  Future<void> rescheduleBillReminders() => rescheduleReminders();

  Future<void> _consumeLaunchIntents() async {
    final launchDetails = await _local.getNotificationAppLaunchDetails();
    final localPayload = launchDetails?.didNotificationLaunchApp == true
        ? launchDetails?.notificationResponse?.payload
        : null;
    _openPayload(localPayload);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteTap(initialMessage);
    }
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    _openPayload(response.payload);
  }

  void _handleRemoteTap(RemoteMessage message) {
    final intent = NotificationIntent.fromMessageData(message.data);
    if (intent == null) return;
    openNotificationIntent(intent);
  }

  void _openPayload(String? payload) {
    final intent = NotificationIntent.fromPayload(payload);
    if (intent == null) return;
    openNotificationIntent(intent);
  }

  Future<void> _scheduleTomorrowPreview(AppLocalizations l10n) async {
    final enabled = await ExpenseRepository(_db).getTomorrowPreviewEnabled();
    if (!enabled) return;

    final now = DateTime.now();
    final previewToday = DateTime(now.year, now.month, now.day, 19, 30);
    final previewAt = previewToday.isAfter(now)
        ? previewToday
        : DateTime(now.year, now.month, now.day + 1, 19, 30);
    final targetDay = DateTime(
      previewAt.year,
      previewAt.month,
      previewAt.day + 1,
    );
    final nextDay = targetDay.add(const Duration(days: 1));

    final bills = await BillRepository(_db).watchAll().first;
    final careItems = await CareRepository(_db).watchAll().first;
    final schoolItems = await SchoolRepository(_db).watchAll().first;
    final events = await (_db.select(_db.calendarEvents)
          ..where((e) => e.deleted.equals(false)))
        .get();
    final tasks = await (_db.select(_db.tasks)
          ..where((t) => t.done.equals(false) & t.deleted.equals(false)))
        .get();

    final billCount = bills
        .where(
          (bill) =>
              !bill.paid && _isSameDayWindow(bill.dueAt, targetDay, nextDay),
        )
        .length;
    final careCount = careItems
        .where(
          (item) =>
              !item.deleted &&
              _isSameDayWindow(item.nextDueAt, targetDay, nextDay),
        )
        .length;
    final schoolCount = schoolItems
        .where(
          (item) =>
              !item.deleted &&
              _isSameDayWindow(item.nextAt, targetDay, nextDay),
        )
        .length;
    final eventCount = events
        .where((e) => _isSameDayWindow(e.startsAt, targetDay, nextDay))
        .length;
    final taskCount = tasks
        .where((t) {
          final due = _dueDateForTask(t, now: previewAt);
          return due != null && _isSameDayWindow(due, targetDay, nextDay);
        })
        .length;

    final parts = <String>[];
    if (billCount > 0) parts.add(l10n.notifBillCount(billCount));
    if (careCount > 0) parts.add(l10n.notifCareCount(careCount));
    if (schoolCount > 0) parts.add(l10n.notifSchoolCount(schoolCount));
    if (eventCount > 0) parts.add(l10n.notifEventCount(eventCount));
    if (taskCount > 0) parts.add(l10n.notifTaskCount(taskCount));
    if (parts.isEmpty) return;

    final when = tz.TZDateTime.from(previewAt, tz.local);
    await _local.zonedSchedule(
      id: 4000,
      title: l10n.notifTomorrowTitle,
      body: l10n.notifTomorrowBody(parts.join(', ')),
      scheduledDate: when,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'nestly_preview',
          l10n.notifChannelPreview,
          channelDescription: l10n.notifChannelPreviewDesc,
          importance: Importance.defaultImportance,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  bool _isSameDayWindow(DateTime value, DateTime start, DateTime end) {
    return !value.isBefore(start) && value.isBefore(end);
  }

  Future<void> _scheduleBillReminders(AppLocalizations l10n) async {
    final bills = await BillRepository(_db).getUnpaidUpcoming();
    var i = 0;
    for (final bill in bills) {
      final remindAt = bill.dueAt.subtract(const Duration(days: 1));
      if (remindAt.isBefore(DateTime.now())) continue;
      final when = tz.TZDateTime.from(remindAt, tz.local);
      await _local.zonedSchedule(
        id: 1000 + i,
        title: l10n.notifBillDueTomorrow,
        body: l10n.notifBillBody(
          bill.title,
          bill.amount.toStringAsFixed(2),
        ),
        scheduledDate: when,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'nestly_bills',
            l10n.notifChannelBills,
            channelDescription: l10n.notifChannelBillsDesc,
            importance: Importance.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: const NotificationIntent(
          NotificationDestination.bills,
        ).payload,
      );
      i++;
      if (i >= 20) break;
    }
  }

  Future<void> _scheduleCareReminders(AppLocalizations l10n) async {
    final now = DateTime.now();
    final endTomorrow = DateTime(now.year, now.month, now.day + 1, 23, 59, 59);
    final items =
        await (_db.select(_db.careItems)
              ..where(
                (c) =>
                    c.deleted.equals(false) &
                    c.nextDueAt.isSmallerOrEqualValue(endTomorrow),
              )
              ..orderBy([(c) => OrderingTerm(expression: c.nextDueAt)]))
            .get();

    var i = 0;
    for (final item in items) {
      final dueMorning = DateTime(
        item.nextDueAt.year,
        item.nextDueAt.month,
        item.nextDueAt.day,
        8,
      );
      var remindAt = dueMorning;
      if (!remindAt.isAfter(now)) {
        remindAt = now.add(const Duration(hours: 1));
      }
      if (!remindAt.isAfter(now)) continue;

      final when = tz.TZDateTime.from(remindAt, tz.local);
      final label = item.category == 'Elder'
          ? l10n.notifElderCareDue
          : l10n.notifCareDue;
      await _local.zonedSchedule(
        id: 2000 + i,
        title: label,
        body: item.title,
        scheduledDate: when,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'nestly_care',
            l10n.notifChannelCare,
            channelDescription: l10n.notifChannelCareDesc,
            importance: Importance.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: const NotificationIntent(NotificationDestination.care).payload,
      );
      i++;
      if (i >= 20) break;
    }
  }

  Future<void> _scheduleSchoolReminders(AppLocalizations l10n) async {
    final now = DateTime.now();
    final endTomorrow = DateTime(now.year, now.month, now.day + 1, 23, 59, 59);
    final items =
        await (_db.select(_db.schoolActivities)
              ..where(
                (s) =>
                    s.deleted.equals(false) &
                    s.nextAt.isSmallerOrEqualValue(endTomorrow),
              )
              ..orderBy([(s) => OrderingTerm(expression: s.nextAt)]))
            .get();

    var i = 0;
    for (final item in items) {
      final dueMorning = DateTime(
        item.nextAt.year,
        item.nextAt.month,
        item.nextAt.day,
        7,
        30,
      );
      var remindAt = dueMorning;
      if (!remindAt.isAfter(now)) {
        remindAt = now.add(const Duration(minutes: 45));
      }
      if (!remindAt.isAfter(now)) continue;

      final when = tz.TZDateTime.from(remindAt, tz.local);
      await _local.zonedSchedule(
        id: 3000 + i,
        title: l10n.notifSchoolPickup,
        body: item.title,
        scheduledDate: when,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'nestly_school',
            l10n.notifChannelSchool,
            channelDescription: l10n.notifChannelSchoolDesc,
            importance: Importance.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: const NotificationIntent(
          NotificationDestination.school,
        ).payload,
      );
      i++;
      if (i >= 20) break;
    }
  }

  Future<void> _scheduleEventReminders(AppLocalizations l10n) async {
    final now = DateTime.now();
    final horizon = now.add(const Duration(days: 3));
    final events =
        await (_db.select(_db.calendarEvents)
              ..where(
                (e) =>
                    e.deleted.equals(false) &
                    e.startsAt.isBiggerThanValue(now) &
                    e.startsAt.isSmallerOrEqualValue(horizon),
              )
              ..orderBy([(e) => OrderingTerm(expression: e.startsAt)]))
            .get();

    var i = 0;
    for (final event in events) {
      var remindAt = event.startsAt.subtract(const Duration(minutes: 30));
      if (!remindAt.isAfter(now)) {
        remindAt = now.add(const Duration(minutes: 5));
      }
      if (!remindAt.isAfter(now) || !remindAt.isBefore(event.startsAt)) {
        continue;
      }

      final when = tz.TZDateTime.from(remindAt, tz.local);
      await _local.zonedSchedule(
        id: 5000 + i,
        title: l10n.notifComingUp,
        body: event.title,
        scheduledDate: when,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'nestly_events',
            l10n.notifChannelEvents,
            channelDescription: l10n.notifChannelEventsDesc,
            importance: Importance.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: const NotificationIntent(
          NotificationDestination.calendar,
        ).payload,
      );
      i++;
      if (i >= 20) break;
    }
  }

  Future<void> _scheduleTaskReminders(AppLocalizations l10n) async {
    final now = DateTime.now();
    final tasks =
        await (_db.select(_db.tasks)
              ..where((t) => t.done.equals(false) & t.deleted.equals(false))
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
            .get();

    var i = 0;
    for (final task in tasks) {
      final dueDay = _dueDateForTask(task, now: now);
      if (dueDay == null) continue;
      var remindAt = DateTime(dueDay.year, dueDay.month, dueDay.day, 9);
      if (!remindAt.isAfter(now)) {
        remindAt = now.add(const Duration(hours: 1));
      }
      if (!remindAt.isAfter(now)) continue;
      // Skip far-future labels beyond a week.
      if (remindAt.isAfter(now.add(const Duration(days: 8)))) continue;

      final when = tz.TZDateTime.from(remindAt, tz.local);
      await _local.zonedSchedule(
        id: 6000 + i,
        title: l10n.notifTaskDue,
        body: task.title,
        scheduledDate: when,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'nestly_tasks',
            l10n.notifChannelTasks,
            channelDescription: l10n.notifChannelTasksDesc,
            importance: Importance.defaultImportance,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: const NotificationIntent(
          NotificationDestination.tasks,
        ).payload,
      );
      i++;
      if (i >= 20) break;
    }
  }
}

/// Maps a task to its calendar due day, preferring [Task.dueAt].
DateTime? _dueDateForTask(Task task, {required DateTime now}) {
  if (task.dueAt != null) {
    final d = task.dueAt!;
    return DateTime(d.year, d.month, d.day);
  }
  return TaskDueLabel.dueDateFor(task.dueLabel, now: now);
}
