import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'db/app_database.dart';
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
    if (_ready) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Simulator / first launch often has no APNS token yet — don't fail init.
    try {
      final token = await _messaging.getToken();
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

    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification == null) return;
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
      );
    });

    _ready = true;
    await rescheduleReminders();
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
  }

  /// Kept for existing call sites.
  Future<void> rescheduleBillReminders() => rescheduleReminders();

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
      );
      i++;
      if (i >= 20) break;
    }
  }

  Future<void> _scheduleCareReminders() async {
    final now = DateTime.now();
    final endTomorrow = DateTime(now.year, now.month, now.day + 1, 23, 59, 59);
    final items = await (_db.select(_db.careItems)
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
      );
      i++;
      if (i >= 20) break;
    }
  }

  Future<void> _scheduleSchoolReminders() async {
    final now = DateTime.now();
    final endTomorrow = DateTime(now.year, now.month, now.day + 1, 23, 59, 59);
    final items = await (_db.select(_db.schoolActivities)
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
      );
      i++;
      if (i >= 20) break;
    }
  }
}
