import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/wellbeing_checkin.dart';
import '../services/wellbeing_service.dart';
import '../state/voice_store.dart';
import '../widgets/app_background.dart';
import '../widgets/crisis_resources_panel.dart';
import '../widgets/glass_panel.dart';
import 'breathing_exercise_screen.dart';
import 'gad7_screen.dart';
import 'gratitude_journal_screen.dart';
import 'grounding_exercise_screen.dart';
import 'phq9_screen.dart';
import 'situational_help_screen.dart';

const _uuid = Uuid();

/// Пять официальных утверждений ВОЗ-5 (World Health Organization-Five
/// Well-Being Index), русский перевод — официальный, с сайта who.int/ru
/// (Psychiatric Research Unit, WHO Collaborating Centre in Mental Health).
const List<String> _who5Statements = [
  'Я чувствую себя бодрой(-ым) и в хорошем настроении',
  'Я чувствую себя спокойной(-ым) и раскованной(-ым)',
  'Я чувствую себя активной(-ым) и энергичной(-ым)',
  'Я просыпаюсь и чувствую себя свежей(-им) и отдохнувшей(-им)',
  'Каждый день со мной происходят вещи, представляющие для меня интерес',
];

const List<String> _who5Options = [
  'Всё время',
  'Большую часть времени',
  'Более половины времени',
  'Менее половины времени',
  'Некоторое время',
  'Никогда',
];

enum _Mode { history, testing, result }

class WellbeingScreen extends StatefulWidget {
  final String userId;
  final VoiceStore? voiceStore;
  const WellbeingScreen({super.key, required this.userId, this.voiceStore});

  @override
  State<WellbeingScreen> createState() => _WellbeingScreenState();
}

class _WellbeingScreenState extends State<WellbeingScreen> {
  final _service = WellbeingService();
  List<WellbeingCheckin> _history = [];
  bool _isLoading = true;
  String? _error;

