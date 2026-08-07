import 'package:flutter/material.dart';

/// Soft, calm motion tokens for Casaio's pastel UI.
abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration page = Duration(milliseconds: 380);
  static const Duration slow = Duration(milliseconds: 480);
  static const Duration stagger = Duration(milliseconds: 45);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve soft = Curves.easeInOutCubic;
  static const Curve springy = Curves.easeOutBack;

  static const double pressScale = 0.96;
  static const Offset enterOffset = Offset(0, 0.04);
}
