import 'package:flutter/material.dart';

import '../screens/care_screen.dart';
import '../screens/expenses_screen.dart';
import '../screens/school_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

enum NotificationDestination { bills, care, school }

class NotificationIntent {
  const NotificationIntent(this.destination);

  final NotificationDestination destination;

  String get payload => switch (destination) {
    NotificationDestination.bills => 'bills',
    NotificationDestination.care => 'care',
    NotificationDestination.school => 'school',
  };

  static NotificationIntent? fromPayload(String? payload) {
    switch (payload?.trim().toLowerCase()) {
      case 'bills':
      case 'budget':
        return const NotificationIntent(NotificationDestination.bills);
      case 'care':
        return const NotificationIntent(NotificationDestination.care);
      case 'school':
        return const NotificationIntent(NotificationDestination.school);
      default:
        return null;
    }
  }

  static NotificationIntent? fromMessageData(Map<String, dynamic> data) {
    final raw = data['nestly_route'] ?? data['route'] ?? data['screen'];
    return fromPayload(raw?.toString());
  }
}

void openNotificationIntent(NotificationIntent intent) {
  _pushWhenReady(intent, attempt: 0);
}

void _pushWhenReady(NotificationIntent intent, {required int attempt}) {
  final navigator = rootNavigatorKey.currentState;
  if (navigator == null) {
    if (attempt >= 8) return;
    Future<void>.delayed(
      const Duration(milliseconds: 180),
      () => _pushWhenReady(intent, attempt: attempt + 1),
    );
    return;
  }

  final route = MaterialPageRoute<void>(
    builder: (_) => switch (intent.destination) {
      NotificationDestination.bills => const ExpensesScreen(),
      NotificationDestination.care => const CareScreen(),
      NotificationDestination.school => const SchoolScreen(),
    },
  );
  navigator.push(route);
}
