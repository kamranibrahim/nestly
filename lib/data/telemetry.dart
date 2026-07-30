import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper so Analytics/Crashlytics stay out of screens and never break tests.
///
/// Crashlytics is mobile-only. Accessing it when the native plugin is missing
/// (web, incomplete install, hot-reload without rebuild) asserts — and if that
/// assertion is fed back into [PlatformDispatcher.onError], it loops forever.
class NestlyTelemetry {
  NestlyTelemetry._();

  static bool _analyticsReady = false;
  static bool _crashlyticsReady = false;
  static bool _handlingError = false;

  /// Call after [Firebase.initializeApp] on mobile. No-op on web.
  static Future<void> init() async {
    if (kIsWeb) return;

    // Analytics first — independent of Crashlytics native wiring.
    _analyticsReady = true;

    _crashlyticsReady = await _probeCrashlytics();
    if (!_crashlyticsReady) {
      debugPrint(
        'Crashlytics unavailable — skipping handlers '
        '(full rebuild / pod install may be needed).',
      );
      return;
    }

    final previousFlutterOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      _reportCrashlytics(() {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      });
      previousFlutterOnError?.call(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      // Never re-enter: Crashlytics failures must not call recordError again.
      if (_handlingError || _isCrashlyticsInternal(error)) {
        debugPrint('Uncaught (Crashlytics skipped): $error');
        return true;
      }
      _reportCrashlytics(() {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      });
      return true;
    };
  }

  /// Returns false when the native plugin did not register (common on web,
  /// or after adding the package without a clean rebuild).
  static Future<bool> _probeCrashlytics() async {
    try {
      const disable = bool.fromEnvironment('DISABLE_CRASHLYTICS');
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!disable);
      return true;
    } catch (e, st) {
      debugPrint('Crashlytics probe failed: $e\n$st');
      return false;
    }
  }

  static bool _isCrashlyticsInternal(Object error) {
    final text = error.toString();
    return text.contains('isCrashlyticsCollectionEnabled') ||
        text.contains('FirebaseCrashlytics') ||
        text.contains('firebase_crashlytics');
  }

  static void _reportCrashlytics(void Function() action) {
    if (!_crashlyticsReady || _handlingError) return;
    _handlingError = true;
    try {
      action();
    } catch (e, st) {
      _crashlyticsReady = false;
      debugPrint('Crashlytics report failed; disabling: $e\n$st');
    } finally {
      _handlingError = false;
    }
  }

  static Future<void> signUp() => _safeAnalytics(() async {
        await FirebaseAnalytics.instance.logSignUp(signUpMethod: 'email');
      });

  static Future<void> login() => _safeAnalytics(() async {
        await FirebaseAnalytics.instance.logLogin(loginMethod: 'email');
      });

  static Future<void> nestCreated() => _event('nest_created');

  static Future<void> nestJoined() => _event('nest_joined');

  static Future<void> passwordResetRequested() =>
      _event('password_reset_requested');

  static Future<void> changePasswordSuccess() =>
      _event('change_password_success');

  static Future<void> syncSuccess({int? durationMs}) => _event(
        'sync_success',
        {
          'duration_ms': ?durationMs,
        },
      );

  static Future<void> syncFail({
    required String reason,
    int? durationMs,
  }) =>
      _event(
        'sync_fail',
        {
          'reason': _sanitizeReason(reason),
          'duration_ms': ?durationMs,
        },
      );

  static Future<void> homeOpen() => _event('home_open');

  /// Non-fatal sync (or other) failure — never pass emails, nest names, or row content.
  static Future<void> recordNonFatal(
    Object error,
    StackTrace stack, {
    String? reason,
  }) async {
    if (!_crashlyticsReady) return;
    final code = reason ?? _errorCode(error);
    _reportCrashlytics(() {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: false,
        reason: 'sync:$code',
      );
    });
  }

  static Future<void> _event(
    String name, [
    Map<String, Object>? parameters,
  ]) =>
      _safeAnalytics(() async {
        if (!_analyticsReady) return;
        await FirebaseAnalytics.instance.logEvent(
          name: name,
          parameters: parameters,
        );
      });

  static Future<void> _safeAnalytics(Future<void> Function() action) async {
    try {
      await action();
    } catch (e, st) {
      debugPrint('Analytics skipped: $e\n$st');
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

  /// Whether the native Crashlytics plugin is usable (for Nest debug UI).
  static bool get crashlyticsReady => _crashlyticsReady;
}
