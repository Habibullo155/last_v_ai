import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../state/theme_store.dart';
import '../theme/background_variant.dart';

// анимированный фон с плавающими цветными бликами - база глазморфизма.
// У каждого из 9 вариантов своя палитра для тёмного и светлого режима
class AppBackground extends StatefulWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _Palette _paletteFor(BackgroundVariant variant, AppThemeMode mode) {
    final isLight = mode == AppThemeMode.light;
    switch (variant) {
      case BackgroundVariant.violet:
        return isLight
            ? const _Palette(
                base: [Color(0xFFF3F0FF), Color(0xFFEAE4FF), Color(0xFFF3F0FF)],
                blob1: Color(0xFF6C5CE7),
                blob2: Color(0xFF00D9C0),
                blob3: Color(0xFFFF7AC6),
              )
            : const _Palette(
                base: [Color(0xFF0B0F1E), Color(0xFF141A2E), Color(0xFF0B0F1E)],
                blob1: Color(0xFF6C5CE7),
                blob2: Color(0xFF00D9C0),
                blob3: Color(0xFFFF7AC6),
              );
      case BackgroundVariant.ocean:
        return isLight
            ? const _Palette(
                base: [Color(0xFFEAF7FB), Color(0xFFDDF1F6), Color(0xFFEAF7FB)],
                blob1: Color(0xFF00B4D8),
                blob2: Color(0xFF4DD0C4),
                blob3: Color(0xFF3A7CA5),
              )
            : const _Palette(
                base: [Color(0xFF071A24), Color(0xFF0C2836), Color(0xFF071A24)],
                blob1: Color(0xFF00B4D8),
                blob2: Color(0xFF4DD0C4),
                blob3: Color(0xFF3A7CA5),
              );
      case BackgroundVariant.midnight:
        return isLight
            ? const _Palette(
                base: [Color(0xFFF0F0F5), Color(0xFFE6E6EF), Color(0xFFF0F0F5)],
                blob1: Color(0xFF7B6EAE),
                blob2: Color(0xFF9B8ACB),
                blob3: Color(0xFF5B4B8A),
              )
            : const _Palette(
                base: [Color(0xFF08080F), Color(0xFF12121C), Color(0xFF08080F)],
                blob1: Color(0xFF3A3A5C),
                blob2: Color(0xFF5B4B8A),
                blob3: Color(0xFF2E2E48),
              );
      case BackgroundVariant.sunset:
        return isLight
            ? const _Palette(
                base: [Color(0xFFFFF1E9), Color(0xFFFFE4D6), Color(0xFFFFF1E9)],
                blob1: Color(0xFFFF7E5F),
                blob2: Color(0xFFFEB47B),
                blob3: Color(0xFFE8618C),
              )
            : const _Palette(
                base: [Color(0xFF1F0F12), Color(0xFF2B1418), Color(0xFF1F0F12)],
                blob1: Color(0xFFFF7E5F),
                blob2: Color(0xFFFEB47B),
                blob3: Color(0xFFE8618C),
              );
      case BackgroundVariant.forest:
        return isLight
            ? const _Palette(
                base: [Color(0xFFEDF7EE), Color(0xFFE0F1E3), Color(0xFFEDF7EE)],
                blob1: Color(0xFF2E8B57),
                blob2: Color(0xFF6FCF97),
                blob3: Color(0xFF1B5E4A),
              )
            : const _Palette(
                base: [Color(0xFF0A1710), Color(0xFF102218), Color(0xFF0A1710)],
                blob1: Color(0xFF2E8B57),
                blob2: Color(0xFF6FCF97),
                blob3: Color(0xFF1B5E4A),
              );
      case BackgroundVariant.rose:
        return isLight
            ? const _Palette(
                base: [Color(0xFFFDF0F4), Color(0xFFFCE2EA), Color(0xFFFDF0F4)],
                blob1: Color(0xFFE0568C),
                blob2: Color(0xFFFF9EBB),
                blob3: Color(0xFFB23A6B),
              )
            : const _Palette(
                base: [Color(0xFF1A0A12), Color(0xFF25101B), Color(0xFF1A0A12)],
                blob1: Color(0xFFE0568C),
                blob2: Color(0xFFFF9EBB),
                blob3: Color(0xFFB23A6B),
              );
      case BackgroundVariant.amber:
        return isLight
            ? const _Palette(
                base: [Color(0xFFFFF8E6), Color(0xFFFFEFC7), Color(0xFFFFF8E6)],
                blob1: Color(0xFFE8A33D),
                blob2: Color(0xFFFFD166),
                blob3: Color(0xFFC97B1F),
              )
            : const _Palette(
                base: [Color(0xFF1C1608), Color(0xFF29200D), Color(0xFF1C1608)],
                blob1: Color(0xFFE8A33D),
                blob2: Color(0xFFFFD166),
                blob3: Color(0xFFC97B1F),
              );
      case BackgroundVariant.slate:
        return isLight
            ? const _Palette(
                base: [Color(0xFFF1F3F5), Color(0xFFE4E8EC), Color(0xFFF1F3F5)],
                blob1: Color(0xFF5C7A99),
                blob2: Color(0xFF8FA8BF),
                blob3: Color(0xFF3D5266),
              )
            : const _Palette(
                base: [Color(0xFF0D1114), Color(0xFF161C21), Color(0xFF0D1114)],
                blob1: Color(0xFF5C7A99),
                blob2: Color(0xFF8FA8BF),
                blob3: Color(0xFF3D5266),
              );
      case BackgroundVariant.mint:
        return isLight
            ? const _Palette(
                base: [Color(0xFFEBFAF6), Color(0xFFD9F3EC), Color(0xFFEBFAF6)],
                blob1: Color(0xFF00D9C0),
                blob2: Color(0xFF6FE7D4),
                blob3: Color(0xFF00A891),
              )
            : const _Palette(
                base: [Color(0xFF071815), Color(0xFF0C221E), Color(0xFF071815)],
                blob1: Color(0xFF00D9C0),
                blob2: Color(0xFF6FE7D4),
                blob3: Color(0xFF00A891),
              );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeStore.instance,
      builder: (context, _) {
        final isLight = ThemeStore.instance.mode == AppThemeMode.light;
        final palette = _paletteFor(ThemeStore.instance.variant, ThemeStore.instance.mode);
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: palette.base,
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value * 2 * math.pi;
                return Stack(
                  children: [
                    _blob(
                      color: palette.blob1,
                      alignment: Alignment(math.sin(t) * 0.8, -0.9 + math.cos(t) * 0.3),
                      size: 420,
                      // раньше 0.22 + плёнка 0.45 ниже почти полностью
                      // вымывали цвет - фон казался "пропавшим". Теперь
                      // блики заметно ярче, плёнка снята почти до нуля -
                      // мягкость обеспечивают уже сами пастельные базовые
                      // цвета палитры (см. _paletteFor выше), не плёнка
                      opacity: isLight ? 0.4 : 0.55,
                    ),
                    _blob(
                      color: palette.blob2,
                      alignment: Alignment(-0.9 + math.sin(t * 0.7) * 0.4, math.cos(t) * 0.9),
                      size: 380,
                      opacity: isLight ? 0.4 : 0.55,
                    ),
                    _blob(
                      color: palette.blob3,
                      alignment: Alignment(0.9 * math.cos(t * 0.5), 0.9 * math.sin(t * 0.9)),
                      size: 340,
                      opacity: isLight ? 0.4 : 0.55,
                    ),
                  ],
                );
              },
            ),
            // тёмный режим: чёрная плёнка притушивает блики, чтобы они не
            // резали глаз на тёмном фоне. Светлый режим - лёгкая белая
            // плёнка, почти незаметная - только слегка смягчает края
            // бликов, не вымывает цвет целиком
            if (isLight) Container(color: Colors.white.withOpacity(0.12)),
            if (!isLight) Container(color: Colors.black.withOpacity(0.25)),
            widget.child,
          ],
        );
      },
    );
  }

  Widget _blob({
    required Color color,
    required Alignment alignment,
    required double size,
    required double opacity,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), color.withOpacity(0.0)],
          ),
        ),
      ),
    );
  }
}

class _Palette {
  final List<Color> base;
  final Color blob1;
  final Color blob2;
  final Color blob3;
  const _Palette({required this.base, required this.blob1, required this.blob2, required this.blob3});
}
