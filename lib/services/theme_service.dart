import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Выбор темы хранится только на устройстве — это оформление, а не то, что
/// нужно синхронизировать между устройствами или показывать на сервере.
class ThemeService {
  static const _key = 'theme_mode_v1';

  Future<ThemeMode> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      switch (raw) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        default:
          return ThemeMode.dark; // дефолт — тёмная, как и было исходно
      }
    } catch (_) {
      return ThemeMode.dark;
    }
  }

  Future<bool> saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode == ThemeMode.light ? 'light' : 'dark');
      return true;
    } catch (_) {
      return false;
    }
  }
}
