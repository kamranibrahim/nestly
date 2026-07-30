import 'package:flutter/material.dart';

/// Soft pastel productivity system: lime + lavender on white, charcoal contrast.
abstract final class AppColors {
  static const Color primary = Color(0xFF1C1C1E);
  static const Color primaryDark = Color(0xFF000000);
  static const Color primarySoft = Color(0xFFF2F2F4);
  static const Color primaryWash = Color(0xFFFAFAFB);

  static const Color accent = Color(0xFFB2B2E6);
  static const Color accentDeep = Color(0xFF8E8ED4);
  static const Color mint = Color(0xFFD4E7B3);
  static const Color mintDeep = Color(0xFFB5CF8A);

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF7F7F8);
  static const Color divider = Color(0xFFE8E8EC);
  static const Color border = Color(0xFFE5E5EA);

  static const Color ink = Color(0xFF1C1C1E);
  static const Color white = Colors.white;
  static const Color inkSecondary = Color(0xFF636366);
  static const Color inkMuted = Color(0xFF8E8E93);
  static const Color onDark = Color(0xFFFFFFFF);

  static const Color navBar = Color(0xFF2C2C2E);
  static const Color navPill = Color(0xFFFFFFFF);

  static const Color danger = Color(0xFFE05454);
  static const Color dangerSoft = Color(0xFFFDECEC);

  // Module / card accents (pastel)
  static const Color tileBlue = Color(0xFFB2B2E6);
  static const Color tileGreen = Color(0xFFD4E7B3);
  static const Color tileOrange = Color(0xFFFFD8A8);
  static const Color tilePink = Color(0xFFF5C6D8);
  static const Color tilePurple = Color(0xFFB2B2E6);
  static const Color tileTeal = Color(0xFFC5E8E0);
  static const Color tileYellow = Color(0xFFF5E6A8);
  static const Color tileRed = Color(0xFFF5C6C6);

  static const List<Color> memberColors = [
    Color(0xFFB2B2E6),
    Color(0xFFD4E7B3),
    Color(0xFFFFD8A8),
    Color(0xFFF5C6D8),
    Color(0xFFC5E8E0),
    Color(0xFFF5E6A8),
  ];

  static const List<Color> softCardColors = [
    Color(0xFFD4E7B3),
    Color(0xFFB2B2E6),
    Color(0xFFFFD8A8),
    Color(0xFFF5C6D8),
    Color(0xFFC5E8E0),
  ];

  /// Punchier fill for [MemberAvatar] — stored member colors stay soft for cards.
  static Color avatarFill(Color pastel) {
    final hsl = HSLColor.fromColor(pastel);
    return hsl
        .withSaturation((hsl.saturation * 1.4 + 0.1).clamp(0.48, 0.82))
        .withLightness((hsl.lightness - 0.16).clamp(0.44, 0.64))
        .toColor();
  }
}
