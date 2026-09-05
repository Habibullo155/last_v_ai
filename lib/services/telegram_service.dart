import 'dart:convert';

import 'package:http/http.dart' as http;

class TelegramException implements Exception {
  final String message;
  TelegramException(this.message);
  @override
  String toString() => message;
}

class TelegramLinkInfo {
  final String code;
  final String channelLink;
  final String botUsername;
  TelegramLinkInfo({required this.code, required this.channelLink, required this.botUsername});

  factory TelegramLinkInfo.fromJson(Map<String, dynamic> json) => TelegramLinkInfo(
        code: json['code'] as String,
        channelLink: json['channel_link'] as String? ?? '',
        botUsername: json['bot_username'] as String? ?? '',
      );
}

class TelegramService {
  final http.Client _client = http.Client();

  Future<TelegramLinkInfo> startLink({required String baseUrl, required String token}) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/api/telegram/link/start'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode >= 400) {
      throw TelegramException('Не удалось начать привязку (код ${res.statusCode}).');
    }
    return TelegramLinkInfo.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<bool> isLinked({required String baseUrl, required String token}) async {
    final res = await _client
        .get(Uri.parse('$baseUrl/api/telegram/status'), headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode >= 400) return false;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['is_linked'] as bool? ?? false;
  }

  /// Вызывается ТОЛЬКО после реального просмотра ролика (см. ad_service.dart
  /// про то, где именно проверяется, что человек действительно досмотрел).
  Future<int> confirmAdWatched({required String baseUrl, required String token}) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/api/telegram/ad-bonus'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode >= 400) {
      throw TelegramException('Не удалось начислить бонус (код ${res.statusCode}).');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['daily_ad_bonus_remaining'] as int? ?? 0;
  }

  void dispose() => _client.close();
}
