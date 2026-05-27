import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Title font: Outfit (clean, geometric, futuristic)
  static final TextStyle titleBase = GoogleFonts.outfit();
  
  // Body font: Inter (neutral, excellent readability at small sizes)
  static final TextStyle bodyBase = GoogleFonts.inter();

  static TextTheme createTextTheme(Color primaryTextColor, Color secondaryTextColor) {
    return TextTheme(
      displayLarge: titleBase.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
        letterSpacing: -1.0,
      ),
      displayMedium: titleBase.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
        letterSpacing: -0.5,
      ),
      displaySmall: titleBase.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
      ),
      headlineLarge: titleBase.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
        letterSpacing: -0.5,
      ),
      headlineMedium: titleBase.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      ),
      headlineSmall: titleBase.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      ),
      titleLarge: titleBase.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      ),
      titleMedium: titleBase.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: primaryTextColor,
        letterSpacing: 0.15,
      ),
      titleSmall: titleBase.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryTextColor,
        letterSpacing: 0.1,
      ),
      bodyLarge: bodyBase.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: primaryTextColor,
        letterSpacing: 0.5,
      ),
      bodyMedium: bodyBase.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: secondaryTextColor,
        letterSpacing: 0.25,
      ),
      bodySmall: bodyBase.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: secondaryTextColor,
        letterSpacing: 0.4,
      ),
      labelLarge: bodyBase.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryTextColor,
        letterSpacing: 1.25,
      ),
      labelMedium: bodyBase.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
        letterSpacing: 1.0,
      ),
      labelSmall: bodyBase.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
        letterSpacing: 1.5,
      ),
    );
  }

  // Handy direct styles
  static TextStyle get currencyStyle => titleBase.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  static TextStyle get badgeStyle => bodyBase.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      );
}
