import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keys for SharedPreferences
const String kThemeModeKey = 'settings_theme_mode';
const String kLanguageKey = 'settings_language';
const String kBiometricsKey = 'settings_biometrics';

// --- Theme Provider ---
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeStr = prefs.getString(kThemeModeKey);
      if (themeStr == 'light') {
        state = ThemeMode.light;
      } else if (themeStr == 'dark') {
        state = ThemeMode.dark;
      } else {
        state = ThemeMode.dark; // Default to dark premium
      }
    } catch (_) {
      state = ThemeMode.dark;
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kThemeModeKey, isDark ? 'dark' : 'light');
    } catch (_) {}
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// --- Language Provider ---
class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('fr') {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString(kLanguageKey);
      if (lang == 'en' || lang == 'fr') {
        state = lang!;
      } else {
        state = 'fr'; // Default to French
      }
    } catch (_) {
      state = 'fr';
    }
  }

  Future<void> setLanguage(String lang) async {
    if (lang == 'en' || lang == 'fr') {
      state = lang;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(kLanguageKey, lang);
      } catch (_) {}
    }
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

// --- Biometrics Provider ---
class BiometricsNotifier extends StateNotifier<bool> {
  BiometricsNotifier() : super(false) {
    _loadBiometrics();
  }

  Future<void> _loadBiometrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(kBiometricsKey) ?? false;
    } catch (_) {
      state = false;
    }
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kBiometricsKey, enabled);
    } catch (_) {}
  }
}

final biometricsProvider = StateNotifierProvider<BiometricsNotifier, bool>((ref) {
  return BiometricsNotifier();
});
