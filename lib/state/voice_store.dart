import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/cloud_voice.dart';
import '../models/voice_settings.dart';
import '../services/app_settings_service.dart';
import '../services/cloud_tts_service.dart';
import '../services/pronunciation_service.dart';
import '../services/voice_settings_service.dart';

class VoiceStore extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final VoiceSettingsService _settingsService = VoiceSettingsService();
  final AppSettingsService _appSettingsService = AppSettingsService();
  final PronunciationService _pronunciationService = PronunciationService();
  final CloudTtsService _cloudTtsService = CloudTtsService();

  String _baseUrl = '';
  String? _authToken;

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

  /// Настроена ли облачная озвучка (Google Cloud TTS или Yandex SpeechKit)
  /// на сервере — если да, используем её вместо движка на устройстве:
  /// звучит естественнее. Честное отражение реальной настройки .env, не
  /// переключатель "для вида".
  bool isCloudTtsAvailable = false;

  /// "google" | "yandex" | null — какой именно провайдер активен, нужен,
  /// чтобы показать правильный список из 4 голосов (models/cloud_voice.dart).
  String? ttsProvider;

  /// Итоговая доступность голоса — и админ должен разрешить фичу
  /// глобально, И сам пользователь не должен её выключить у себя (личное
  /// предпочтение, отдельное от общего переключателя админа).
  bool get isVoiceAvailable => isVoiceFeatureEnabled && settings.voiceUiEnabled;

  bool isListening = false;
  bool isSpeaking = false;
  List<Map<String, String>> availableVoices = [];
  String? lastError;

  Future<void> init(String baseUrl, {String? authToken}) async {
    _baseUrl = baseUrl;
    _authToken = authToken;

    settings = await _settingsService.load();
    final publicSettings = await _appSettingsService.getPublicSettings(baseUrl);
    isVoiceFeatureEnabled = publicSettings.voiceEnabled;
    isCloudTtsAvailable = publicSettings.cloudTtsEnabled;
    ttsProvider = publicSettings.ttsProvider;
    globalPronunciation = await _pronunciationService.getPublicDictionary(baseUrl);

    // Если сохранённый голос принадлежит ДРУГОМУ провайдеру (например,
    // сервер переключили с Google на Yandex), сбрасываем на первый голос
    // актуального списка — иначе застрянем на имени голоса, которого для
    // этого провайдера не существует.
    if (isCloudTtsAvailable) {
      final activeVoices = cloudVoicesFor(ttsProvider);
      final currentIsValid = activeVoices.any((v) => v.name == settings.cloudVoiceName);
      if (!currentIsValid && activeVoices.isNotEmpty) {
        settings = settings.copyWith(cloudVoiceName: activeVoices.first.name);
        await _settingsService.save(settings);
      }
    }

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

      // Список голосов на устройстве нужен только как запасной вариант —
      // если облачная озвучка настроена на сервере, используются 4
      // фиксированных облачных голоса (models/cloud_voice.dart) вместо этого.
      if (!isCloudTtsAvailable) {
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
      _audioPlayer.onPlayerComplete.listen((_) {
        isSpeaking = false;
        notifyListeners();
      });

      if (!isCloudTtsAvailable) {
        await _applyOnDeviceTtsSettings();
      }
    }

    notifyListeners();
  }

  Future<void> _applyOnDeviceTtsSettings() async {
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
    if (!isCloudTtsAvailable) {
      await _applyOnDeviceTtsSettings();
    }
  }

  /// Проговаривает тестовую фразу выбранным голосом на устройстве, НЕ
  /// сохраняя его как текущий — так можно послушать варианты перед тем,
  /// как решить. Для облачных голосов используй previewCloudVoice.
  Future<void> previewVoice(String name, String locale) async {
    if (!isVoiceAvailable || isCloudTtsAvailable) return;
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
      await _applyOnDeviceTtsSettings();
    }
  }

  /// Прослушать конкретный облачный голос без сохранения выбора.
  Future<void> previewCloudVoice(String voiceName) async {
    if (!isVoiceAvailable || !isCloudTtsAvailable) return;
    await _speakCloud('Привет! Так звучит этот голос.', voiceOverride: voiceName);
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
    if (isCloudTtsAvailable) {
      await _speakCloud(text);
    } else {
      await _speakOnDevice(text);
    }
  }

  Future<void> _speakOnDevice(String text) async {
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

  Future<void> _speakCloud(String text, {String? voiceOverride}) async {
    final token = _authToken;
    if (token == null) return;
    await stopSpeaking();
    isSpeaking = true;
    lastError = null;
    notifyListeners();
    try {
      final bytes = await _cloudTtsService.synthesize(
        baseUrl: _baseUrl,
        token: token,
        text: _applyPronunciation(text),
        voiceName: voiceOverride ?? settings.cloudVoiceName,
      );
      await _audioPlayer.play(BytesSource(bytes));
      // isSpeaking сбросится в onPlayerComplete-подписке из init().
    } on CloudTtsException catch (e) {
      lastError = e.message;
      isSpeaking = false;
      notifyListeners();
    } catch (e) {
      lastError = '$e';
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
    try {
      await _audioPlayer.stop();
    } catch (_) {
      // аналогично — не критично
    }
    isSpeaking = false;
    notifyListeners();
  }

  /// Обновляет токен авторизации — нужен для запросов к облачной озвучке.
  /// Вызывается, если токен обновился уже после init() (например, после
  /// повторного входа).
  void updateAuthToken(String? token) {
    _authToken = token;
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
    _audioPlayer.dispose();
    _appSettingsService.dispose();
    _pronunciationService.dispose();
    _cloudTtsService.dispose();
    super.dispose();
  }
}
