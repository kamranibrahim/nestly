import 'package:flutter/material.dart';

import '../data/nest_home_widget.dart';
import '../screens/care_screen.dart';
import '../screens/expenses_screen.dart';
import '../screens/meals_screen.dart';
import '../screens/school_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Tab indexes in [AppShell] — keep in sync with `lib/screens/app_shell.dart`.
abstract final class NestlyShellTab {
  static const home = 0;
  static const calendar = 1;
  static const tasks = 2;
  static const shopping = 3;
  static const more = 4;
}

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
  _pushWhenReady(
    (_) => switch (intent.destination) {
      NotificationDestination.bills => const ExpensesScreen(),
      NotificationDestination.care => const CareScreen(),
      NotificationDestination.school => const SchoolScreen(),
    },
    attempt: 0,
  );
}

/// Handles `nestly://…` launches from the Home Screen widget (and similar).
void openNestlyUri(Uri uri) {
  if (uri.scheme != 'nestly') return;
  final host = uri.host.toLowerCase();
  final path = uri.path.toLowerCase();
  final key = host.isNotEmpty ? host : path.replaceFirst('/', '');

  switch (key) {
    case 'home':
    case '':
      nestlyShellTabRequest.value = NestlyShellTab.home;
      return;
    case 'calendar':
      nestlyShellTabRequest.value = NestlyShellTab.calendar;
      return;
    case 'tasks':
      nestlyShellTabRequest.value = NestlyShellTab.tasks;
      return;
    case 'meals':
    case 'dinner':
      _pushWhenReady((_) => const MealsScreen(), attempt: 0);
      return;
    case 'shopping':
      nestlyShellTabRequest.value = NestlyShellTab.shopping;
      return;
    default:
      // Unknown — open home.
      nestlyShellTabRequest.value = NestlyShellTab.home;
  }
}

/// Latest shell-tab request from widgets / deep links (listened by AppShell).
final ValueNotifier<int?> nestlyShellTabRequest = ValueNotifier<int?>(null);

void _pushWhenReady(
  Widget Function(BuildContext context) builder, {
  required int attempt,
}) {
  final navigator = rootNavigatorKey.currentState;
  if (navigator == null) {
    if (attempt >= 8) return;
    Future<void>.delayed(
      const Duration(milliseconds: 180),
      () => _pushWhenReady(builder, attempt: attempt + 1),
    );
    return;
  }

  navigator.push(
    MaterialPageRoute<void>(builder: builder),
  );
}

/// Convenience for tests / callers that still have a raw string.
void openNestlyUriString(String? raw) {
  if (raw == null || raw.trim().isEmpty) return;
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return;
  openNestlyUri(uri);
}

// Re-export URI constants for navigation tests.
const nestlyHomeUri = NestHomeWidget.launchUri;
const nestlyTasksUri = NestHomeWidget.tasksUri;
const nestlyCalendarUri = NestHomeWidget.calendarUri;
const nestlyMealsUri = NestHomeWidget.mealsUri;
