import 'package:flutter/material.dart';

import '../state/voice_store.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';
import 'breathing_exercise_screen.dart';
import 'gratitude_journal_screen.dart';
import 'grounding_exercise_screen.dart';

/// Быстрые подсказки под конкретную ситуацию — часть маршрутизирует к уже
/// сделанным безопасным инструментам (дыхание, заземление, дневник
/// благодарности), часть — под темы, для которых готового инструмента
/// нет (развод, утрата, потеря работы) — напрямую открывает разговор с
/// ИИ с честной, неприсваивающей чужих деталей опорной фразой. Никакого
/// нового психологического контента здесь не пишем — либо готовый
/// инструмент, либо просто начало разговора с ИИ.
class SituationalHelpScreen extends StatelessWidget {
  final String userId;
  final VoiceStore? voiceStore;
  // null — тема без прямого разговора с ИИ (плитки к инструментам ниже).
  // Если задан вызывающим экраном — плитки "поговорить с ИИ" появляются
  // тоже: создаёт новый чат, сразу отправляет опорную фразу, возвращает
  // на экран чата. Опционально — если вызывающий код не прокинул этот
  // колбэк (например, более старая версия навигации где-то ещё), эти
  // три плитки просто не показываются, ничего не ломается.
  final Future<void> Function(String text)? onStartAiConversation;
  const SituationalHelpScreen({super.key, required this.userId, this.voiceStore, this.onStartAiConversation});

  @override
  Widget build(BuildContext context) {
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
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Ситуативная помощь',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Выбери, что сейчас ближе всего — предложу то, что может помочь.',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12.5, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          _SituationTile(
                            icon: Icons.bolt_rounded,
                            title: 'Тревога или паника прямо сейчас',
                            subtitle: 'Переключить внимание на органы чувств',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => GroundingExerciseScreen(voiceStore: voiceStore)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SituationTile(
                            icon: Icons.air_rounded,
                            title: 'Не могу успокоиться, нервы на пределе',
                            subtitle: 'Дыхательное упражнение — 4 фазы по 4 секунды',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const BreathingExerciseScreen()),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SituationTile(
                            icon: Icons.bedtime_rounded,
                            title: 'Трудно заснуть, мысли не отпускают',
                            subtitle: 'То же дыхательное упражнение помогает и перед сном',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const BreathingExerciseScreen()),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SituationTile(
                            icon: Icons.wb_cloudy_rounded,
                            title: 'Плохое настроение, всё валится из рук',
                            subtitle: 'Дневник благодарности — вспомнить несколько хороших мелочей',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => GratitudeJournalScreen(userId: userId)),
                            ),
                          ),
                          if (onStartAiConversation != null) ...[
                            const SizedBox(height: 20),
                            Text(
                              'ПОГОВОРИТЬ С ИИ',
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Для этих тем готового упражнения нет — сразу начнём разговор.',
                              style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11.5),
                            ),
                            const SizedBox(height: 10),
                            _SituationTile(
                              icon: Icons.heart_broken_outlined,
                              title: 'Развод или разрыв отношений',
                              subtitle: 'Начать разговор с ИИ об этом',
                              onTap: () => onStartAiConversation!(
                                'У меня сейчас развод или расставание, и мне тяжело с этим '
                                'справляться. Можешь поддержать меня в разговоре об этом?',
                              ),
                            ),
                            const SizedBox(height: 10),
                            _SituationTile(
                              icon: Icons.spa_outlined,
                              title: 'Тяжёлая утрата',
                              subtitle: 'Начать разговор с ИИ об этом',
                              onTap: () => onStartAiConversation!(
                                'У меня недавно случилась тяжёлая утрата близкого человека, '
                                'и мне хочется с кем-то об этом поговорить.',
                              ),
                            ),
                            const SizedBox(height: 10),
                            _SituationTile(
                              icon: Icons.work_off_outlined,
                              title: 'Потеря работы или крупные перемены',
                              subtitle: 'Начать разговор с ИИ об этом',
                              onTap: () => onStartAiConversation!(
                                'У меня сейчас сложный период — потеряна работа или '
                                'произошла резкая перемена в жизни, и это тяжело '
                                'переживать. Можешь поддержать меня в разговоре об этом?',
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          GlassPanel(
                            opacity: 0.06,
                            borderRadius: BorderRadius.circular(14),
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              'Это подсказки для самопомощи, не диагностика и не замена '
                              'специалиста. Если ситуация серьёзная или не отпускает — '
                              'обратись к близким или к специалисту напрямую.',
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11.5, height: 1.4),
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

class _SituationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SituationTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      opacity: 0.08,
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF6FB1DE), Color(0xFF4DD0C4)]),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

