import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config.dart';
import '../models/app_user.dart';
import 'package:ai_last_v/services/auth_service.dart' as auth_svc;

enum AuthStatus { unknown, checking, authenticated, unauthenticated }

class AuthStore extends ChangeNotifier {
  final auth_svc.AuthService _authService = auth_svc.AuthService();

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;
  String? token;
  String? lastError;
  bool isBusy = false;

  /// Адрес бэкенда — только из --dart-define=BACKEND_URL=... на этапе
  /// сборки (см. lib/config.dart), не редактируется в приложении. Раньше
  /// тут была кнопка сменить сервер прямо в интерфейсе — убрали: рядовой
  /// пользователь не должен иметь возможность перенаправить приложение на
  /// произвольный сервер.
  final String baseUrl = AppConfig.backendUrl;

  /// При старте приложения: смотрим, есть ли сохранённый токен, и если
  /// да — проверяем его на сервере (он мог истечь или его могли отозвать).
  Future<void> restoreSession() async {
    status = AuthStatus.checking;
    notifyListeners();

    final storedToken = await _authService.readStoredToken();
    if (storedToken == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    final freshUser = await _authService.fetchMe(baseUrl: baseUrl, token: storedToken);
    if (freshUser == null) {
      // Токен истёк/недействителен, или сервер сейчас недоступен —
      // в обоих случаях просим войти заново, это безопаснее, чем
      // притворяться, что всё в порядке.
      await _authService.clearToken();
      status = AuthStatus.unauthenticated;
    } else {
      token = storedToken;
      user = freshUser;
      status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<bool> register(String email, String password) =>
      _attempt(() => _authService.register(baseUrl: baseUrl, email: email, password: password));

  Future<bool> login(String email, String password) =>
      _attempt(() => _authService.login(baseUrl: baseUrl, email: email, password: password));

  Future<bool> _attempt(Future<auth_svc.AuthResult> Function() action) async {
    isBusy = true;
    lastError = null;
    notifyListeners();
    try {
      final result = await action();
      token = result.token;
      user = result.user;
      status = AuthStatus.authenticated;
      return true;
    } on auth_svc.AuthException catch (e) {
      lastError = e.message;
      return false;
    } catch (e) {
      lastError = 'Непредвиденная ошибка: $e';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.clearToken();
    token = null;
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Необратимо удаляет аккаунт пользователя (требует пароль — см.
  /// backend/routers_auth.py). Возвращает null при успехе, иначе — текст
  /// ошибки для показа в UI (например "неверный пароль").
  Future<String?> deleteAccount(String password) async {
    final currentToken = token;
    if (currentToken == null) return 'Сессия не найдена. Войди заново.';

    isBusy = true;
    notifyListeners();
    try {
      await _authService.deleteAccount(baseUrl: baseUrl, token: currentToken, password: password);
      token = null;
      user = null;
      status = AuthStatus.unauthenticated;
      return null;
    } on auth_svc.AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Непредвиденная ошибка: $e';
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
