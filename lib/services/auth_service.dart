import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/app_user.dart';

class AuthResult {
  final String token;
  final AppUser user;
  AuthResult({required this.token, required this.user});
}

/// Бросается при ожидаемых ошибках сервера (неверный пароль, email занят,
/// и т.п.) — содержит понятное сообщение из ответа бэкенда.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  final http.Client _client = http.Client();
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  Future<String?> readStoredToken() => _storage.read(key: _tokenKey);

  Future<void> _storeToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<AuthResult> register({
    required String baseUrl,
    required String email,
    required String password,
  }) => _authRequest('$baseUrl/api/auth/register', email, password);

  Future<AuthResult> login({
    required String baseUrl,
    required String email,
    required String password,
  }) => _authRequest('$baseUrl/api/auth/login', email, password);

  Future<AuthResult> _authRequest(String url, String email, String password) async {
    http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw AuthException('Не удалось связаться с сервером.\n$e');
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException('Сервер вернул неожиданный ответ (код ${res.statusCode}).');
    }

    if (res.statusCode >= 400) {
      throw AuthException(_extractErrorMessage(data));
    }

    final token = data['access_token'] as String;
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    await _storeToken(token);
    return AuthResult(token: token, user: user);
  }

  /// Проверяет токен и возвращает свежие данные пользователя.
  /// Возвращает null, если токен недействителен/истёк — вызывающий код
  /// должен в этом случае разлогинить пользователя.
  Future<AppUser?> fetchMe({required String baseUrl, required String token}) async {
    try {
      final res = await _client.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return AppUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// FastAPI отдаёт ошибки в двух разных формах:
  /// - {"detail": "текст"} — наши собственные HTTPException;
  /// - {"detail": [{"msg": "...", "loc": [...]}, ...]} — автоматическая
  ///   валидация pydantic (например, слишком короткий пароль). Без этой
  ///   проверки код упал бы на приведении List к String.
  String _extractErrorMessage(Map<String, dynamic> data) {
    final detail = data['detail'];
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final messages = detail
          .map((e) => e is Map ? e['msg']?.toString() : e.toString())
          .whereType<String>()
          .toList();
      if (messages.isNotEmpty) return messages.join('\n');
    }
    return 'Ошибка авторизации.';
  }

  void dispose() => _client.close();
}
