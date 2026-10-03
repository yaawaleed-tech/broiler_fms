import 'package:flutter/material.dart';

/// The shared color palette and typography for the whole app, mobile
/// and web alike. Lifted directly from the HTML mockups, all four of
/// which use the exact same values, so this file is the single source
/// of truth rather than four copies.
class AppColors {
  AppColors._();

  static const bgPage = Color(0xFFEFE9D8);
  static const parchment = Color(0xFFF5EFDE);
  static const card = Color(0xFFFBF8F1);
  static const ink = Color(0xFF2B2620);
  static const inkMuted = Color(0xFF5A4E3E);
  static const hairline = Color(0xFFD9CFBB);
  static const hairlineStrong = Color(0xFFB9AC8D);
  static const rust = Color(0xFFA8442A);
  static const rustDark = Color(0xFF7E3320);
  static const olive = Color(0xFF4B6B33);
  static const oliveBg = Color(0xFFE4EAD9);
  static const amber = Color(0xFFC08A28);
  static const amberBg = Color(0xFFF5E9CE);
  static const brick = Color(0xFF8C2F26);
  static const brickBg = Color(0xFFF5E1DE);
}

/// Builds the app's [ThemeData]. Headings use Roboto Slab, body text
/// uses Public Sans, matching the mockups exactly. Both fonts need to
/// be added to pubspec.yaml's fonts section before this will render
/// correctly, see the note at the bottom of this file.
ThemeData buildAppTheme() {
  return ThemeData(
    scaffoldBackgroundColor: AppColors.bgPage,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.rust,
      primary: AppColors.rust,
      surface: AppColors.card,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontFamily: 'RobotoSlab',
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      titleMedium: TextStyle(
        fontFamily: 'RobotoSlab',
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'PublicSans',
        color: AppColors.ink,
      ),
      bodySmall: TextStyle(
        fontFamily: 'PublicSans',
        color: AppColors.inkMuted,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.rust,
        foregroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.hairlineStrong, width: 1.5),
      ),
    ),
  );
}

// NOTE: Roboto Slab and Public Sans are loaded via Google Fonts in the
// HTML mockups, which Flutter cannot do the same way. Two options:
// 1. Add the google_fonts package and use GoogleFonts.robotoSlab()/
//    publicSans() directly instead of named TextStyle families here.
// 2. Download both font files and bundle them in pubspec.yaml's
//    fonts section, matching the 'RobotoSlab' / 'PublicSans' family
//    names used above.
// Neither is set up yet. This is a real decision needed before any
// screen's text will actually look like the mockups rather than
// falling back to the system default font.