import 'package:flutter/material.dart';

import 'package:LOMALU/l10n/app_localizations.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

enum _Phase { inhale, holdFull, exhale, holdEmpty }

// функция, а не константная карта - l10n.of(context) требует
// BuildContext, недоступный на уровне файла/константы
Map<_Phase, String> _phaseLabels(AppLocalizations l10n) => {
  _Phase.inhale: l10n.breathingInhale,
  _Phase.holdFull: l10n.breathingHold,
  _Phase.exhale: l10n.breathingExhale,
  _Phase.holdEmpty: l10n.breathingHold,
};

/// "Квадратное" дыхание (box breathing) — 4 секунды на каждую фазу.
/// Простая, широко известная техника саморегуляции (используется в том
/// числе в спорте и медицине как вспомогательный приём) — не заменяет
/// профессиональную помощь, просто способ ненадолго успокоить дыхание.
class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isRunning = false;
  _Phase _phase = _Phase.inhale;
  static const _phaseDuration = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _phaseDuration)
      ..addStatusListener(_onStatusChanged);
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() => _phase = _nextPhase(_phase));
      _controller
        ..reset()
        ..forward();
    }
  }

  _Phase _nextPhase(_Phase phase) {
    switch (phase) {
      case _Phase.inhale:
        return _Phase.holdFull;
      case _Phase.holdFull:
        return _Phase.exhale;
      case _Phase.exhale:
        return _Phase.holdEmpty;
      case _Phase.holdEmpty:
        return _Phase.inhale;
    }
  }

  void _toggle() {
    setState(() => _isRunning = !_isRunning);
    if (_isRunning) {
      _phase = _Phase.inhale;
      _controller
        ..reset()
        ..forward();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _circleScale() {
    final t = _controller.value;
    switch (_phase) {
      case _Phase.inhale:
        return 0.55 + 0.45 * t;
      case _Phase.holdFull:
        return 1.0;
      case _Phase.exhale:
        return 1.0 - 0.45 * t;
      case _Phase.holdEmpty:
        return 0.55;
    }
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
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      l10n.breathingTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final scale = _isRunning ? _circleScale() : 0.55;
                          return Container(
                            width: 220 * scale,
                            height: 220 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6FB1DE), Color(0xFF4DD0C4)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4DD0C4,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 40,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _isRunning
                            ? _phaseLabels(l10n)[_phase]!
                            : l10n.breathingReadyToStart,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: _toggle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C5CE7), Color(0xFF00B4D8)],
                              ),
                            ),
                            child: Text(
                              _isRunning
                                  ? l10n.breathingStopButton
                                  : l10n.muscleStartButton,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: GlassPanel(
                  opacity: 0.07,
                  borderRadius: BorderRadius.circular(14),
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    l10n.breathingDisclaimer,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11.5,
                      height: 1.4,
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
