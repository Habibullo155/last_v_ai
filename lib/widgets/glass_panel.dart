import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_text_color.dart';

// стеклянный контейнер: размытие + полупрозрачная заливка + обводка + тень
//
// tint: null = белое "матовое стекло" всегда, независимо от темы - не
// завязано на цвет текста темы. В тёмном режиме белая плёнка поверх
// тёмного фона и так давала красивый результат; в светлом режиме та же
// логика раньше брала context.onSurface (тёмно-синий, цвет ТЕКСТА) как
// тон стекла - на светлом фоне это давало грязно-тёмную панель, а не
// стекло. Белый тон работает в обе стороны: светлеет то, что под ним,
// как и должно вести себя настоящее матовое стекло
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
    final effectiveTint = tint ?? Colors.white;
    // раньше каждый вызов передавал свою фиксированную opacity (0.06-0.18
    // в разных местах), значение темы никак её не трогало - "сделать
    // светлую тему прозрачнее" точечно менять дефолт бесполезно, почти
    // никто его не использует. Вместо этого масштабируем РЕАЛЬНУЮ
    // непрозрачность здесь, в одном месте - тёмный режим не трогаем
    // вообще (множитель 1), светлый становится заметно прозрачнее
    final isLight = Theme.of(context).brightness == Brightness.light;
    final scaledOpacity = isLight ? opacity * 0.55 : opacity;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveTint.withOpacity(scaledOpacity),
        borderRadius: borderRadius,
        border: border ??
            Border.all(
              color: context.onSurfaceFaded(isLight ? 0.12 : 0.18),
              width: 1.2,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLight ? 0.12 : 0.25),
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
