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
  final String defaultVoice;
  final int? voicePitch; // null = не задано, сервер синтеза сам решает
  final int? voiceRate;
  final int voiceSampleRate; // 8000 | 24000 | 48000
  const PublicAppSettings({
    required this.voiceEnabled,
    required this.cloudTtsEnabled,
    required this.ttsProvider,
    this.defaultVoice = 'baya',
    this.voicePitch,
    this.voiceRate,
    this.voiceSampleRate = 48000,
  });

  static PublicAppSettings fromJson(Map<String, dynamic> data) => PublicAppSettings(
        voiceEnabled: data['voice_enabled'] as bool? ?? true,
        cloudTtsEnabled: data['cloud_tts_enabled'] as bool? ?? false,
        ttsProvider: data['tts_provider'] as String?,
        defaultVoice: data['default_voice'] as String? ?? 'baya',
        voicePitch: data['voice_pitch'] as int?,
        voiceRate: data['voice_rate'] as int?,
        voiceSampleRate: data['voice_sample_rate'] as int? ?? 48000,
      );
}

class PersonaSettings {
  final String assistantName;
  final String assistantCustomPrompt;
  const PersonaSettings({this.assistantName = '', this.assistantCustomPrompt = ''});

  static PersonaSettings fromJson(Map<String, dynamic> data) => PersonaSettings(
        assistantName: data['assistant_name'] as String? ?? '',
        assistantCustomPrompt: data['assistant_custom_prompt'] as String? ?? '',
      );
}

enum ResponseLength { concise, balanced, detailed }

class ModelSettings {
  final double temperature;
  final double topP;
  final ResponseLength responseLength;
  const ModelSettings({this.temperature = 1.0, this.topP = 0.95, this.responseLength = ResponseLength.balanced});

  String get responseLengthKey => responseLength.name;

  static ModelSettings fromJson(Map<String, dynamic> data) => ModelSettings(
        temperature: (data['temperature'] as num?)?.toDouble() ?? 1.0,
        topP: (data['top_p'] as num?)?.toDouble() ?? 0.95,
        responseLength: ResponseLength.values.firstWhere(
          (v) => v.name == (data['response_length'] as String? ?? 'balanced'),
          orElse: () => ResponseLength.balanced,
        ),
      );
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
      return PublicAppSettings.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return const PublicAppSettings(voiceEnabled: true, cloudTtsEnabled: false, ttsProvider: null);
    }
  }

  /// Только для админа — оба поля необязательны, можно поменять только
  /// одно (та же exclude_unset-логика, что и на бэкенде).
  Future<PublicAppSettings> updateSettings({
    required String baseUrl,
    required String token,
    bool? voiceEnabled,
    String? defaultVoice,
    int? voicePitch,
    int? voiceRate,
    bool clearVoicePitch = false,
    bool clearVoiceRate = false,
    int? voiceSampleRate,
  }) async {
    final body = <String, dynamic>{};
    if (voiceEnabled != null) body['voice_enabled'] = voiceEnabled;
    if (defaultVoice != null) body['default_voice'] = defaultVoice;
    if (clearVoicePitch) {
      body['clear_voice_pitch'] = true;
    } else if (voicePitch != null) {
      body['voice_pitch'] = voicePitch;
    }
    if (clearVoiceRate) {
      body['clear_voice_rate'] = true;
    } else if (voiceRate != null) {
      body['voice_rate'] = voiceRate;
    }
    if (voiceSampleRate != null) body['voice_sample_rate'] = voiceSampleRate;

    final res = await _client
        .patch(
          Uri.parse('$baseUrl/api/settings/admin'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) {
      throw AppSettingsException('Не удалось изменить настройку (код ${res.statusCode}).');
    }
    return PublicAppSettings.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Возвращает голосовые настройки к заводским значениям. НЕ трогает
  /// словарь произношения (routers_pronunciation.py) — это отдельный
  /// накопленный контент, не переключатель.
  Future<PublicAppSettings> resetToDefaults({
    required String baseUrl,
    required String token,
  }) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/api/settings/admin/reset'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) {
      throw AppSettingsException('Не удалось восстановить настройки (код ${res.statusCode}).');
    }
    return PublicAppSettings.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // --- Личность ИИ (имя + системный промпт) — admin-only, отдельно от
  // публичных настроек, системный промпт не должен быть виден анонимно.

  Future<PersonaSettings> getPersonaSettings({required String baseUrl, required String token}) async {
    final res = await _client
        .get(Uri.parse('$baseUrl/api/settings/admin/persona'), headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) {
      throw AppSettingsException('Не удалось загрузить настройки личности ИИ (код ${res.statusCode}).');
    }
    return PersonaSettings.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<PersonaSettings> updatePersonaSettings({
    required String baseUrl,
    required String token,
    String? assistantName,
    String? assistantCustomPrompt,
  }) async {
    final body = <String, dynamic>{};
    if (assistantName != null) body['assistant_name'] = assistantName;
    if (assistantCustomPrompt != null) body['assistant_custom_prompt'] = assistantCustomPrompt;

    final res = await _client
        .patch(
          Uri.parse('$baseUrl/api/settings/admin/persona'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) {
      throw AppSettingsException('Не удалось сохранить личность ИИ (код ${res.statusCode}).');
    }
    return PersonaSettings.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<PersonaSettings> resetPersonaSettings({required String baseUrl, required String token}) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/api/settings/admin/persona/reset'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) {
      throw AppSettingsException('Не удалось сбросить личность ИИ (код ${res.statusCode}).');
    }
    return PersonaSettings.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // --- Скорость/тон ответа (temperature, top_p, длина) — тот же
  // admin-only паттерн, отдельный сброс от голоса и личности ИИ.

  Future<ModelSettings> getModelSettings({required String baseUrl, required String token}) async {
    final res = await _client
        .get(Uri.parse('$baseUrl/api/settings/admin/model'), headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) {
      throw AppSettingsException('Не удалось загрузить настройки модели (код ${res.statusCode}).');
    }
    return ModelSettings.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<ModelSettings> updateModelSettings({
    required String baseUrl,
    required String token,
    double? temperature,
    double? topP,
    ResponseLength? responseLength,
  }) async {
    final body = <String, dynamic>{};
    if (temperature != null) body['temperature'] = temperature;
    if (topP != null) body['top_p'] = topP;
    if (responseLength != null) body['response_length'] = responseLength.name;

    final res = await _client
        .patch(
          Uri.parse('$baseUrl/api/settings/admin/model'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) {
      throw AppSettingsException('Не удалось сохранить настройки модели (код ${res.statusCode}).');
    }
    return ModelSettings.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<ModelSettings> resetModelSettings({required String baseUrl, required String token}) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/api/settings/admin/model/reset'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) {
      throw AppSettingsException('Не удалось сбросить настройки модели (код ${res.statusCode}).');
    }
    return ModelSettings.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  void dispose() => _client.close();
}
