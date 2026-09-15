import 'package:shared_preferences/shared_preferences.dart';

/// Показывается ли интро-видео при запуске - только ОДИН РАЗ на
/// устройстве, не привязано к аккаунту (в отличие от опросника, который
/// per-аккаунт на сервере) - имеет смысл показать один раз "это
/// устройство", даже если человек потом выйдет и зайдёт под другим
/// аккаунтом.
class IntroVideoService {
  static const _seenKey = 'intro_video_seen_v1';

  Future<bool> hasSeenIntro() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_seenKey) ?? false;
    } catch (_) {
      // не смогли прочитать - безопаснее НЕ показывать видео повторно
      // человеку, который, возможно, уже видел его много раз
      return true;
    }
  }

  Future<void> markIntroSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seenKey, true);
    } catch (_) {
      // не критично - в худшем случае видео покажется ещё раз при
      // следующем запуске
    }
  }
}
