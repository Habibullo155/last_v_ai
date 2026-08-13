import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  // Без этого необработанное исключение в асинхронном коде (Future,
  // например ошибка внутри callback'а, который никто не await'ит) просто
  // тихо теряется — runZonedGuarded гарантирует, что она хотя бы попадёт
  // в лог, а не исчезнет незаметно.
  runZonedGuarded(
    () {
      // Дефолтный "красный экран смерти" Flutter при ошибке рендеринга —
      // не то, что должен увидеть обычный пользователь. Показываем свой
      // стилизованный экран вместо него.
      ErrorWidget.builder = (FlutterErrorDetails details) => _FriendlyErrorScreen(details: details);

      // Логируем и не даём ошибке молча пройти мимо. Сюда же в будущем
      // можно подключить сервис сбора крашей (Sentry/Crashlytics и т.п.).
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
      };

      runApp(const GlassChatApp());
    },
    (error, stack) {
      // Ошибки вне дерева виджетов (асинхронные, не пойманные FlutterError)
      // — хотя бы печатаем, чтобы не потерялись бесследно при отладке.
      debugPrint('Необработанная ошибка: $error\n$stack');
    },
  );
}

class _FriendlyErrorScreen extends StatelessWidget {
  final FlutterErrorDetails details;
  const _FriendlyErrorScreen({required this.details});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B0F1E),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white38, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Что-то пошло не так',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Попробуй вернуться назад или перезапустить приложение.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
