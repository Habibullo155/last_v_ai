import 'dart:math' as math;

import 'package:ai_last_v/l10n/app_localizations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../models/sound_asset.dart';
import '../services/sounds_service.dart';
import '../state/auth_store.dart';
import '../theme/app_text_color.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

enum _ReleaseMode { envelope, shatter }

enum _Stage { writing, animating, done }

/// "Отпустить" — написать тяжёлую мысль/воспоминание и символически
/// уничтожить её (сжечь или разбить). Текст НИКУДА не сохраняется и
/// никуда не отправляется — ни на сервер, ни в локальное хранилище: сам
/// смысл упражнения в том, чтобы отпустить, а не архивировать.
class MemoryReleaseScreen extends StatefulWidget {
  final AuthStore? authStore;
  const MemoryReleaseScreen({super.key, this.authStore});

  @override
  State<MemoryReleaseScreen> createState() => _MemoryReleaseScreenState();
}

class _MemoryReleaseScreenState extends State<MemoryReleaseScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _soundsService = SoundsService();
  final _effectPlayer = AudioPlayer();
  _ReleaseMode _mode = _ReleaseMode.envelope;
  _Stage _stage = _Stage.writing;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _stage = _Stage.done);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    _soundsService.dispose();
    _effectPlayer.dispose();
    super.dispose();
  }

  // необязательное озвучивание эффекта - если админ не загрузил звук
  // категории "release" (или что-то пошло не так с сетью), анимация всё
  // равно проигрывается молча, это не должно ломать основной сценарий
  Future<void> _playReleaseSoundIfAvailable() async {
    final authStore = widget.authStore;
    final token = authStore?.token;
    if (token == null) return;
    try {
      final sounds = await _soundsService.list(
        baseUrl: authStore!.baseUrl,
        token: token,
        category: SoundCategory.release,
      );
      if (sounds.isEmpty) return;
      final bytes = await _soundsService.fetchAudioBytes(
        baseUrl: authStore.baseUrl,
        token: token,
        soundId: sounds.first.id,
      );
      await _effectPlayer.play(BytesSource(bytes));
    } catch (_) {
      // тихо игнорируем - звук необязателен для самого упражнения
    }
  }

  void _startRelease() {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _stage = _Stage.animating);
    _animController.forward(from: 0);
    _playReleaseSoundIfAvailable();
  }

  void _reset() {
    setState(() {
      _controller.clear();
      _stage = _Stage.writing;
    });
    _animController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                      icon: Icon(
                        Icons.adaptive.arrow_back,
                        color: context.onSurface,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      l10n.wellbeingReleaseTitle,
                      style: TextStyle(
                        color: context.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
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
                      child: switch (_stage) {
                        _Stage.writing => _buildWriting(),
                        _Stage.animating => _buildAnimating(),
                        _Stage.done => _buildDone(),
                      },
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

  Widget _buildWriting() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassPanel(
          opacity: 0.07,
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(14),
          child: Text(
            l10n.memoryReleaseIntro,
            style: TextStyle(
              color: context.onSurfaceFaded(0.6),
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          minLines: 5,
          maxLines: 10,
          style: TextStyle(
            color: context.onSurface,
            fontSize: 14.5,
            height: 1.5,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.onSurfaceFaded(0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
            hintText: l10n.memoryReleaseHint,
            hintStyle: TextStyle(color: context.onSurfaceFaded(0.3)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _modeChip(
                _ReleaseMode.envelope,
                Icons.mail_outline_rounded,
                l10n.memoryReleaseEnvelopeMode,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _modeChip(
                _ReleaseMode.shatter,
                Icons.blur_on_rounded,
                l10n.memoryReleaseShatterMode,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _startRelease,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: _mode == _ReleaseMode.envelope
                      ? [const Color(0xFF8E7CF0), const Color(0xFF6C5CE7)]
                      : [const Color(0xFF6C5CE7), const Color(0xFF00B4D8)],
                ),
              ),
              child: Text(
                _mode == _ReleaseMode.envelope
                    ? l10n.memoryReleaseEnvelopeMode
                    : l10n.memoryReleaseShatterMode,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _modeChip(_ReleaseMode mode, IconData icon, String label) {
    final selected = _mode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _mode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected
                ? context.onSurfaceFaded(0.12)
                : context.onSurfaceFaded(0.04),
            border: Border.all(
              color: selected
                  ? context.onSurfaceFaded(0.4)
                  : context.onSurfaceFaded(0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: context.onSurfaceFaded(selected ? 0.9 : 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: context.onSurfaceFaded(selected ? 0.9 : 0.5),
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimating() {
    return SizedBox(
      height: 420,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return _mode == _ReleaseMode.envelope
              ? _EnvelopeSliceEffect(
                  progress: _animController.value,
                  text: _controller.text,
                )
              : _ShatterEffect(
                  progress: _animController.value,
                  text: _controller.text,
                );
        },
      ),
    );
  }

  Widget _buildDone() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _mode == _ReleaseMode.envelope
              ? Icons.mail_outline_rounded
              : Icons.check_circle_outline_rounded,
          color: context.onSurfaceFaded(0.5),
          size: 40,
        ),
        const SizedBox(height: 16),
        Text(
          _mode == _ReleaseMode.envelope
              ? l10n.memoryReleaseEnvelopeResult
              : l10n.memoryReleaseShatteredResult,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.onSurfaceFaded(0.7), fontSize: 14.5),
        ),
        const SizedBox(height: 24),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _reset,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.onSurfaceFaded(0.2)),
              ),
              child: Text(
                l10n.memoryReleaseWriteMoreButton,
                style: TextStyle(
                  color: context.onSurfaceFaded(0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Раньше здесь было "сжигание" - убрано по просьбе, заменено на
/// другую метафору: написанный текст сворачивается в конверт (письмо
/// "запечатывается"), а затем конверт разрезается по диагонали одним
/// движением - как во Fruit Ninja (быстрый свайп, объект распадается
/// на куски вдоль линии разреза, а не просто исчезает).
class _EnvelopeSliceEffect extends StatelessWidget {
  final double progress;
  final String text;
  const _EnvelopeSliceEffect({required this.progress, required this.text});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 420),
      painter: _EnvelopeSlicePainter(progress: progress, text: text),
    );
  }
}

/// Три фазы по прогрессу 0..1:
/// 0.00-0.40 - письмо (лист с текстом) уменьшается и уезжает вниз, в
///             конверт; треугольный клапан конверта опускается следом
/// 0.40-0.55 - лезвие пролетает по диагонали через закрытый конверт
///             (быстро, как настоящий свайп, а не медленное движение)
/// 0.55-1.00 - конверт распадается на две половины по той же диагонали,
///             каждая улетает в свою сторону с вращением и ускорением
///             вниз (имитация гравитации)
class _EnvelopeSlicePainter extends CustomPainter {
  final double progress;
  final String text;
  _EnvelopeSlicePainter({required this.progress, required this.text});

  @override
  void paint(Canvas canvas, Size size) {
    final envelopeCenter = Offset(size.width / 2, size.height * 0.62);
    const envelopeWidth = 200.0;
    const envelopeHeight = 130.0;
    final envelopeRect = Rect.fromCenter(
      center: envelopeCenter,
      width: envelopeWidth,
      height: envelopeHeight,
    );

    // фаза 1 - письмо едет в конверт
    final letterPhase = (progress / 0.4).clamp(0.0, 1.0);
    if (letterPhase < 1.0) {
      final letterScale = 1.0 - letterPhase * 0.82;
      final letterY =
          size.height * 0.22 +
          (envelopeCenter.dy - size.height * 0.22) * letterPhase;
      final letterOpacity =
          1.0 - (letterPhase > 0.7 ? (letterPhase - 0.7) / 0.3 : 0.0);

      canvas.save();
      canvas.translate(size.width / 2, letterY);
      canvas.scale(letterScale);
      final letterRect = Rect.fromCenter(
        center: Offset.zero,
        width: 220,
        height: 280,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(letterRect, const Radius.circular(6)),
        Paint()..color = const Color(0xFFF3E5C8).withValues(alpha: letterOpacity),
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: const Color(0xFF3B2A1A).withValues(alpha: letterOpacity),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        textAlign: TextAlign.center,
        maxLines: 12,
        ellipsis: '…',
      )..layout(maxWidth: letterRect.width - 24);
      textPainter.paint(
        canvas,
        Offset(-letterRect.width / 2 + 12, -letterRect.height / 2 + 12),
      );
      canvas.restore();
    }

    // конверт - тело + треугольный клапан, клапан опускается в течение
    // всей фазы 1 (не мгновенно), выглядит как настоящее запечатывание
    final flapPhase = letterPhase; // 0 = открыт, 1 = закрыт
    void drawEnvelopeBody(Canvas c, Rect rect) {
      c.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = const Color(0xFFE8E2F5),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()
          ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      // клапан - треугольник от верхних углов к точке, опускающейся к центру
      final flapTip = Offset(
        rect.center.dx,
        rect.top + rect.height * 0.5 * flapPhase,
      );
      final flapPath = Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(flapTip.dx, flapTip.dy)
        ..close();
      c.drawPath(flapPath, Paint()..color = const Color(0xFFD8CFF0));
      c.drawPath(
        flapPath,
        Paint()
          ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    if (progress < 0.55) {
      drawEnvelopeBody(canvas, envelopeRect);
    }

    // фаза 2 - лезвие. Быстрый диагональный свайв слева-сверху направо-вниз,
    // проходит через весь экран (не только через конверт) - так заметнее
    // сам жест разреза, не только его результат
    final slicePhase = ((progress - 0.4) / 0.15).clamp(0.0, 1.0);
    if (slicePhase > 0 && slicePhase < 1) {
      final t = slicePhase;
      final bladeStart = Offset(
        -40 + size.width * 0.5 * t,
        -40 + size.height * 0.4 * t,
      );
      final bladeEnd =
          bladeStart + Offset(size.width * 0.5, size.height * 0.35);
      canvas.drawLine(
        bladeStart,
        bladeEnd,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      // лёгкое свечение вдоль лезвия
      canvas.drawLine(
        bladeStart,
        bladeEnd,
        Paint()
          ..color = const Color(0xFF00D9C0).withValues(alpha: 0.5)
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }

    // фаза 3 - конверт разрезан по диагонали (левый верх -> правый низ
    // самого конверта) на два треугольника, каждый улетает в свою
    // сторону с вращением и ускорением вниз
    final shatterPhase = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
    if (shatterPhase > 0) {
      final diag1 = envelopeRect.topLeft;
      final diag2 = envelopeRect.bottomRight;

      void drawHalf(Path clipPath, Offset direction, double rotationSign) {
        canvas.save();
        // ускорение вниз (гравитация) - квадратичный рост смещения по Y
        final dx = direction.dx * 220 * shatterPhase;
        final dy =
            direction.dy * 140 * shatterPhase +
            260 * shatterPhase * shatterPhase;
        canvas.translate(dx, dy);
        canvas.translate(envelopeCenter.dx, envelopeCenter.dy);
        canvas.rotate(rotationSign * shatterPhase * 2.4);
        canvas.translate(-envelopeCenter.dx, -envelopeCenter.dy);
        canvas.clipPath(clipPath);
        drawEnvelopeBody(canvas, envelopeRect);
        canvas.restore();
      }

      final upperRightPath = Path()
        ..moveTo(diag1.dx, diag1.dy)
        ..lineTo(envelopeRect.right, envelopeRect.top)
        ..lineTo(diag2.dx, diag2.dy)
        ..close();
      final lowerLeftPath = Path()
        ..moveTo(diag1.dx, diag1.dy)
        ..lineTo(envelopeRect.left, envelopeRect.bottom)
        ..lineTo(diag2.dx, diag2.dy)
        ..close();

      final fade = (1 - shatterPhase).clamp(0.0, 1.0);
      canvas.saveLayer(
        Rect.largest,
        Paint()..color = Colors.black.withValues(alpha: fade),
      );
      drawHalf(upperRightPath, const Offset(1, -0.6), 1);
      drawHalf(lowerLeftPath, const Offset(-1, 0.4), -1);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _EnvelopeSlicePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ShatterEffect extends StatelessWidget {
  final double progress;
  final String text;
  const _ShatterEffect({required this.progress, required this.text});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 420),
      painter: _ShatterPainter(
        progress: progress,
        text: text,
        baseColor: context.onSurface,
      ),
    );
  }
}

class _ShatterPainter extends CustomPainter {
  final double progress;
  final String text;
  final Color baseColor;
  final math.Random _rnd;
  _ShatterPainter({
    required this.progress,
    required this.text,
    required this.baseColor,
  }) : _rnd = math.Random(text.hashCode);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 20);
    const plateRadius = 130.0;

    // до 30% - тарелка цела; трещины начинают проступать в последней
    // трети этой фазы, ещё до самого разлёта - даёт ощущение нарастания,
    // а не мгновенного "было целое - стало на куски"
    final crackPhase = ((progress - 0.18) / 0.12).clamp(0.0, 1.0);
    final shatterProgress = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);

    if (progress < 0.3) {
      // настоящая тарелка - обод и внутренняя часть двумя концентрическими
      // кругами, а не один плоский круг с тонкой обводкой, как раньше
      canvas.drawCircle(
        center,
        plateRadius,
        Paint()..color = baseColor.withValues(alpha: 0.16),
      );
      canvas.drawCircle(
        center,
        plateRadius * 0.78,
        Paint()..color = baseColor.withValues(alpha: 0.08),
      );
      canvas.drawCircle(
        center,
        plateRadius,
        Paint()
          ..color = baseColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawCircle(
        center,
        plateRadius * 0.78,
        Paint()
          ..color = baseColor.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: baseColor.withValues(alpha: 0.85),
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
        textAlign: TextAlign.center,
        maxLines: 6,
        ellipsis: '…',
      )..layout(maxWidth: plateRadius * 1.4);
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );

      // трещины - зерно смещено от _rnd (text.hashCode), чтобы не совпадать
      // один в один с последовательностью, которую использует разлёт
      // осколков ниже
      if (crackPhase > 0) {
        final crackRnd = math.Random(text.hashCode + 500);
        const crackCount = 6;
        for (var i = 0; i < crackCount; i++) {
          var angle = crackRnd.nextDouble() * 2 * math.pi;
          var x = center.dx;
          var y = center.dy;
          final path = Path()..moveTo(x, y);
          const segments = 4;
          for (var s = 0; s < segments; s++) {
            final segLen = (plateRadius / segments) * crackPhase;
            angle += (crackRnd.nextDouble() - 0.5) * 0.7;
            x += math.cos(angle) * segLen;
            y += math.sin(angle) * segLen;
            path.lineTo(x, y);
          }
          canvas.drawPath(
            path,
            Paint()
              ..color = baseColor.withValues(alpha: 0.55 * crackPhase)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4,
          );
        }
      }
    }

    if (progress >= 0.3) {
      // пылевой всплеск ровно в момент разлёта - без него переход от
      // "целое" к "куски летят" выглядел слишком резко
      if (shatterProgress < 0.15) {
        final dustFade = 1 - shatterProgress / 0.15;
        final dustRnd = math.Random(text.hashCode + 900);
        for (var i = 0; i < 20; i++) {
          final a = dustRnd.nextDouble() * 2 * math.pi;
          final r = dustRnd.nextDouble() * 40 * (shatterProgress / 0.15);
          canvas.drawCircle(
            center + Offset(math.cos(a) * r, math.sin(a) * r),
            1.5,
            Paint()..color = baseColor.withValues(alpha: 0.35 * dustFade),
          );
        }
      }

      const shardCount = 16;
      for (var i = 0; i < shardCount; i++) {
        final angle = (i / shardCount) * 2 * math.pi + _rnd.nextDouble() * 0.3;
        final speed = 140 + _rnd.nextDouble() * 120;
        final dx = math.cos(angle) * speed * shatterProgress;
        final dy =
            math.sin(angle) * speed * shatterProgress -
            80 * shatterProgress * (1 - shatterProgress);
        final rotation = angle * 3 * shatterProgress;
        final fade = (1 - shatterProgress).clamp(0.0, 1.0);

        canvas.save();
        canvas.translate(center.dx + dx, center.dy + dy);
        canvas.rotate(rotation);

        // неправильный четырёхугольник вместо ровного треугольника -
        // больше похоже на реальный обломок керамики, не на геометрическую
        // фигуру
        final baseSize = 12.0 + _rnd.nextDouble() * 12;
        final shardPath = Path()
          ..moveTo(
            -baseSize * 0.4 + _rnd.nextDouble() * 4,
            -baseSize + _rnd.nextDouble() * 4,
          )
          ..lineTo(
            baseSize * 0.6 + _rnd.nextDouble() * 4,
            -baseSize * 0.3 + _rnd.nextDouble() * 4,
          )
          ..lineTo(
            baseSize * 0.3 + _rnd.nextDouble() * 4,
            baseSize * 0.6 + _rnd.nextDouble() * 4,
          )
          ..lineTo(
            -baseSize * 0.5 + _rnd.nextDouble() * 4,
            baseSize * 0.2 + _rnd.nextDouble() * 4,
          )
          ..close();
        canvas.drawPath(
          shardPath,
          Paint()..color = baseColor.withValues(alpha: fade * 0.55),
        );
        // тонкая светлая грань по контуру - ощущение объёма у обломка
        canvas.drawPath(
          shardPath,
          Paint()
            ..color = baseColor.withValues(alpha: fade * 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ShatterPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
