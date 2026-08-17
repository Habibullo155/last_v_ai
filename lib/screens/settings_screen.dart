import 'package:flutter/material.dart';

import '../state/auth_store.dart';
import '../state/chat_store.dart';
import '../state/theme_store.dart';
import '../utils/auth_navigation.dart';
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
  final ThemeStore themeStore;
  const SettingsScreen({
    super.key,
    required this.authStore,
    required this.chatStore,
    required this.themeStore,
  });

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
                          _sectionLabel('ОФОРМЛЕНИЕ'),
                          AnimatedBuilder(
                            animation: themeStore,
                            builder: (context, _) {
                              return GlassPanel(
                                opacity: 0.08,
                                borderRadius: BorderRadius.circular(18),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Цвет фона', style: TextStyle(color: Colors.white)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: BackgroundVariant.values
                                          .map((v) => Padding(
                                                padding: const EdgeInsets.only(right: 12),
                                                child: _VariantSwatch(
                                                  variant: v,
                                                  selected: themeStore.variant == v,
                                                  onTap: () => themeStore.setVariant(v),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          _sectionLabel('АККАУНТ'),
                          GlassPanel(
                            opacity: 0.08,
                            borderRadius: BorderRadius.circular(18),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => confirmAndLogout(context, authStore),
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
                          const SizedBox(height: 24),
                          _sectionLabel('ОПАСНАЯ ЗОНА'),
                          GlassPanel(
                            opacity: 0.08,
                            borderRadius: BorderRadius.circular(18),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => _showDeleteAccountDialog(context, authStore),
                                child: const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_forever_rounded, color: Color(0xFFFF6B6B)),
                                      SizedBox(width: 12),
                                      Text(
                                        'Удалить аккаунт',
                                        style: TextStyle(color: Color(0xFFFFB4B4), fontWeight: FontWeight.w500),
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

  Future<void> _showDeleteAccountDialog(BuildContext context, AuthStore authStore) async {
    await showDialog(
      context: context,
      builder: (context) => _DeleteAccountDialog(authStore: authStore),
    );
  }
}

/// Отдельный StatefulWidget для диалога — нужно локальное состояние (поле
/// пароля, текст ошибки), а сам SettingsScreen остаётся StatelessWidget.
class _DeleteAccountDialog extends StatefulWidget {
  final AuthStore authStore;
  const _DeleteAccountDialog({required this.authStore});

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _isBusy = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;

    setState(() {
      _isBusy = true;
      _error = null;
    });

    final error = await widget.authStore.deleteAccount(password);

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isBusy = false;
        _error = error;
      });
      return;
    }

    // Аккаунт удалён — закрываем диалог И возвращаемся на корень стека
    // навигации (тот же приём, что и в lib/utils/auth_navigation.dart для
    // обычного выхода): иначе экран настроек, с которого запускалось
    // удаление, так и остался бы виден поверх уже изменившегося состояния
    // "не авторизован" — просто закрыть диалог для этого недостаточно.
    Navigator.of(context).pop();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassPanel(
        opacity: 0.18,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Удалить аккаунт?',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Это необратимо: аккаунт, история обращений в поддержку и '
                'статистика использования будут удалены полностью. История '
                'переписки на этом устройстве останется — она никогда не '
                'хранилась на сервере, и её можно удалить отдельно.',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 16),
              Text(
                'Подтверди паролем',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                autofocus: true,
                onSubmitted: (_) => _isBusy ? null : _confirmDelete(),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  hintText: 'Пароль',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 13)),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isBusy ? null : () => Navigator.of(context).pop(),
                    child: Text('Отмена', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B)),
                    onPressed: _isBusy ? null : _confirmDelete,
                    child: _isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Удалить навсегда'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VariantSwatch extends StatelessWidget {
  final BackgroundVariant variant;
  final bool selected;
  final VoidCallback onTap;
  const _VariantSwatch({required this.variant, required this.selected, required this.onTap});

  List<Color> get _colors {
    switch (variant) {
      case BackgroundVariant.violet:
        return const [Color(0xFF6C5CE7), Color(0xFF00D9C0)];
      case BackgroundVariant.ocean:
        return const [Color(0xFF00B4D8), Color(0xFF4DD0C4)];
      case BackgroundVariant.midnight:
        return const [Color(0xFF3A3A5C), Color(0xFF5B4B8A)];
    }
  }

  String get _label {
    switch (variant) {
      case BackgroundVariant.violet:
        return 'Фиолетовый';
      case BackgroundVariant.ocean:
        return 'Океан';
      case BackgroundVariant.midnight:
        return 'Полночь';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: _colors),
              border: Border.all(
                color: selected ? Colors.white : Colors.white.withOpacity(0.15),
                width: selected ? 2.5 : 1,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(height: 6),
          Text(_label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10.5)),
        ],
      ),
    );
  }
}
