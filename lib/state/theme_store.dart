import 'package:flutter/material.dart';

import '../services/theme_service.dart';

class ThemeStore extends ChangeNotifier {
  final ThemeService _service = ThemeService();
  ThemeMode themeMode = ThemeMode.dark;

  Future<void> load() async {
    themeMode = await _service.loadThemeMode();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await _service.saveThemeMode(mode);
  }

  void toggle() => setThemeMode(themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}
