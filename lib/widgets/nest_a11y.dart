import 'package:flutter/material.dart';

/// Shared accessibility helpers for Nestly UI.
abstract final class NestA11y {
  /// True when the user prefers reduced motion (or animations are disabled).
  static bool reduceMotion(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return false;
    return mq.disableAnimations || mq.accessibleNavigation;
  }
}
