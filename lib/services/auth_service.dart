import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'pinned_http_client.dart';

import 'package:LOMALU/l10n/app_localizations.dart';
import '../models/app_user.dart';

class AuthResult {
  final String token;
  final AppUser user;
  AuthResult({required this.token, required this.user});
}

enum _AuthErrorType {
  networkError,
  unexpectedResponse,
  deleteAccountFailed,
  requestFailed,
  changePasswordFailed,
  resendCodeFailed,
  // раскодированная ошибка от бэкенда (например "Неверный пароль") -
  // остаётся как есть, НЕ локализуется здесь. Сам бэкенд пока отвечает
  // только на русском независимо от языка клиента - перевод текста
  // ошибок FastAPI (каждый HTTPException во всех роутерах) отдельная,
  // намного более крупная задача, не входит в эту правку
  serverMessage,
}

/// Бросается при ожидаемых ошибках сервера (неверный пароль, email занят,
/// и т.п.) — раньше сразу содержал готовую строку на русском, теперь несёт
/// тип + данные, а готовый текст для показа получаешь через
/// localizedMessage(l10n) на стороне вызывающего кода (там, где есть
/// BuildContext) - сам этот класс, как обычный сервис, доступа к
/// BuildContext не имеет.
class AuthException implements Exception {
  final _AuthErrorType _type;
  final String?
  _details; // текст исключения (networkError) или сообщение с бэкенда (serverMessage)
  final int? _statusCode; // для типов, которые просто показывают код ответа

  AuthException.network(String details)
    : _type = _AuthErrorType.networkError,
      _details = details,
      _statusCode = null;
  AuthException.unexpectedResponse(int code)
    : _type = _AuthErrorType.unexpectedResponse,
      _statusCode = code,
      _details = null;
  AuthException.deleteAccountFailed(int code)
    : _type = _AuthErrorType.deleteAccountFailed,
      _statusCode = code,
      _details = null;
  AuthException.requestFailed(int code)
    : _type = _AuthErrorType.requestFailed,
      _statusCode = code,
      _details = null;
  AuthException.changePasswordFailed(int code)
    : _type = _AuthErrorType.changePasswordFailed,
      _statusCode = code,
      _details = null;
  AuthException.resendCodeFailed(int code)
    : _type = _AuthErrorType.resendCodeFailed,
      _statusCode = code,
      _details = null;
  AuthException.server(String? message)
    : _type = _AuthErrorType.serverMessage,
      _details = message,
      _statusCode = null;

  String localizedMessage(AppLocalizations l10n) {
    switch (_type) {
      case _AuthErrorType.networkError:
        return l10n.authNetworkError(_details ?? '');
      case _AuthErrorType.unexpectedResponse:
        return l10n.authUnexpectedResponse(_statusCode ?? 0);
      case _AuthErrorType.deleteAccountFailed:
        return l10n.authDeleteAccountFailed(_statusCode ?? 0);
      case _AuthErrorType.requestFailed:
        return l10n.authRequestFailed(_statusCode ?? 0);
      case _AuthErrorType.changePasswordFailed:
        return l10n.authChangePasswordFailed(_statusCode ?? 0);
      case _AuthErrorType.resendCodeFailed:
        return l10n.authResendCodeFailed(_statusCode ?? 0);
      case _AuthErrorType.serverMessage:
        return _details ?? l10n.authGenericError;
    }
  }

  // для логов/отладки, где локализация не нужна - НЕ показывать эту
  // строку пользователю напрямую, используй localizedMessage(l10n)
  @override
  String toString() =>
      _details ?? 'AuthException(${_type.name}, code: $_statusCode)';
}

class AuthService {
  final http.Client _client = createHttpClient();
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  Future<String?> readStoredToken() => _storage.read(key: _tokenKey);

  Future<void> _storeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

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

  Future<AuthResult> _authRequest(
    String url,
    String email,
    String password,
  ) async {
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
      throw AuthException.network('$e');
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException.unexpectedResponse(res.statusCode);
    }

    if (res.statusCode >= 400) {
      throw AuthException.server(_extractErrorMessage(data));
    }

