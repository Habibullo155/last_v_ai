import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:ai_last_v/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:google_mobile_ads/google_mobile_ads.dart';
/// Показ рекламы за вознаграждение (rewarded ad) - только Android/iOS,
/// у AdMob (google_mobile_ads) нет поддержки веба и десктопа вообще. На
/// вебе/десктопе кнопка "посмотреть рекламу" в интерфейсе просто не
/// показывается (см. purchase_screen.dart) - единственный способ
/// получить дополнительные запросы там - подписка на Telegram-канал.
///
/// App ID AdMob прописывается в native-файлах на этапе сборки, не может
/// быть настроен из админки (это не то же самое, что ad unit id ниже):
///   Android: android/app/src/main/AndroidManifest.xml, внутри <application>:
///     <meta-data
///         android:name="com.google.android.gms.ads.APPLICATION_ID"
///         android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
///   iOS: ios/Runner/Info.plist:
///     <key>GADApplicationIdentifier</key>
///     <string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
/// Без этого приложение крашнется при старте на реальном устройстве -
/// это не опционально, AdMob сам требует App ID в манифесте.
class AdService {
  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  Future<void> initialize() async {
    if (!isSupportedPlatform) return;
    await MobileAds.instance.initialize();
  }

  Future<({bool enabled, String adUnitId})> _fetchConfig(String baseUrl) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/settings/admob')).timeout(const Duration(seconds: 10));
      if (res.statusCode >= 400) return (enabled: false, adUnitId: '');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (
        enabled: data['admob_enabled'] as bool? ?? false,
        adUnitId: data['admob_rewarded_ad_unit_id'] as String? ?? '',
      );
    } catch (_) {
      return (enabled: false, adUnitId: '');
    }
  }

  /// Загружает ролик заранее (до нажатия кнопки) - показывать сразу по
  /// нажатию без предзагрузки означало бы заметную паузу/спиннер каждый
  /// раз, предзагрузка даёт мгновенный показ.
  Future<bool> preload(String baseUrl) async {
    if (!isSupportedPlatform || _isLoading || _rewardedAd != null) return _rewardedAd != null;
    final config = await _fetchConfig(baseUrl);
    if (!config.enabled || config.adUnitId.isEmpty) return false;

    _isLoading = true;
    final completer = Completer<bool>();
    await RewardedAd.load(
      adUnitId: config.adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          completer.complete(false);
        },
      ),
    );
    return completer.future;
  }

  /// Возвращает true только если человек ДЕЙСТВИТЕЛЬНО досмотрел ролик
  /// до конца (реальный колбэк onUserEarnedReward от самого SDK) - вызов
  /// бэкенда за бонусом (routers_telegram.py::confirm_ad_watched)
  /// делается только после этого, не раньше.
  Future<bool> showAndWaitForReward() async {
    final ad = _rewardedAd;
    if (ad == null) return false;
    _rewardedAd = null; // ролик одноразовый, следующий нужно грузить заново

    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    await ad.show(
      onUserEarnedReward: (ad, reward) => earned = true,
    );
    return completer.future;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
