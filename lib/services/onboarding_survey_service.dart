import 'dart:convert';

import 'package:http/http.dart' as http;

class OnboardingSurveyException implements Exception {
  final String message;
  OnboardingSurveyException(this.message);
  @override
  String toString() => message;
}

class OnboardingSurveyService {
  final http.Client _client = http.Client();

  Future<String> getStatus({required String baseUrl, required String token}) async {
    final res = await _client
        .get(Uri.parse('$baseUrl/api/onboarding-survey/status'), headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode >= 400) {
      throw OnboardingSurveyException('Не удалось загрузить статус опросника (код ${res.statusCode}).');
    }
    return (jsonDecode(res.body) as Map<String, dynamic>)['status'] as String;
  }

  Future<void> complete({required String baseUrl, required String token, required Map<String, String> answers}) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/api/onboarding-survey/complete'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode({'answers': answers}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode >= 400) {
      throw OnboardingSurveyException('Не удалось сохранить ответы (код ${res.statusCode}).');
    }
  }

  Future<void> skip({required String baseUrl, required String token}) async {
    final res = await _client
        .post(Uri.parse('$baseUrl/api/onboarding-survey/skip'), headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode >= 400) {
      throw OnboardingSurveyException('Не удалось пропустить опросник (код ${res.statusCode}).');
    }
  }

  void dispose() => _client.close();
}
