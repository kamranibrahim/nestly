import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import '../widgets/motion.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onDark,
        secondary: AppColors.accent,
        onSecondary: AppColors.ink,
        tertiary: AppColors.mint,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.danger,
        outline: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.background,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const NestPageTransitionsBuilder(),
        },
      ),
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          height: 1.15,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.4),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          height: 1.4,
          color: AppColors.inkSecondary,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onDark,
        elevation: 0,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.primary,
        // Selected bg is near-black; keep check/avatar icons white.
        checkmarkColor: AppColors.onDark,
        secondarySelectedColor: AppColors.primary,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.ink,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.onDark,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink, size: 18),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const CircleBorder(),
        side: const BorderSide(color: AppColors.inkMuted, width: 1.6),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
      ),
    );
  }
}
