import 'package:flutter_test/flutter_test.dart';
import 'package:ai_last_v/models/voice_settings.dart';

void main() {
  group('VoiceSettings defaults', () {
    test('default constructor uses safe defaults (voice on, auto-read off)', () {
      const settings = VoiceSettings();
      expect(settings.autoReadEnabled, isFalse);
      expect(settings.voiceUiEnabled, isTrue);
      expect(settings.rate, 0.5);
      expect(settings.pitch, 1.0);
      expect(settings.voiceName, isNull);
      expect(settings.cloudVoiceName, 'baya');
    });
  });

  group('VoiceSettings.copyWith', () {
    test('changes only the specified field, keeps the rest', () {
      const original = VoiceSettings(autoReadEnabled: false, rate: 0.5);
      final updated = original.copyWith(autoReadEnabled: true);
      expect(updated.autoReadEnabled, isTrue);
      expect(updated.rate, 0.5); // не тронуто
    });

    test('clearVoice removes the selected voice name/locale', () {
      const original = VoiceSettings(voiceName: 'Milena', voiceLocale: 'ru-RU');
      final cleared = original.copyWith(clearVoice: true);
      expect(cleared.voiceName, isNull);
      expect(cleared.voiceLocale, isNull);
    });

    test('setting a new voice overrides the previous one', () {
      const original = VoiceSettings(voiceName: 'OldVoice', voiceLocale: 'en-US');
      final updated = original.copyWith(voiceName: 'NewVoice', voiceLocale: 'ru-RU');
      expect(updated.voiceName, 'NewVoice');
      expect(updated.voiceLocale, 'ru-RU');
    });
  });

  group('VoiceSettings JSON round-trip', () {
    test('toJson/fromJson preserves all fields', () {
      const original = VoiceSettings(
        autoReadEnabled: true,
        voiceUiEnabled: false,
        rate: 0.7,
        pitch: 1.3,
        voiceName: 'Milena',
        voiceLocale: 'ru-RU',
        sttLocaleId: 'ru_RU',
        cloudVoiceName: 'aidar',
      );
      final restored = VoiceSettings.fromJson(original.toJson());

      expect(restored.autoReadEnabled, original.autoReadEnabled);
      expect(restored.voiceUiEnabled, original.voiceUiEnabled);
      expect(restored.rate, original.rate);
      expect(restored.pitch, original.pitch);
      expect(restored.voiceName, original.voiceName);
      expect(restored.voiceLocale, original.voiceLocale);
      expect(restored.sttLocaleId, original.sttLocaleId);
      expect(restored.cloudVoiceName, original.cloudVoiceName);
    });

    test('fromJson applies safe defaults for a missing/empty map', () {
      final settings = VoiceSettings.fromJson({});
      expect(settings.autoReadEnabled, isFalse);
      expect(settings.voiceUiEnabled, isTrue);
      expect(settings.rate, 0.5);
    });
  });
}
