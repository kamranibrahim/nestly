import 'package:flutter/material.dart';

import '../data/enums.dart';
import '../data/nest_home_widget.dart';
import '../screens/care_screen.dart';
import '../screens/expenses_screen.dart';
import '../screens/meals_screen.dart';
import '../screens/school_screen.dart';

export '../data/enums.dart' show NotificationDestination, CasaioDeepLink;

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Tab indexes in [AppShell] — keep in sync with `lib/screens/app_shell.dart`.
abstract final class CasaioShellTab {
  static const home = 0;
  static const calendar = 1;
  static const tasks = 2;
  static const shopping = 3;
  static const more = 4;
}

class NotificationIntent {
  const NotificationIntent(this.destination);

  final NotificationDestination destination;

  String get payload => destination.payload;

  static NotificationIntent? fromPayload(String? payload) {
    final destination = NotificationDestination.tryParse(payload);
    if (destination == null) return null;
    return NotificationIntent(destination);
  }

  static NotificationIntent? fromMessageData(Map<String, dynamic> data) {
    final raw = data['nestly_route'] ?? data['route'] ?? data['screen'];
    return fromPayload(raw?.toString());
  }
}

void openNotificationIntent(NotificationIntent intent) {
  switch (intent.destination) {
    case NotificationDestination.calendar:
      nestlyShellTabRequest.value = CasaioShellTab.calendar;
      return;
    case NotificationDestination.tasks:
      nestlyShellTabRequest.value = CasaioShellTab.tasks;
      return;
    case NotificationDestination.bills:
    case NotificationDestination.care:
    case NotificationDestination.school:
      _pushWhenReady(
        (_) => switch (intent.destination) {
          NotificationDestination.bills => const ExpensesScreen(),
          NotificationDestination.care => const CareScreen(),
          NotificationDestination.school => const SchoolScreen(),
          NotificationDestination.calendar ||
          NotificationDestination.tasks =>
            throw StateError('unreachable'),
        },
        attempt: 0,
      );
  }
}

/// Handles `casaio://…` launches from the Home Screen widget (and similar).
void openCasaioUri(Uri uri) {
  if (uri.scheme != 'casaio' && uri.scheme != 'nestly') return;
  final host = uri.host.toLowerCase();
  final path = uri.path.toLowerCase();
  final key = host.isNotEmpty ? host : path.replaceFirst('/', '');

  switch (CasaioDeepLink.parse(key)) {
    case CasaioDeepLink.home:
      nestlyShellTabRequest.value = CasaioShellTab.home;
    case CasaioDeepLink.calendar:
      nestlyShellTabRequest.value = CasaioShellTab.calendar;
    case CasaioDeepLink.tasks:
      nestlyShellTabRequest.value = CasaioShellTab.tasks;
    case CasaioDeepLink.meals:
      _pushWhenReady((_) => const MealsScreen(), attempt: 0);
    case CasaioDeepLink.shopping:
      nestlyShellTabRequest.value = CasaioShellTab.shopping;
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
void openCasaioUriString(String? raw) {
  if (raw == null || raw.trim().isEmpty) return;
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return;
  openCasaioUri(uri);
}

// Re-export URI constants for navigation tests.
const nestlyHomeUri = NestHomeWidget.launchUri;
const nestlyTasksUri = NestHomeWidget.tasksUri;
const nestlyCalendarUri = NestHomeWidget.calendarUri;
const nestlyMealsUri = NestHomeWidget.mealsUri;
