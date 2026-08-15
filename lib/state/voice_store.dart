import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/voice_settings.dart';
import '../services/app_settings_service.dart';
import '../services/pronunciation_service.dart';
import '../services/voice_settings_service.dart';

class VoiceStore extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  final VoiceSettingsService _settingsService = VoiceSettingsService();
  final AppSettingsService _appSettingsService = AppSettingsService();
  final PronunciationService _pronunciationService = PronunciationService();

  /// Словарь произношения, который задал админ — общий для всех
  /// пользователей (в отличие от settings.pronunciationOverrides, который
  /// хранится только на этом устройстве). Личный словарь при совпадении
  /// слова имеет приоритет — пользователь может переопределить у себя то,
  /// что задал админ глобально.
  Map<String, String> globalPronunciation = {};

  VoiceSettings settings = const VoiceSettings();

  /// Распознавание речи в принципе доступно на этом устройстве (есть
  /// разрешение на микрофон, есть системный движок).
  bool isSttAvailable = false;

  /// Разрешено ли использовать голос вообще — управляется админом
  /// (см. backend/routers_settings.py). Не про доступность оборудования,
  /// а про то, включена ли фича глобально.
  bool isVoiceFeatureEnabled = true;

  /// Итоговая доступность голоса — и админ должен разрешить фичу
  /// глобально, И сам пользователь не должен её выключить у себя (личное
  /// предпочтение, отдельное от общего переключателя админа).
  bool get isVoiceAvailable => isVoiceFeatureEnabled && settings.voiceUiEnabled;

  bool isListening = false;
  bool isSpeaking = false;
  List<Map<String, String>> availableVoices = [];
  String? lastError;

  Future<void> init(String baseUrl) async {
    settings = await _settingsService.load();
    isVoiceFeatureEnabled = await _appSettingsService.isVoiceEnabled(baseUrl);
    globalPronunciation = await _pronunciationService.getPublicDictionary(baseUrl);

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

      // Если пользователь ещё ни разу не выбирал язык распознавания сам —
      // по умолчанию предпочитаем русский, если он вообще доступен на
      // устройстве, а не оставляем "как решит система" (которая может
      // выбрать английский, даже если приложение целиком на русском).
      if (settings.sttLocaleId == null && isSttAvailable) {
        try {
          final locales = await _stt.locales();
          String? russianLocaleId;
          for (final l in locales) {
            if (l.localeId.toLowerCase().startsWith('ru')) {
              russianLocaleId = l.localeId;
              break;
            }
          }
          if (russianLocaleId != null) {
            settings = settings.copyWith(sttLocaleId: russianLocaleId);
            await _settingsService.save(settings);
          }
        } catch (_) {
          // Не критично — останется системный дефолт.
        }
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

  /// Проговаривает тестовую фразу выбранным голосом, НЕ сохраняя его как
  /// текущий — так можно послушать разные варианты перед тем, как решить.
  /// После проверки возвращает движок к реально выбранному голосу.
  Future<void> previewVoice(String name, String locale) async {
    if (!isVoiceAvailable) return;
    await stopSpeaking();
    try {
      await _tts.setVoice({'name': name, 'locale': locale});
      isSpeaking = true;
      notifyListeners();
      await _tts.speak('Привет! Так звучит этот голос.');
    } catch (_) {
      isSpeaking = false;
      notifyListeners();
    } finally {
      // Возвращаем движок на реально выбранный (сохранённый) голос —
      // иначе следующая обычная озвучка ответа неожиданно звучала бы тем,
      // что здесь только прослушивали "для примерки".
      await _applyTtsSettings();
    }
  }

  /// Личный словарь переопределяет глобальный при совпадении слова —
  /// сначала применяем глобальные замены (админские), затем личные поверх.
  String _applyPronunciation(String text) {
    var result = text;
    for (final entry in globalPronunciation.entries) {
      if (entry.key.isEmpty) continue;
      result = result.replaceAll(
        RegExp(RegExp.escape(entry.key), caseSensitive: false),
        entry.value,
      );
    }
    return settings.applyPronunciation(result);
  }

  Future<void> speak(String text) async {
    if (!isVoiceAvailable || text.trim().isEmpty) return;
    await stopSpeaking();
    isSpeaking = true;
    notifyListeners();
    try {
      await _tts.speak(_applyPronunciation(text));
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
    if (!isVoiceAvailable || !isSttAvailable || isListening) return;
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
    _pronunciationService.dispose();
    super.dispose();
  }
}
