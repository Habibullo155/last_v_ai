import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../state/theme_store.dart';
import '../theme/background_variant.dart';

/// Тёмный фон с плавающими цветными "бликами" — база для эффекта
/// глазморфизма (стеклянные панели поверх размытых цветных пятен).
///
/// Раньше здесь была ещё и полноценная светлая тема — убрана осознанно:
/// у приложения весь текст захардкожен белым по коду, и честная светлая
/// тема потребовала бы переписать цвет текста в каждом месте без
/// возможности визуально проверить контраст. Вместо этого — несколько
/// вариантов ТЁМНОГО фона с разными акцентными цветами (см.
/// BackgroundVariant), выбираются в настройках, текст везде остаётся
/// читаемым в любом варианте.
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

  _Palette _paletteFor(BackgroundVariant variant) {
    switch (variant) {
      case BackgroundVariant.violet:
        return const _Palette(
          base: [Color(0xFF0B0F1E), Color(0xFF141A2E), Color(0xFF0B0F1E)],
          blob1: Color(0xFF6C5CE7),
          blob2: Color(0xFF00D9C0),
          blob3: Color(0xFFFF7AC6),
        );
      case BackgroundVariant.ocean:
        return const _Palette(
          base: [Color(0xFF071A24), Color(0xFF0C2836), Color(0xFF071A24)],
          blob1: Color(0xFF00B4D8),
          blob2: Color(0xFF4DD0C4),
          blob3: Color(0xFF3A7CA5),
        );
      case BackgroundVariant.midnight:
        return const _Palette(
          base: [Color(0xFF08080F), Color(0xFF12121C), Color(0xFF08080F)],
          blob1: Color(0xFF3A3A5C),
          blob2: Color(0xFF5B4B8A),
          blob3: Color(0xFF2E2E48),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeStore.instance,
      builder: (context, _) {
        final palette = _paletteFor(ThemeStore.instance.variant);
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
                      opacity: 0.55,
                    ),
                    _blob(
                      color: palette.blob2,
                      alignment: Alignment(-0.9 + math.sin(t * 0.7) * 0.4, math.cos(t) * 0.9),
                      size: 380,
                      opacity: 0.55,
                    ),
                    _blob(
                      color: palette.blob3,
                      alignment: Alignment(0.9 * math.cos(t * 0.5), 0.9 * math.sin(t * 0.9)),
                      size: 340,
                      opacity: 0.55,
                    ),
                  ],
                );
              },
            ),
            // Лёгкое затемнение сверху, чтобы блики не были слишком яркими.
            Container(color: Colors.black.withOpacity(0.25)),
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
