import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper so Analytics/Crashlytics stay out of screens and never break tests.
class NestlyTelemetry {
  NestlyTelemetry._();

  static bool _ready = false;

  /// Call after [Firebase.initializeApp] on mobile. No-op on web.
  static Future<void> init() async {
    if (kIsWeb) return;

    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Collect in all builds so soft-launch crashes are visible; disable only if
    // you need quiet local runs via --dart-define=DISABLE_CRASHLYTICS=true.
    const disable = bool.fromEnvironment('DISABLE_CRASHLYTICS');
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!disable);

    _ready = true;
  }

  static Future<void> signUp() => _safe(() async {
        await FirebaseAnalytics.instance.logSignUp(signUpMethod: 'email');
      });

  static Future<void> login() => _safe(() async {
        await FirebaseAnalytics.instance.logLogin(loginMethod: 'email');
      });

  static Future<void> nestCreated() => _event('nest_created');

  static Future<void> nestJoined() => _event('nest_joined');

  static Future<void> passwordResetRequested() =>
      _event('password_reset_requested');

  static Future<void> changePasswordSuccess() =>
      _event('change_password_success');

  static Future<void> syncSuccess() => _event('sync_success');

  static Future<void> syncFail({required String reason}) => _event(
        'sync_fail',
        {'reason': _sanitizeReason(reason)},
      );

  static Future<void> homeOpen() => _event('home_open');

  /// Non-fatal sync (or other) failure — never pass emails, nest names, or row content.
  static Future<void> recordNonFatal(
    Object error,
    StackTrace stack, {
    String? reason,
  }) =>
      _safe(() async {
        if (!_ready) return;
        final code = reason ?? _errorCode(error);
        await FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          fatal: false,
          reason: 'sync:$code',
        );
      });

  static Future<void> _event(
    String name, [
    Map<String, Object>? parameters,
  ]) =>
      _safe(() async {
        if (!_ready) return;
        await FirebaseAnalytics.instance.logEvent(
          name: name,
          parameters: parameters,
        );
      });

  static Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (e, st) {
      debugPrint('Telemetry skipped: $e\n$st');
    }
  }

  static String _errorCode(Object error) {
    if (error is FirebaseException) {
      return error.code;
    }
    return error.runtimeType.toString();
  }

  static String _sanitizeReason(String reason) {
    final cleaned = reason.trim().replaceAll(RegExp(r'[^\w.\-]'), '_');
    if (cleaned.isEmpty) return 'unknown';
    return cleaned.length > 40 ? cleaned.substring(0, 40) : cleaned;
  }
}
