import 'package:ai_last_v/widgets/app_background.dart';
import 'package:flutter/material.dart';

import 'package:ai_last_v/l10n/app_localizations.dart';
import '../state/auth_store.dart';
import '../state/chat_store.dart';
import '../state/theme_store.dart';
import '../state/voice_store.dart';
import '../widgets/glass_panel.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'sleep_music_screen.dart';
import 'wellbeing_screen.dart';

/// Только для мобильных — на десктопе/планшете как было: один ChatScreen
/// с выпадающим меню (см. app.dart, Responsive.isMobile решает, что
/// показать). Три главных раздела как переключаемые вкладки без потери
/// состояния между переходами (IndexedStack держит их все смонтированными,
/// а не пересоздаёт заново при каждом переключении), остальное — доступно,
/// как и раньше, через меню внутри самого чата.
class MainShellScreen extends StatefulWidget {
  final ChatStore store;
  final AuthStore authStore;
  final ThemeStore themeStore;
  final VoiceStore voiceStore;
  const MainShellScreen({
    super.key,
    required this.store,
    required this.authStore,
    required this.themeStore,
    required this.voiceStore,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = 0;
  // Ленивая первая загрузка - раньше все 4 экрана строились сразу при
  // старте приложения и IndexedStack держал их все смонтированными
  // навсегда, даже если человек ни разу не открывал, скажем, "Профиль".
  // Каждый такой экран - это списки, контроллеры, слушатели стора - реальная
  // память и работа сборщика мусора впустую для вкладок, которые ещё
  // никто не открывал. Теперь вкладка строится только при первом реальном
  // переходе на неё; после этого - как раньше, состояние сохраняется
  // между переключениями (IndexedStack не пересоздаёт уже посещённые).
  //
  // Честно про оставшийся компромисс: после первого посещения вкладка
  // остаётся смонтированной навсегда (пока не закрыт весь MainShellScreen) -
  // это НАМЕРЕННО, ради сохранения состояния (текст, ещё не отправленный
  // в чате; позиция скролла; играющий плеер в SleepMusicScreen - там
  // продолжать играть при переходе на другую вкладку часто и есть
  // ожидаемое поведение, не баг). Единственный периодический Timer среди
  // этих экранов - обратный отсчёт "спящего таймера" в SleepMusicScreen,
  // и он должен тикать, пока активен, вне зависимости от того, какая
  // вкладка сейчас открыта. Самая дорогая часть (у каждой вкладки был
  // СВОЙ анимированный фон, значит одновременно работали 4 таймера
  // анимации бликов сразу) уже убрана - см. комментарий у AppBackground
  // ниже.
  final Set<int> _visitedIndices = {0};

  void _goToIndex(int i) {
    if (!mounted) return;
    setState(() {
      _index = i;
      _visitedIndices.add(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.authStore.user?.id.toString() ?? '';

    final pages = [
      ChatScreen(
        store: widget.store,
        authStore: widget.authStore,
        themeStore: widget.themeStore,
        voiceStore: widget.voiceStore,
        hideShellDuplicates: true,
      ),
      if (_visitedIndices.contains(1))
        WellbeingScreen(
          userId: userId,
          voiceStore: widget.voiceStore,
          authStore: widget.authStore,
          showOwnBackground: false,
          onStartAiConversation: (text) async {
            // без createNewChat() - не обрываем уже идущий разговор ради
            // нового, см. тот же фикс в chat_screen.dart::_chooseTest()
            await widget.store.sendMessage(text);
            _goToIndex(0);
          },
        )
      else
        const SizedBox.shrink(),
      if (_visitedIndices.contains(2))
        ProfileScreen(authStore: widget.authStore, showOwnBackground: false)
      else
        const SizedBox.shrink(),
      if (_visitedIndices.contains(3))
        SleepMusicScreen(authStore: widget.authStore, showOwnBackground: false)
      else
        const SizedBox.shrink(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1E),
      // ОДИН общий фон на всю оболочку - раньше каждая из 4 вкладок несла
      // СВОЙ отдельный AppBackground, а IndexedStack держит все вкладки
      // смонтированными одновременно (не только видимую), значит на
      // мобильном реально работали 4 параллельных таймера анимации бликов
      // разом, даже когда видна была только одна вкладка. Теперь - ровно
      // один, у каждого дочернего экрана enabled: false (или
      // hideShellDuplicates: true у ChatScreen, тот же смысл)
      body: AppBackground(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: _GlassBottomNav(index: _index, onTap: _goToIndex),
    );
  }
}

class _GlassBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _GlassBottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Явно указываем тип списка, чтобы Dart не путался
    final List<({Widget icon, String label})> items = [
      (
        icon: Image.asset(
          'assets/images/ai_icon.png',
          width: 24,
          height: 24,
          fit: BoxFit.cover,
        ),
        label: l10n.navChat,
      ),
      // Оборачиваем остальные элементы в виджет Icon!
      (
        icon: const Icon(Icons.self_improvement_rounded),
        label: l10n.navWellbeing,
      ),
      (icon: const Icon(Icons.person_rounded), label: l10n.navProfile),
      (icon: const Icon(Icons.music_note_rounded), label: l10n.navSleep),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: GlassPanel(
          opacity: 0.1,
          borderRadius: BorderRadius.circular(24),
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                items.length,
                (i) => _buildItem(i, items),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int i, List<({Widget icon, String label})> items) {
    final selected = i == index;
    final item = items[i];

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: selected
                  ? const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFF00B4D8)],
                    )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // IconTheme заставит иконки менять цвет при выборе,
                // при этом не сломает твою картинку (Image)
                IconTheme(
                  data: IconThemeData(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    size: 24,
                  ),
                  child: item.icon,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
