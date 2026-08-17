import 'package:shared_preferences/shared_preferences.dart';

import '../theme/background_variant.dart';

/// Выбор варианта фона хранится только на устройстве — это оформление,
/// не то, что нужно синхронизировать между устройствами или показывать
/// на сервере.
class ThemeService {
  static const _key = 'background_variant_v1';

  Future<BackgroundVariant> loadVariant() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      return BackgroundVariant.values.firstWhere(
        (v) => v.name == raw,
        orElse: () => BackgroundVariant.violet,
      );
    } catch (_) {
      return BackgroundVariant.violet;
    }
  }

  Future<bool> saveVariant(BackgroundVariant variant) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, variant.name);
      return true;
    } catch (_) {
      return false;
    }
  }
}
