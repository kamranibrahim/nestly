import 'package:flutter/material.dart';

/// FamilyWall-inspired: bright blue primary, white surfaces, colorful module accents.
abstract final class AppColors {
  static const Color primary = Color(0xFF4A78DD);
  static const Color primaryDark = Color(0xFF3A63C2);
  static const Color primarySoft = Color(0xFFE8EFFC);
  static const Color primaryWash = Color(0xFFF3F7FE);

  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE6EAF2);

  static const Color ink = Color(0xFF1C1F26);
  static const Color inkSecondary = Color(0xFF5C6578);
  static const Color inkMuted = Color(0xFF9AA3B5);

  static const Color danger = Color(0xFFE05454);
  static const Color dangerSoft = Color(0xFFFDECEC);

  // Module tile accents (FamilyWall-style colorful hubs)
  static const Color tileBlue = Color(0xFF4A78DD);
  static const Color tileGreen = Color(0xFF3CB371);
  static const Color tileOrange = Color(0xFFF29B4A);
  static const Color tilePink = Color(0xFFE56B9A);
  static const Color tilePurple = Color(0xFF7B6CDB);
  static const Color tileTeal = Color(0xFF2EB8B0);
  static const Color tileYellow = Color(0xFFE8B84A);
  static const Color tileRed = Color(0xFFE05454);

  static const List<Color> memberColors = [
    Color(0xFF4A78DD),
    Color(0xFFE56B9A),
    Color(0xFF3CB371),
    Color(0xFFF29B4A),
    Color(0xFF7B6CDB),
    Color(0xFF2EB8B0),
  ];
}
