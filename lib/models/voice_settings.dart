class VoiceSettings {
  final bool autoReadEnabled;
  final bool voiceUiEnabled; // личный выбор пользователя — скрыть голосовые кнопки
  final double rate; // 0.0–1.0, нормализованная шкала flutter_tts (только голос на устройстве)
  final double pitch; // 0.5–2.0 (только голос на устройстве)
  final String? voiceName; // голос на устройстве (flutter_tts), если облако недоступно
  final String? voiceLocale;
  final String? sttLocaleId;

  /// Выбор из 4 фиксированных облачных голосов (Silero TTS) — см.
  /// models/cloud_voice.dart. Используется только когда облачная озвучка
  /// вообще доступна (сервер настроен) — иначе играет голос на устройстве.
  final String cloudVoiceName;

  /// Словарь произношения: слово (как его пишет пользователь) → как это
  /// нужно "прочитать" движку синтеза речи. Применяется к тексту перед
  /// озвучкой — если движок неправильно произносит конкретное слово
  /// (например, имя, аббревиатуру, редкий термин), можно задать замену.
  final Map<String, String> pronunciationOverrides;

  const VoiceSettings({
    this.autoReadEnabled = false,
    this.voiceUiEnabled = true,
    this.rate = 0.5,
    this.pitch = 1.0,
    this.voiceName,
    this.voiceLocale,
    this.sttLocaleId,
    this.cloudVoiceName = 'ru-RU-Chirp3-HD-Aoede',
    this.pronunciationOverrides = const {},
  });

  VoiceSettings copyWith({
    bool? autoReadEnabled,
    bool? voiceUiEnabled,
    double? rate,
    double? pitch,
    String? voiceName,
    String? voiceLocale,
    String? sttLocaleId,
    String? cloudVoiceName,
    Map<String, String>? pronunciationOverrides,
    bool clearVoice = false,
  }) {
    return VoiceSettings(
      autoReadEnabled: autoReadEnabled ?? this.autoReadEnabled,
      voiceUiEnabled: voiceUiEnabled ?? this.voiceUiEnabled,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      voiceName: clearVoice ? null : (voiceName ?? this.voiceName),
      voiceLocale: clearVoice ? null : (voiceLocale ?? this.voiceLocale),
      sttLocaleId: sttLocaleId ?? this.sttLocaleId,
      cloudVoiceName: cloudVoiceName ?? this.cloudVoiceName,
      pronunciationOverrides: pronunciationOverrides ?? this.pronunciationOverrides,
    );
  }

  /// Применяет словарь произношения к тексту перед озвучкой — простая
  /// замена подстрок, регистронезависимая по ключу.
  String applyPronunciation(String text) {
    if (pronunciationOverrides.isEmpty) return text;
    var result = text;
    for (final entry in pronunciationOverrides.entries) {
      if (entry.key.isEmpty) continue;
      result = result.replaceAll(
        RegExp(RegExp.escape(entry.key), caseSensitive: false),
        entry.value,
      );
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
        'autoReadEnabled': autoReadEnabled,
        'voiceUiEnabled': voiceUiEnabled,
        'rate': rate,
        'pitch': pitch,
        'voiceName': voiceName,
        'voiceLocale': voiceLocale,
        'sttLocaleId': sttLocaleId,
        'cloudVoiceName': cloudVoiceName,
        'pronunciationOverrides': pronunciationOverrides,
      };

  factory VoiceSettings.fromJson(Map<String, dynamic> json) {
    final rawOverrides = json['pronunciationOverrides'];
    return VoiceSettings(
      autoReadEnabled: json['autoReadEnabled'] as bool? ?? false,
      voiceUiEnabled: json['voiceUiEnabled'] as bool? ?? true,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.5,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      voiceName: json['voiceName'] as String?,
      voiceLocale: json['voiceLocale'] as String?,
      sttLocaleId: json['sttLocaleId'] as String?,
      cloudVoiceName: json['cloudVoiceName'] as String? ?? 'ru-RU-Chirp3-HD-Aoede',
      pronunciationOverrides: rawOverrides is Map
          ? rawOverrides.map((k, v) => MapEntry(k.toString(), v.toString()))
          : const {},
    );
  }
}
