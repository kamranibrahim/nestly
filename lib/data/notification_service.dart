import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'db/app_database.dart';
import '../navigation/app_navigator.dart';
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
      await _local.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'nestly_general',
            'Nestly',
            channelDescription: 'Family reminders and updates',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
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

  /// Bills + care + school — prefer this after any schedule change.
  Future<void> rescheduleReminders() async {
    if (!_ready) return;
    await _local.cancelAll();
    await _scheduleBillReminders();
    await _scheduleCareReminders();
    await _scheduleSchoolReminders();
    await _scheduleTomorrowPreview();
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

  Future<void> _scheduleTomorrowPreview() async {
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

    final parts = <String>[];
    if (billCount > 0) parts.add(_countLabel(billCount, 'bill'));
    if (careCount > 0) parts.add(_countLabel(careCount, 'care task'));
    if (schoolCount > 0) parts.add(_countLabel(schoolCount, 'school item'));
    if (parts.isEmpty) return;

    final when = tz.TZDateTime.from(previewAt, tz.local);
    await _local.zonedSchedule(
      id: 4000,
      title: 'Tomorrow in Nestly',
      body: '${parts.join(', ')} due tomorrow',
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'nestly_preview',
          'Tomorrow preview',
          channelDescription: 'A quiet evening look at tomorrow',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  bool _isSameDayWindow(DateTime value, DateTime start, DateTime end) {
    return !value.isBefore(start) && value.isBefore(end);
  }

  String _countLabel(int count, String singular) {
    return count == 1 ? '1 $singular' : '$count ${singular}s';
  }

  Future<void> _scheduleBillReminders() async {
    final bills = await BillRepository(_db).getUnpaidUpcoming();
    var i = 0;
    for (final bill in bills) {
      final remindAt = bill.dueAt.subtract(const Duration(days: 1));
      if (remindAt.isBefore(DateTime.now())) continue;
      final when = tz.TZDateTime.from(remindAt, tz.local);
      await _local.zonedSchedule(
        id: 1000 + i,
        title: 'Bill due tomorrow',
        body: '${bill.title} · \$${bill.amount.toStringAsFixed(2)}',
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'nestly_bills',
            'Bills',
            channelDescription: 'Reminders before household bills are due',
            importance: Importance.high,
          ),
          iOS: DarwinNotificationDetails(),
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

  Future<void> _scheduleCareReminders() async {
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
      final label = item.category == 'Elder' ? 'Elder care due' : 'Care due';
      await _local.zonedSchedule(
        id: 2000 + i,
        title: label,
        body: item.title,
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'nestly_care',
            'Care',
            channelDescription: 'Reminders for household and elder care',
            importance: Importance.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: const NotificationIntent(NotificationDestination.care).payload,
      );
      i++;
      if (i >= 20) break;
    }
  }

  Future<void> _scheduleSchoolReminders() async {
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
        title: 'School / pickup',
        body: item.title,
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'nestly_school',
            'School',
            channelDescription: 'Reminders for school runs and activities',
            importance: Importance.high,
          ),
          iOS: DarwinNotificationDetails(),
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
}
