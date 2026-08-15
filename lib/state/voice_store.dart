import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/voice_settings.dart';
import '../services/app_settings_service.dart';
import '../services/voice_settings_service.dart';

class VoiceStore extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  final VoiceSettingsService _settingsService = VoiceSettingsService();
  final AppSettingsService _appSettingsService = AppSettingsService();

  VoiceSettings settings = const VoiceSettings();

  /// Распознавание речи в принципе доступно на этом устройстве (есть
  /// разрешение на микрофон, есть системный движок).
  bool isSttAvailable = false;

  /// Разрешено ли использовать голос вообще — управляется админом
  /// (см. backend/routers_settings.py). Не про доступность оборудования,
  /// а про то, включена ли фича глобально.
  bool isVoiceFeatureEnabled = true;

  bool isListening = false;
  bool isSpeaking = false;
  List<Map<String, String>> availableVoices = [];
  String? lastError;

  Future<void> init(String baseUrl) async {
    settings = await _settingsService.load();
    isVoiceFeatureEnabled = await _appSettingsService.isVoiceEnabled(baseUrl);

    if (isVoiceFeatureEnabled) {
      try {
        isSttAvailable = await _stt.initialize(
          onStatus: (status) {
            isListening = status == 'listening';
            notifyListeners();
          },
          onError: (error) {
            lastError = error.errorMsg;
            isListening = false;
            notifyListeners();
          },
        );
      } catch (_) {
        isSttAvailable = false;
      }

      try {
        final voices = await _tts.getVoices;
        if (voices is List) {
          availableVoices = voices
              .whereType<Map>()
              .map((v) => {
                    'name': v['name']?.toString() ?? '',
                    'locale': v['locale']?.toString() ?? '',
                  })
              .where((v) => v['name']!.isNotEmpty)
              .toList();
        }
      } catch (_) {
        availableVoices = [];
      }

      _tts.setCompletionHandler(() {
        isSpeaking = false;
        notifyListeners();
      });
      _tts.setCancelHandler(() {
        isSpeaking = false;
        notifyListeners();
      });
      _tts.setErrorHandler((_) {
        isSpeaking = false;
        notifyListeners();
      });

      await _applyTtsSettings();
    }

    notifyListeners();
  }

  Future<void> _applyTtsSettings() async {
    try {
      await _tts.setSpeechRate(settings.rate);
      await _tts.setPitch(settings.pitch);
      if (settings.voiceName != null && settings.voiceLocale != null) {
        await _tts.setVoice({'name': settings.voiceName!, 'locale': settings.voiceLocale!});
      }
    } catch (_) {
      // Выбранный голос мог перестать существовать (сменилось устройство,
      // обновилась ОС) — не критично, просто останется голос по умолчанию.
    }
  }

  Future<void> updateSettings(VoiceSettings newSettings) async {
    settings = newSettings;
    notifyListeners();
    await _settingsService.save(newSettings);
    await _applyTtsSettings();
  }

  Future<void> speak(String text) async {
    if (!isVoiceFeatureEnabled || text.trim().isEmpty) return;
    await stopSpeaking();
    isSpeaking = true;
    notifyListeners();
    try {
      await _tts.speak(text);
    } catch (_) {
      isSpeaking = false;
      notifyListeners();
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {
      // игнорируем — stop() на уже остановленном движке иногда бросает на некоторых платформах
    }
    isSpeaking = false;
    notifyListeners();
  }

  /// Слушает и вызывает [onResult] с распознанным текстом при каждом
  /// промежуточном/финальном результате — вызывающий код сам решает, что
  /// делать (обычно — подставить текст в поле ввода).
  Future<void> startListening({required ValueChanged<String> onResult}) async {
    if (!isVoiceFeatureEnabled || !isSttAvailable || isListening) return;
    lastError = null;
    try {
      await _stt.listen(
        onResult: (result) => onResult(result.recognizedWords),
        localeId: settings.sttLocaleId,
      );
      isListening = true;
      notifyListeners();
    } catch (e) {
      lastError = '$e';
      isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    try {
      await _stt.stop();
    } catch (_) {
      // игнорируем
    }
    isListening = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    _stt.stop();
    _appSettingsService.dispose();
    super.dispose();
  }
}
