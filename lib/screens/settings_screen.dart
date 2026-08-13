import 'package:flutter/material.dart';

import '../state/auth_store.dart';
import '../state/chat_store.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

/// Адрес сервера здесь только отображается — редактировать его в
/// приложении больше нельзя, он задаётся один раз при сборке через
/// --dart-define=BACKEND_URL=... (см. lib/config.dart). Это осознанное
/// решение: рядовой пользователь не должен иметь возможность
/// перенаправить приложение на произвольный сервер.
class SettingsScreen extends StatelessWidget {
  final AuthStore authStore;
  final ChatStore chatStore;
  const SettingsScreen({super.key, required this.authStore, required this.chatStore});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Настройки',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sectionLabel('АККАУНТ'),
                          GlassPanel(
                            opacity: 0.08,
                            borderRadius: BorderRadius.circular(18),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: authStore.logout,
                                child: const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(Icons.logout_rounded, color: Colors.white70),
                                      SizedBox(width: 12),
                                      Text('Выйти из аккаунта', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _sectionLabel('О ПРИЛОЖЕНИИ'),
                          GlassPanel(
                            opacity: 0.08,
                            borderRadius: BorderRadius.circular(18),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('AI Glass Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('Версия 1.0.0', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12.5)),
                                const SizedBox(height: 8),
                                Text(
                                  'Модель по умолчанию: gemma4:e2b через локальный Ollama.',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Сервер: ${chatStore.baseUrl}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
