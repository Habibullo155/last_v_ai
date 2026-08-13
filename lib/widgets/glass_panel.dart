import 'dart:ui';
import 'package:flutter/material.dart';

/// Базовый "стеклянный" контейнер: размытие фона + полупрозрачная
/// заливка + тонкая светлая обводка + мягкая тень.
///
/// [blurred] управляет тем, применяется ли реальное размытие фона
/// (`BackdropFilter`) — по умолчанию да. `BackdropFilter` заставляет движок
/// делать отдельный saveLayer + блюр-проход на каждый экземпляр виджета —
/// для нескольких фиксированных панелей на экране (шапка, сайдбар, диалоги)
/// это незаметно, но если таким виджетом рисовать КАЖДОЕ сообщение в
/// прокручиваемом списке (потенциально десятки одновременно видимых), это
/// заметно бьёт по плавности скролла — каждый кадр система заново считает
/// блюр для всех видимых пузырей. Для таких мест передавай `blurred: false`:
/// эффект "стекла" сохраняется (полупрозрачная заливка + обводка), просто
/// без дорогого размытия того, что под ним.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color tint;
  final Border? border;
  final bool blurred;

  const GlassPanel({
    super.key,
    required this.child,
    this.blur = 22,
    this.opacity = 0.10,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding,
    this.tint = Colors.white,
    this.border,
    this.blurred = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tint.withOpacity(opacity),
        borderRadius: borderRadius,
        border: border ??
            Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1.2,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );

    if (!blurred) {
      // Без ClipRRect/BackdropFilter — дешевле, но края останутся резкими
      // только в смысле отсутствия блюра снаружи; сама заливка всё ещё со
      // скруглением через BoxDecoration.borderRadius выше.
      return content;
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );
  }
}
