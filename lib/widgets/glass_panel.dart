import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_text_color.dart';

// стеклянный контейнер: размытие + полупрозрачная заливка + обводка + тень
//
// tint: null = нейтральный цвет, подстраивается под тему. Не Colors.white
// по умолчанию, потому что дефолты параметров в Dart должны быть
// compile-time константами, а цвет от темы - нет (нужен BuildContext)
//
// blurred: false для списков (сообщения в чате) - BackdropFilter на
// каждый элемент прокручиваемого списка заметно бьёт по FPS, эффект
// стекла остаётся и без него (заливка + обводка), просто без блюра фона
class GlassPanel extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final Border? border;
  final bool blurred;

  const GlassPanel({
    super.key,
    required this.child,
    this.blur = 22,
    this.opacity = 0.10,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding,
    this.tint,
    this.border,
    this.blurred = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTint = tint ?? context.onSurface;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveTint.withOpacity(opacity),
        borderRadius: borderRadius,
        border: border ??
            Border.all(
              color: context.onSurfaceFaded(0.18),
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

    if (!blurred) return content;  // без ClipRRect/BackdropFilter, дешевле

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );
  }
}
