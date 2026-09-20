import 'dart:convert';

import 'package:http/http.dart' as http;

import 'pinned_http_client.dart';

class OnboardingSurveyException implements Exception {
  final String message;
  OnboardingSurveyException(this.message);
  @override
  String toString() => message;
}

/// Анонимная агрегированная статистика по одному вопросу - "сколько
/// людей выбрали тот же вариант, что и ты". Никогда не диагноз, только
/// сравнение с общим числом ответивших.
class OnboardingSurveyStat {
  final String question;
  final String myAnswer;
  final double matchingPercentage;
  final int respondentsForQuestion;

  OnboardingSurveyStat({
    required this.question,
    required this.myAnswer,
    required this.matchingPercentage,
    required this.respondentsForQuestion,
  });

  factory OnboardingSurveyStat.fromJson(Map<String, dynamic> json) => OnboardingSurveyStat(
    question: json['question'] as String,
    myAnswer: json['my_answer'] as String,
    matchingPercentage: (json['matching_percentage'] as num).toDouble(),
    respondentsForQuestion: json['respondents_for_question'] as int,
  );
}

class OnboardingSurveyService {
  final http.Client _client = createHttpClient();

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

  Future<List<OnboardingSurveyStat>> getStats({required String baseUrl, required String token}) async {
    final res = await _client
        .get(Uri.parse('$baseUrl/api/onboarding-survey/stats'), headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode >= 400) {
      throw OnboardingSurveyException('Не удалось загрузить статистику (код ${res.statusCode}).');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['stats'] as List<dynamic>;
    return list.map((e) => OnboardingSurveyStat.fromJson(e as Map<String, dynamic>)).toList();
  }

  void dispose() => _client.close();
}

