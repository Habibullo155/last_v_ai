import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Тёмный фон с плавающими цветными "бликами" — база для эффекта
/// глазморфизма (стеклянные панели поверх размытых цветных пятен).
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Базовый тёмный градиент
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B0F1E),
                Color(0xFF141A2E),
                Color(0xFF0B0F1E),
              ],
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
                  color: const Color(0xFF6C5CE7),
                  alignment: Alignment(math.sin(t) * 0.8, -0.9 + math.cos(t) * 0.3),
                  size: 420,
                ),
                _blob(
                  color: const Color(0xFF00D9C0),
                  alignment: Alignment(-0.9 + math.sin(t * 0.7) * 0.4, math.cos(t) * 0.9),
                  size: 380,
                ),
                _blob(
                  color: const Color(0xFFFF7AC6),
                  alignment: Alignment(0.9 * math.cos(t * 0.5), 0.9 * math.sin(t * 0.9)),
                  size: 340,
                ),
              ],
            );
          },
        ),
        // Лёгкое затемнение сверху, чтобы блики не были слишком яркими
        Container(color: Colors.black.withOpacity(0.25)),
        widget.child,
      ],
    );
  }

  Widget _blob({
    required Color color,
    required Alignment alignment,
    required double size,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.55), color.withOpacity(0.0)],
          ),
        ),
      ),
    );
  }
}
