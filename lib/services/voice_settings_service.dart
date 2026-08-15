import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/voice_settings.dart';

/// Настройки голоса — чисто клиентские предпочтения (какой голос, скорость,
/// автоозвучка), не имеет смысла хранить на сервере или синхронизировать.
class VoiceSettingsService {
  static const _key = 'voice_settings_v1';

  Future<VoiceSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return const VoiceSettings();
      return VoiceSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const VoiceSettings();
    }
  }

  Future<bool> save(VoiceSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(settings.toJson()));
      return true;
    } catch (_) {
      return false;
    }
  }
}
