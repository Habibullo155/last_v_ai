import 'package:flutter/material.dart';

import '../services/onboarding_survey_service.dart';
import '../state/auth_store.dart';
import '../theme/app_text_color.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

/// Показывается один раз, СРАЗУ после завершения опросника - анонимная,
/// агрегированная статистика ("сколько людей выбрали тот же вариант,
/// что и ты"). НЕ персональный вывод о состоянии - см. подробное
/// обоснование в backend/routers_onboarding.py. Если статистику не
/// удалось загрузить (сеть, пустая выборка) - не блокируем вход в
/// приложение, просто сразу продолжаем без этого экрана.
class OnboardingStatsScreen extends StatefulWidget {
  final AuthStore authStore;
  final VoidCallback onDone;
  const OnboardingStatsScreen({super.key, required this.authStore, required this.onDone});

  @override
  State<OnboardingStatsScreen> createState() => _OnboardingStatsScreenState();
}

class _OnboardingStatsScreenState extends State<OnboardingStatsScreen> {
  final _service = OnboardingSurveyService();
  List<OnboardingSurveyStat>? _stats;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = widget.authStore.token;
    if (token == null) {
      widget.onDone();
      return;
    }
    try {
      final stats = await _service.getStats(baseUrl: widget.authStore.baseUrl, token: token);
      if (!mounted) return;
      if (stats.isEmpty) {
        // нечего показывать (например, ты первый, кто вообще прошёл
        // опросник) - не показываем пустой экран, сразу продолжаем
        widget.onDone();
        return;
      }
      setState(() => _stats = stats);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      // сбой сети - не задерживаем человека на пустом экране статистики
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      return const SizedBox.shrink();
    }
    final stats = _stats;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: stats == null
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'Ты не один(а)',
                        style: TextStyle(color: context.onSurface, fontSize: 26, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Вот как твои ответы соотносятся с другими людьми — анонимно, без привязки к личности.',
                        style: TextStyle(color: context.onSurfaceFaded(0.6), fontSize: 14),
                      ),
                      const SizedBox(height: 28),
                      Expanded(
                        child: ListView.separated(
                          itemCount: stats.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 14),
                          itemBuilder: (context, i) => _StatCard(stat: stats[i]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: widget.onDone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C5CE7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Продолжить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

class _StatCard extends StatelessWidget {
  final OnboardingSurveyStat stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final fraction = (stat.matchingPercentage / 100).clamp(0.0, 1.0);
    return GlassPanel(
      opacity: 0.08,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.question,
            style: TextStyle(color: context.onSurfaceFaded(0.75), fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            'Твой ответ: ${stat.myAnswer}',
            style: TextStyle(color: context.onSurface, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: context.onSurfaceFaded(0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00D9C0)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stat.matchingPercentage.toStringAsFixed(0)}% людей выбрали тот же вариант',
            style: TextStyle(color: context.onSurfaceFaded(0.6), fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
