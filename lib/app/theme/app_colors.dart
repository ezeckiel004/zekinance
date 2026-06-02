import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF00C853);      // Emerald Green (Growth, Money)
  static const Color primaryLight = Color(0xFF69F0AE); // Light Mint Green
  static const Color primaryDark = Color(0xFF003300);  // Deep Forest Green
  
  static const Color secondary = Color(0xFFFFB300);    // Warm Gold (Savings, Wealth)
  static const Color secondaryLight = Color(0xFFFFE082);
  
  static const Color accent = Color(0xFF00E5FF);       // Neon Cyan (Tech, AI)
  
  // Status Colors
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFD50000);
  static const Color info = Color(0xFF2979FF);

  // Dark Mode Palette (Primary theme)
  static const Color darkBg = Color(0xFF090D16);       // Deep space navy background
  static const Color darkSurface = Color(0xFF131A2D);  // Premium dark card/surface
  static const Color darkSurfaceLight = Color(0xFF1E294B); // Lighter navy surface
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50 (Very light)
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400 (Muted)
  static const Color darkBorder = Color(0xFF1E293B);    // Subtle slate border

  // Light Mode Palette
  static const Color lightBg = Color(0xFFF8FAFC);      // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white card
  static const Color lightSurfaceDark = Color(0xFFF1F5F9); // Slate 100
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate 500
  static const Color lightBorder = Color(0xFFE2E8F0);   // Slate 200

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [secondary, Color(0xFFFFE082)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [darkSurface, Color(0xFF1A233D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

extension ThemeContextExt on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get surfaceColor => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get surfaceColorLight => isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceDark;
  Color get borderColor => isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get textPrimary => isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary => isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;
}
