import 'dart:convert';

import 'package:http/http.dart' as http;

class AppSettingsException implements Exception {
  final String message;
  AppSettingsException(this.message);
  @override
  String toString() => message;
}

class AppSettingsService {
  final http.Client _client = http.Client();

  /// Если сервер недоступен — не блокируем голосовые функции ими: они
  /// работают полностью на устройстве (STT/TTS не проходят через бэкенд),
  /// сам факт недоступности сервера не повод их прятать.
  Future<bool> isVoiceEnabled(String baseUrl) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/api/settings/public'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return true;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['voice_enabled'] as bool? ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Только для админа — глобально включает/выключает голосовые функции
  /// для всех пользователей приложения.
  Future<bool> setVoiceEnabled({
    required String baseUrl,
    required String token,
    required bool enabled,
  }) async {
    final res = await _client
        .patch(
          Uri.parse('$baseUrl/api/settings/admin'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode({'voice_enabled': enabled}),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) {
      throw AppSettingsException('Не удалось изменить настройку (код ${res.statusCode}).');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['voice_enabled'] as bool? ?? enabled;
  }

  void dispose() => _client.close();
}