    final token = data['access_token'] as String;
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    await _storeToken(token);
    return AuthResult(token: token, user: user);
  }

  /// Проверяет токен и возвращает свежие данные пользователя.
  /// Возвращает null, если токен недействителен/истёк — вызывающий код
  /// должен в этом случае разлогинить пользователя.
  Future<AppUser?> fetchMe({
    required String baseUrl,
    required String token,
  }) async {
    try {
      final res = await _client
          .get(
            Uri.parse('$baseUrl/api/auth/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return AppUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Необратимое удаление своего аккаунта — требует подтверждения паролем
  /// на сервере (см. backend/routers_auth.py). Бросает AuthException с
  /// понятным сообщением, если пароль неверный или сервер недоступен.
  Future<void> deleteAccount({
    required String baseUrl,
    required String token,
    required String password,
  }) async {
    http.Response res;
    try {
      res = await _client
          .delete(
            Uri.parse('$baseUrl/api/auth/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'password': password}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw AuthException.network('$e');
    }

    if (res.statusCode >= 400) {
      Map<String, dynamic> data;
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        throw AuthException.deleteAccountFailed(res.statusCode);
      }
      throw AuthException.server(_extractErrorMessage(data));
    }

    await clearToken();
  }

  /// Обновляет только СВОИ поля профиля (ФИО, возраст, хобби) — не все
  /// три обязательны разом, можно прислать одно. Передавай явный `null`
  /// в соответствующем параметре, чтобы очистить поле, а не просто
  /// пропускай его — пропущенный параметр здесь и так не попадёт в тело
  /// запроса (см. ниже), так что это разделение делает сам вызывающий код.
  Future<AppUser> updateProfile({
    required String baseUrl,
    required String token,
    Map<String, dynamic>? fields,
  }) async {
    http.Response res;
    try {
      res = await _client
          .patch(
            Uri.parse('$baseUrl/api/auth/me/profile'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(fields ?? {}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw AuthException.network('$e');
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException.unexpectedResponse(res.statusCode);
    }

    if (res.statusCode >= 400) {
      throw AuthException.server(_extractErrorMessage(data));
    }

    return AppUser.fromJson(data);
  }

  /// Backend отвечает 204 без тела при успехе - в отличие от остальных
  /// методов здесь нечего декодировать в успешном случае, только на
  /// ошибке приходит JSON с detail.
  Future<void> changePassword({
    required String baseUrl,
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    http.Response res;
    try {
      res = await _client
          .patch(
            Uri.parse('$baseUrl/api/auth/me/password'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'current_password': currentPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw AuthException.network('$e');
    }

    if (res.statusCode >= 400) {
      Map<String, dynamic> data;
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        throw AuthException.changePasswordFailed(res.statusCode);
      }
      throw AuthException.server(_extractErrorMessage(data));
    }
  }

  /// Первый шаг смены почты - код уходит на НОВЫЙ адрес, сама почта
  /// пока не меняется (см. подтверждение ниже).
  Future<void> requestEmailChange({
    required String baseUrl,
    required String token,
    required String newEmail,
    required String currentPassword,
  }) async {
    http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$baseUrl/api/auth/me/email/request-change'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'new_email': newEmail,
              'current_password': currentPassword,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw AuthException.network('$e');
    }

    if (res.statusCode >= 400) {
      Map<String, dynamic> data;
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        throw AuthException.unexpectedResponse(res.statusCode);
      }
      throw AuthException.server(_extractErrorMessage(data));
    }
  }

  /// Второй шаг - код, присланный на новый адрес, применяет смену.
  Future<AppUser> confirmEmailChange({
    required String baseUrl,
    required String token,
    required String changeToken,
  }) async {
    http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$baseUrl/api/auth/me/email/confirm-change'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'token': changeToken}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw AuthException.network('$e');
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException.unexpectedResponse(res.statusCode);
    }

    if (res.statusCode >= 400) {
      throw AuthException.server(_extractErrorMessage(data));
    }

    return AppUser.fromJson(data);
  }

  /// Всегда завершается успешно (сервер намеренно отвечает одинаково, есть
  /// такой email или нет - см. комментарий в routers_auth.py), кроме
  /// реальных сетевых сбоев или превышения лимита запросов (429).
  Future<void> forgotPassword({
    required String baseUrl,
    required String email,
  }) async {
    http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$baseUrl/api/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw AuthException.network('$e');
    }

    if (res.statusCode >= 400) {
      Map<String, dynamic> data;
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        throw AuthException.requestFailed(res.statusCode);
      }
      throw AuthException.server(_extractErrorMessage(data));
    }
  }

  Future<void> resetPassword({
    required String baseUrl,
    required String token,
    required String newPassword,
  }) async {
    http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$baseUrl/api/auth/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token, 'new_password': newPassword}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw AuthException.network('$e');
    }

    if (res.statusCode >= 400) {
      Map<String, dynamic> data;
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        throw AuthException.changePasswordFailed(res.statusCode);
      }
      throw AuthException.server(_extractErrorMessage(data));
    }
  }

  /// Возвращает свежие данные пользователя (is_email_verified теперь true) -
  /// вызывающий код (AuthStore) должен обновить своё поле user этим
  /// результатом, иначе баннер "подтвердите почту" не пропадёт до
  /// следующего перезапуска приложения.
  Future<AppUser> verifyEmail({
    required String baseUrl,
    required String token,
  }) async {
    http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$baseUrl/api/auth/verify-email'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw AuthException.network('$e');
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException.unexpectedResponse(res.statusCode);
    }

    if (res.statusCode >= 400) {
      throw AuthException.server(_extractErrorMessage(data));
    }

    return AppUser.fromJson(data);
  }

  Future<void> resendVerification({
    required String baseUrl,
    required String token,
  }) async {
    http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$baseUrl/api/auth/resend-verification'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw AuthException.network('$e');
    }

    if (res.statusCode >= 400) {
      Map<String, dynamic> data;
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        throw AuthException.resendCodeFailed(res.statusCode);
      }
      throw AuthException.server(_extractErrorMessage(data));
    }
  }

  /// FastAPI отдаёт ошибки в двух разных формах:
  /// - {"detail": "текст"} — наши собственные HTTPException;
  /// - {"detail": [{"msg": "...", "loc": [...]}, ...]} — автоматическая
  ///   валидация pydantic (например, слишком короткий пароль). Без этой
  ///   проверки код упал бы на приведении List к String.
  ///
  /// Текст, который возвращает эта функция, приходит С БЭКЕНДА как есть -
  /// он пока не локализован независимо от языка клиента (см. комментарий
  /// у _AuthErrorType.serverMessage выше). null - если извлечь ничего не
  /// удалось; тогда AuthException.localizedMessage сам подставит
  /// локализованный общий текст ошибки, а не жёстко зашитую русскую строку.
  String? _extractErrorMessage(Map<String, dynamic> data) {
    final detail = data['detail'];
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final messages = detail
          .map((e) => e is Map ? e['msg']?.toString() : e.toString())
          .whereType<String>()
          .toList();
      if (messages.isNotEmpty) return messages.join('\n');
    }
    return null;
  }

  void dispose() => _client.close();
}
