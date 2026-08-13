import 'package:flutter/material.dart';

import '../state/chat_store.dart';
import 'glass_panel.dart';

/// Только индикатор состояния сервера — без возможности его сменить.
/// Адрес бэкенда задаётся один раз при сборке приложения
/// (--dart-define=BACKEND_URL=..., см. lib/config.dart), обычный
/// пользователь не должен иметь возможность перенаправить приложение на
/// произвольный сервер прямо из интерфейса. Тап по пиндлу просто
/// перепроверяет статус ещё раз.
class BackendStatusPill extends StatelessWidget {
  final ChatStore store;
  const BackendStatusPill({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final (color, label) = switch (store.backendStatus) {
          BackendStatus.online => (const Color(0xFF00E6A0), 'Сервер онлайн'),
          BackendStatus.offline => (const Color(0xFFFF6B6B), 'Сервер недоступен'),
          BackendStatus.checking => (const Color(0xFFFFD166), 'Проверка…'),
          BackendStatus.unknown => (Colors.white38, 'Неизвестно'),
        };
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: store.refreshBackendStatus,
          child: GlassPanel(
            opacity: 0.10,
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.7), blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
