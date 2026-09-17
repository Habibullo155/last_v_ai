import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ai_last_v/l10n/app_localizations.dart';
import '../theme/app_text_color.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

/// Билатеральная стимуляция (элементы EMDR/ДПДГ) - шар плавно движется
/// слева направо и обратно, взгляд следует за ним без поворота головы.
/// Не заменяет настоящую сессию ДПДГ со специалистом - это упрощённый,
/// самостоятельный вариант техники слежения глазами.
class BilateralStimulationScreen extends StatefulWidget {
  const BilateralStimulationScreen({super.key});

  @override
  State<BilateralStimulationScreen> createState() =>
      _BilateralStimulationScreenState();
}

class _BilateralStimulationScreenState extends State<BilateralStimulationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isRunning = false;
  int _selectedMinutes = 1;
  // near_left/near_right пересекаются на стыке циклов (0.98..1.0 одного
  // цикла продолжается в 0..0.02 следующего) - простой булев флаг \"рядом
  // ли с любым краем сейчас\" даёт ровно одно срабатывание на каждый
  // разворот, без отдельного отслеживания \"какой именно край\"
  bool _wasAtEdge = false;

  // Полный цикл движения шара, в секундах: сначала два полных прохода
  // слева направо и обратно (по просьбе - "2 раза с одного края в
  // другой"), затем облёт по всем четырём углам области, и цикл
  // повторяется заново. Горизонтальная фаза - основная, для слежения
  // взглядом без поворота головы; угловая - разнообразит траекторию,
  // задействуя периферийное зрение и лёгкое движение головой тоже.
  static const double _horizontalPhaseSeconds =
      16; // 4 однонаправленных прохода по 4с
  static const double _cornersPhaseSeconds = 8; // 4 отрезка между углами по 2с
  static const double _totalCycleSeconds =
      _horizontalPhaseSeconds + _cornersPhaseSeconds;
  static const double _horizontalPhaseFraction =
      _horizontalPhaseSeconds / _totalCycleSeconds;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalCycleSeconds.round()),
    )..addListener(_checkEdge);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Треугольная волна периода 1: 0→1→0, для x в любом диапазоне (берёт
  /// дробную часть сам).
  static double _triangleWave(double x) {
    final frac = x - x.floorToDouble();
    return frac < 0.5 ? frac * 2 : 2 - frac * 2;
  }

  /// Позиция шара как доля (dx, dy) от 0 до 1 внутри доступной области -
  /// умножается на реальные ширину/высоту в build(). (0,0) - левый верх,
  /// (1,1) - правый низ.
  (double, double) _ballFraction(double t) {
    if (t < _horizontalPhaseFraction) {
      // горизонтальная фаза - 2 полных прохода (частота 2) по центру
      // вертикали, движение только по X
      final hp = t / _horizontalPhaseFraction;
      return (_triangleWave(hp * 2), 0.5);
    }
    // угловая фаза - облёт по периметру: верх-лево -> верх-право ->
    // низ-право -> низ-лево -> обратно к верх-лево (следующий цикл
    // начнётся снова с горизонтальной фазы оттуда же)
    const corners = [
      (0.0, 0.0),
      (1.0, 0.0),
      (1.0, 1.0),
      (0.0, 1.0),
      (0.0, 0.0),
    ];
    final ap =
        (t - _horizontalPhaseFraction) /
        (1 - _horizontalPhaseFraction); // 0..1 внутри угловой фазы
    final segmentFloat = ap * 4;
    final segmentIndex = segmentFloat.floor().clamp(0, 3);
    final segmentT = segmentFloat - segmentIndex;
    final from = corners[segmentIndex];
    final to = corners[segmentIndex + 1];
    return (
      from.$1 + (to.$1 - from.$1) * segmentT,
      from.$2 + (to.$2 - from.$2) * segmentT,
    );
  }

  void _checkEdge() {
    final t = _controller.value;
    // "у края" теперь означает и горизонтальные развороты, и прибытие в
    // любой из четырёх углов - везде, где шар меняет направление
    final (dx, dy) = _ballFraction(t);
    final nearHorizontalEdge = dx < 0.03 || dx > 0.97;
    final nearVerticalEdge = dy < 0.03 || dy > 0.97;
    final nearAnyEdge =
        nearHorizontalEdge && nearVerticalEdge ||
        (t < _horizontalPhaseFraction && nearHorizontalEdge);
    if (nearAnyEdge && !_wasAtEdge) {
      HapticFeedback.lightImpact();
    }
    _wasAtEdge = nearAnyEdge;
  }

  void _start() {
    setState(() => _isRunning = true);
    _controller.repeat();
    Future.delayed(Duration(minutes: _selectedMinutes), () {
      if (mounted && _isRunning) _stop();
    });
  }

  void _stop() {
    _controller.stop();
    setState(() => _isRunning = false);
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
                      l10n.bilateralTitle,
                      style: TextStyle(
                        color: context.onSurface,
                        fontSize: 16,
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
                      child: Column(
                        children: [
                          if (!_isRunning) ...[
                            GlassPanel(
                              opacity: 0.07,
                              borderRadius: BorderRadius.circular(16),
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                l10n.bilateralIntro,
                                style: TextStyle(
                                  color: context.onSurfaceFaded(0.6),
                                  fontSize: 12.5,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.freewritingHowManyMinutes,
                              style: TextStyle(
                                color: context.onSurfaceFaded(0.5),
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [1, 2, 3].map((m) {
                                final selected = _selectedMinutes == m;
                                return ChoiceChip(
                                  label: Text(l10n.freewritingMinutesOption(m)),
                                  selected: selected,
                                  onSelected: (_) =>
                                      setState(() => _selectedMinutes = m),
                                  labelStyle: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : context.onSurfaceFaded(0.7),
                                  ),
                                  selectedColor: const Color(0xFF6C5CE7),
                                  backgroundColor: context.onSurfaceFaded(0.06),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                          ] else
                            SizedBox(
                              height: 340,
                              child: AnimatedBuilder(
                                animation: _controller,
                                builder: (context, _) {
                                  final (dx, dy) = _ballFraction(
                                    _controller.value,
                                  );
                                  return LayoutBuilder(
                                    builder: (context, constraints) {
                                      const ballSize = 56.0;
                                      const margin = 40.0;
                                      final width =
                                          constraints.maxWidth -
                                          margin * 2 -
                                          ballSize;
                                      final height =
                                          constraints.maxHeight -
                                          margin * 2 -
                                          ballSize;
                                      return Stack(
                                        children: [
                                          Positioned(
                                            top: margin + height * dy,
                                            left: margin + width * dx,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                // мягкое внешнее свечение позади самого шара -
                                                // крупнее и прозрачнее, даёт красивый ореол,
                                                // не отвлекая от самого шара как фокуса взгляда
                                                Container(
                                                  width: ballSize * 1.7,
                                                  height: ballSize * 1.7,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: RadialGradient(
                                                      colors: [
                                                        const Color(
                                                          0xFF6C5CE7,
                                                        ).withValues(alpha: 0.35),
                                                        Colors.transparent,
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  width: ballSize,
                                                  height: ballSize,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient:
                                                        const LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            Color(0xFF8E7CF0),
                                                            Color(0xFF6C5CE7),
                                                            Color(0xFF00D9C0),
                                                          ],
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(
                                                          0xFF6C5CE7,
                                                        ).withValues(alpha: 0.6),
                                                        blurRadius: 24,
                                                        spreadRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // тонкий светлый блик сверху-слева - придаёт
                                                // объём, а не плоский однотонный круг
                                                Positioned(
                                                  top: ballSize * 0.18,
                                                  left: ballSize * 0.18,
                                                  child: Container(
                                                    width: ballSize * 0.28,
                                                    height: ballSize * 0.28,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.white
                                                          .withValues(alpha: 0.45),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _isRunning ? _stop : _start,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(
                                    colors: _isRunning
                                        ? [
                                            context.onSurfaceFaded(0.2),
                                            context.onSurfaceFaded(0.1),
                                          ]
                                        : [
                                            const Color(0xFF6C5CE7),
                                            const Color(0xFF00B4D8),
                                          ],
                                  ),
                                ),
                                child: Text(
                                  _isRunning
                                      ? l10n.breathingStopButton
                                      : l10n.muscleStartButton,
                                  style: TextStyle(
                                    color: _isRunning
                                        ? context.onSurface
                                        : Colors.white,
                                    fontWeight: FontWeight.w600,
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
}
