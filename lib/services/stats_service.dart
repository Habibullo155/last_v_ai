import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/dashboard_stats.dart';

class StatsException implements Exception {
  final String message;
  StatsException(this.message);
  @override
  String toString() => message;
}

class StatsService {
  final http.Client _client = http.Client();

  Future<DashboardStats> getDashboardStats({required String baseUrl, required String token}) async {
    final res = await _client
        .get(
          Uri.parse('$baseUrl/api/admin/stats'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) {
      throw StatsException('Не удалось загрузить статистику (код ${res.statusCode}).');
    }
    return DashboardStats.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  void dispose() => _client.close();
}
