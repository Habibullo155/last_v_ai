import 'dart:convert';

import 'package:http/http.dart' as http;

class AppSettingsException implements Exception {
  final String message;
  AppSettingsException(this.message);
  @override
  String toString() => message;
}

class PublicAppSettings {
  final bool voiceEnabled;
  final bool cloudTtsEnabled;
  final String? ttsProvider; // "silero" | null
  const PublicAppSettings({
    required this.voiceEnabled,
    required this.cloudTtsEnabled,
    required this.ttsProvider,
  });
}

class AppSettingsService {
  final http.Client _client = http.Client();

  /// Если сервер недоступен — не блокируем голосовые функции ими: базовый
  /// голос на устройстве работает независимо от бэкенда, а облачную
  /// озвучку в этом случае просто считаем недоступной (она физически не
  /// может работать без сервера — это не то же самое, что "выключена").
  Future<PublicAppSettings> getPublicSettings(String baseUrl) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/api/settings/public'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        return const PublicAppSettings(voiceEnabled: true, cloudTtsEnabled: false, ttsProvider: null);
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return PublicAppSettings(
        voiceEnabled: data['voice_enabled'] as bool? ?? true,
        cloudTtsEnabled: data['cloud_tts_enabled'] as bool? ?? false,
        ttsProvider: data['tts_provider'] as String?,
      );
    } catch (_) {
      return const PublicAppSettings(voiceEnabled: true, cloudTtsEnabled: false, ttsProvider: null);
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
