import 'package:flutter/foundation.dart';

import '../services/theme_service.dart';
import '../theme/background_variant.dart';

export '../theme/background_variant.dart';

/// Синглтон намеренно — AppBackground используется примерно в 20 экранах,
/// пробрасывать ThemeStore через конструктор каждого из них ради выбора
/// цвета фона было бы избыточно. AppBackground читает
/// ThemeStore.instance напрямую.
class ThemeStore extends ChangeNotifier {
  ThemeStore._internal();
  static final ThemeStore instance = ThemeStore._internal();

  final ThemeService _service = ThemeService();
  BackgroundVariant variant = BackgroundVariant.violet;

  Future<void> load() async {
    variant = await _service.loadVariant();
    notifyListeners();
  }

  Future<void> setVariant(BackgroundVariant newVariant) async {
    variant = newVariant;
    notifyListeners();
    await _service.saveVariant(newVariant);
  }
}