  _Mode _mode = _Mode.history;
  final List<int?> _currentAnswers = List<int?>.filled(5, null);
  WellbeingCheckin? _lastResult;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final items = await _service.loadCheckins(widget.userId);
    if (!mounted) return;
    setState(() {
      _history = items;
      _isLoading = false;
    });
  }

  void _startTest() {
    setState(() {
      _mode = _Mode.testing;
      _currentAnswers.fillRange(0, 5, null);
      _error = null;
    });
  }

  Future<void> _submitTest() async {
    if (_currentAnswers.any((a) => a == null)) return;
    final checkin = WellbeingCheckin(
      id: _uuid.v4(),
      date: DateTime.now(),
      answers: _currentAnswers.cast<int>(),
    );
    final saved = await _service.addCheckin(widget.userId, checkin);
    if (!mounted) return;
    if (saved == null) {
      setState(() => _error = 'Не удалось сохранить результат локально. Можно пройти ещё раз.');
      return;
    }
    setState(() {
      _history = [saved, ..._history];
      _lastResult = saved;
      _mode = _Mode.result;
    });
  }

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
                      onPressed: () {
                        if (_mode != _Mode.history) {
                          setState(() => _mode = _Mode.history);
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const Text(
                      'Самочувствие',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
                        : switch (_mode) {
                            _Mode.history => _buildHistory(),
                            _Mode.testing => _buildTest(),
                            _Mode.result => _buildResult(),
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassPanel(
          opacity: 0.08,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Короткий опросник самочувствия ВОЗ (WHO-5) — 5 вопросов о твоих '
                'последних двух неделях, минута на прохождение. Результат виден '
                'только тебе — никуда не отправляется и не хранится на сервере.',
                style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _startTest,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00B4D8)]),
                    ),
                    child: Text(
                      _history.isEmpty ? 'Пройти опросник' : 'Пройти ещё раз',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildToolTile(
          icon: Icons.support_rounded,
          title: 'Ситуативная помощь',
          subtitle: 'Тревога, плохое настроение, не могу уснуть — быстрые подсказки под ситуацию',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SituationalHelpScreen(userId: widget.userId, voiceStore: widget.voiceStore)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'ИНСТРУМЕНТЫ',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        _buildToolTile(
          icon: Icons.air_rounded,
          title: 'Дыхательное упражнение',
          subtitle: '«Квадратное» дыхание — 4 фазы по 4 секунды',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BreathingExerciseScreen()),
          ),
        ),
        const SizedBox(height: 10),
        _buildToolTile(
          icon: Icons.grid_view_rounded,
          title: 'Техника заземления 5-4-3-2-1',
          subtitle: 'Переключить внимание на органы чувств',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => GroundingExerciseScreen(voiceStore: widget.voiceStore)),
          ),
        ),
        const SizedBox(height: 10),
        _buildToolTile(
          icon: Icons.auto_awesome_rounded,
          title: 'Дневник благодарности',
          subtitle: 'Три вещи, за которые сегодня благодарен(на) — только на этом устройстве',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => GratitudeJournalScreen(userId: widget.userId)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'ОПРОСНИКИ (СКРИНИНГ)',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Официальные, свободно распространяемые инструменты (Pfizer). Не диагностика.',
          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11.5),
        ),
        const SizedBox(height: 10),
        _buildToolTile(
          icon: Icons.psychology_outlined,
          title: 'PHQ-9 — депрессивные симптомы',
          subtitle: '9 вопросов, 2-3 минуты',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => Phq9Screen(userId: widget.userId)),
          ),
        ),
        const SizedBox(height: 10),
        _buildToolTile(
          icon: Icons.waves_rounded,
          title: 'GAD-7 — тревожные симптомы',
          subtitle: '7 вопросов, 1-2 минуты',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => Gad7Screen(userId: widget.userId)),
          ),
        ),
        if (_history.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'ИСТОРИЯ',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ..._history.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassPanel(
                  opacity: 0.07,
                  blurred: false, // список из многих записей — см. message_bubble.dart
                  borderRadius: BorderRadius.circular(14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        '${c.percentScore}%',
                        style: TextStyle(
                          color: c.suggestsFurtherAssessment ? const Color(0xFFFFD166) : const Color(0xFF00E6A0),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat.yMMMd().add_Hm().format(c.date),
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              )),
        ],
        const SizedBox(height: 20),
        _buildAttributionFooter(),
      ],
    );
  }

  Widget _buildToolTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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

  Widget _buildTest() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Отметь, что ближе всего к тому, как ты себя чувствовал(а) последние '
          'две недели.',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < 5; i++) ...[
          _buildQuestion(i),
          const SizedBox(height: 14),
        ],
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 13)),
          const SizedBox(height: 12),
        ],
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _currentAnswers.every((a) => a != null) ? _submitTest : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: _currentAnswers.every((a) => a != null)
                      ? [const Color(0xFF6C5CE7), const Color(0xFF00B4D8)]
                      : [Colors.white24, Colors.white10],
                ),
              ),
              child: const Text('Показать результат', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion(int index) {
    return GlassPanel(
      opacity: 0.08,
      blurred: false, // 5 таких панелей на экране одновременно
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _who5Statements[index],
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_who5Options.length, (optionIdx) {
              // Шкала ВОЗ-5: "Всё время" = 5 баллов ... "Никогда" = 0.
              final value = 5 - optionIdx;
              final selected = _currentAnswers[index] == value;
              return ChoiceChip(
                label: Text(_who5Options[optionIdx]),
                selected: selected,
                onSelected: (_) => setState(() => _currentAnswers[index] = value),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.white.withOpacity(0.7),
                  fontSize: 12.5,
                ),
                selectedColor: const Color(0xFF6C5CE7),
                backgroundColor: Colors.white.withOpacity(0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.white.withOpacity(0.12)),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final result = _lastResult;
    if (result == null) return _buildHistory();

    final isLow = result.suggestsFurtherAssessment;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassPanel(
          opacity: 0.10,
          borderRadius: BorderRadius.circular(22),
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Text(
                '${result.percentScore}%',
                style: TextStyle(
                  color: isLow ? const Color(0xFFFFD166) : const Color(0xFF00E6A0),
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLow ? 'Показатель ниже среднего' : 'Показатель в пределах нормы',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                isLow
                    ? 'Это не диагноз. По методике ВОЗ балл ниже 50% — повод '
                        'обратиться к специалисту для более точной оценки '
                        'состояния, особенно если так продолжается больше '
                        'двух недель.'
                    : 'Официальная методика ВОЗ считает такой результат '
                        'признаком нормального психологического благополучия '
                        'за последние две недели.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        if (isLow) ...[
          const SizedBox(height: 16),
          const CrisisResourcesPanel(),
        ],
        const SizedBox(height: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _mode = _Mode.history),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.16)),
              ),
              child: Text('К истории', style: TextStyle(color: Colors.white.withOpacity(0.85))),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildAttributionFooter(),
      ],
    );
  }

  /// Обязательная нижняя приписка: ИИ может ошибаться, это не диагноз, за
  /// точной оценкой — к врачу. Плюс атрибуция ВОЗ-5 (лицензия CC BY-NC-SA —
  /// некоммерческое использование, это бесплатная часть приложения).
  Widget _buildAttributionFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ИИ и автоматические подсчёты могут ошибаться. Этот опросник — '
            'инструмент для самонаблюдения, а не диагностика. Для точной '
            'оценки психологического состояния обратись к врачу или '
            'психотерапевту.',
            style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Опросник: World Health Organization-Five Well-Being Index (WHO-5), '
            '© World Health Organization 2024, лицензия CC BY-NC-SA 3.0 IGO. '
            'Использование ВОЗ этого приложения не подразумевается.',
            style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 10.5, height: 1.5),
          ),
        ],
      ),
    );
  }
}
