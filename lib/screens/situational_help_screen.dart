import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/voice_store.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';
import 'breathing_exercise_screen.dart';
import 'gratitude_journal_screen.dart';
import 'grounding_exercise_screen.dart';

/// Быстрые подсказки под конкретную ситуацию — не новый контент, а
/// маршрутизация к уже сделанным безопасным инструментам (дыхание,
/// заземление, дневник благодарности) плюс готовые фразы для начала
/// разговора с ИИ. Никакого нового психологического контента здесь нет —
/// сознательно, по тем же причинам, что и раньше в этом проекте.
class SituationalHelpScreen extends StatelessWidget {
  final String userId;
  final VoiceStore? voiceStore;
  const SituationalHelpScreen({super.key, required this.userId, this.voiceStore});

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
                          const SizedBox(height: 24),
                          Text(
                            'ХОЧЕТСЯ ПРОСТО ПОГОВОРИТЬ',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Скопируй любую фразу и вставь в чат — иногда сложнее всего начать.',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          ..._starterPrompts.map((p) => _PromptTile(text: p)),
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

  static const _starterPrompts = [
    'Мне сейчас непросто, и я хочу об этом поговорить.',
    'День выдался тяжёлым — можешь просто меня выслушать?',
    'Не знаю, с чего начать, но хочу выговориться.',
  ];
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

class _PromptTile extends StatelessWidget {
  final String text;
  const _PromptTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassPanel(
        opacity: 0.06,
        blurred: false, // список из нескольких фраз — см. message_bubble.dart
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text('«$text»', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.3)),
            ),
            IconButton(
              icon: Icon(Icons.copy_rounded, size: 16, color: Colors.white.withOpacity(0.5)),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Скопировано'), duration: Duration(seconds: 1)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
