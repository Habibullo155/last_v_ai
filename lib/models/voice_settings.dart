class VoiceSettings {
  final bool autoReadEnabled;
  final double rate; // 0.0–1.0, нормализованная шкала flutter_tts
  final double pitch; // 0.5–2.0
  final String? voiceName;
  final String? voiceLocale;
  final String? sttLocaleId;

  const VoiceSettings({
    this.autoReadEnabled = false,
    this.rate = 0.5,
    this.pitch = 1.0,
    this.voiceName,
    this.voiceLocale,
    this.sttLocaleId,
  });

  VoiceSettings copyWith({
    bool? autoReadEnabled,
    double? rate,
    double? pitch,
    String? voiceName,
    String? voiceLocale,
    String? sttLocaleId,
    bool clearVoice = false,
  }) {
    return VoiceSettings(
      autoReadEnabled: autoReadEnabled ?? this.autoReadEnabled,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      voiceName: clearVoice ? null : (voiceName ?? this.voiceName),
      voiceLocale: clearVoice ? null : (voiceLocale ?? this.voiceLocale),
      sttLocaleId: sttLocaleId ?? this.sttLocaleId,
    );
  }

  Map<String, dynamic> toJson() => {
        'autoReadEnabled': autoReadEnabled,
        'rate': rate,
        'pitch': pitch,
        'voiceName': voiceName,
        'voiceLocale': voiceLocale,
        'sttLocaleId': sttLocaleId,
      };

  factory VoiceSettings.fromJson(Map<String, dynamic> json) {
    return VoiceSettings(
      autoReadEnabled: json['autoReadEnabled'] as bool? ?? false,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.5,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      voiceName: json['voiceName'] as String?,
      voiceLocale: json['voiceLocale'] as String?,
      sttLocaleId: json['sttLocaleId'] as String?,
    );
  }
}
