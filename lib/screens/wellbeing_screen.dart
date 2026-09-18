import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:ai_last_v/l10n/app_localizations.dart';
import '../models/wellbeing_checkin.dart';
import '../services/wellbeing_service.dart';
import '../state/auth_store.dart';
import '../state/voice_store.dart';
import '../theme/app_text_color.dart';
import '../widgets/app_background.dart';
import '../widgets/crisis_resources_panel.dart';
import '../widgets/glass_panel.dart';
import 'asrs_screen.dart';
import 'bilateral_stimulation_screen.dart';
import 'breathing_exercise_screen.dart';
import 'freewriting_screen.dart';
import 'gad7_screen.dart';
import 'gratitude_journal_screen.dart';
import 'grounding_exercise_screen.dart';
import 'custom_test_list_screen.dart';
import 'my_help_screen.dart';
import 'memory_release_screen.dart';
import 'muscle_relaxation_screen.dart';
import 'phq9_screen.dart';
import 'personal_memories_screen.dart';

const _uuid = Uuid();

enum _Mode { history, testing, result }

class WellbeingScreen extends StatefulWidget {
  final String userId;
  final VoiceStore? voiceStore;
  final Future<void> Function(String text)? onStartAiConversation;
  final AuthStore? authStore;
  // false - когда экран используется внутри main_shell_screen.dart
  // (IndexedStack держит все вкладки смонтированными разом) - общий фон
  // там уже один на всю оболочку, не нужен ещё один здесь же
  final bool showOwnBackground;
  const WellbeingScreen({
    super.key,
    required this.userId,
    this.voiceStore,
    this.onStartAiConversation,
    this.authStore,
    this.showOwnBackground = true,
  });

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
  int _currentQuestion = 0;
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
      _currentQuestion = 0;
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
      setState(
        () => _error = AppLocalizations.of(context)!.wellbeingSaveFailed,
      );
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        enabled: widget.showOwnBackground,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_mode != _Mode.history || widget.showOwnBackground)
                      IconButton(
                        icon: Icon(
                          Icons.adaptive.arrow_back,
                          color: context.onSurface,
                        ),
                        onPressed: () {
                          if (_mode != _Mode.history) {
                            setState(() => _mode = _Mode.history);
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                      )
                    else
                      const SizedBox(width: 8),
                    Text(
                      l10n.chatMenuWellbeing,
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
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF6C5CE7),
                            ),
                          )
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
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.wellbeingToolsSection,
          style: TextStyle(
            color: context.onSurfaceFaded(0.4),
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: [
            _buildGridTile(
              icon: Icons.air_rounded,
              title: l10n.wellbeingBreathingTitle,
              subtitle: l10n.wellbeingBreathingSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BreathingExerciseScreen(),
                ),
              ),
            ),
            _buildGridTile(
              icon: Icons.grid_view_rounded,
              title: l10n.wellbeingGroundingTitle,
              subtitle: '5-4-3-2-1',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      GroundingExerciseScreen(voiceStore: widget.voiceStore),
                ),
              ),
            ),
            _buildGridTile(
              icon: Icons.auto_awesome_rounded,
              title: l10n.wellbeingGratitudeTitle,
              subtitle: l10n.wellbeingGratitudeSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GratitudeJournalScreen(userId: widget.userId),
                ),
              ),
            ),
            _buildGridTile(
              icon: Icons.remove_red_eye_outlined,
              title: l10n.wellbeingBilateralTitle,
              subtitle: l10n.wellbeingBilateralSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BilateralStimulationScreen(),
                ),
              ),
            ),
            _buildGridTile(
              icon: Icons.fitness_center_outlined,
              title: l10n.wellbeingMuscleRelaxationTitle,
              subtitle: l10n.wellbeingMuscleRelaxationSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MuscleRelaxationScreen(),
                ),
              ),
            ),
            _buildGridTile(
              icon: Icons.lock_outline_rounded,
              title: l10n.wellbeingSafeTitle,
              subtitle: l10n.wellbeingSafeSubtitle,
              onTap: () {
                final authStore = widget.authStore;
                if (authStore == null) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PersonalMemoriesScreen(
                      authStore: authStore,
                      onStartAiConversation: widget.onStartAiConversation,
                    ),
                  ),
                );
              },
            ),
            _buildGridTile(
              icon: Icons.local_fire_department_outlined,
              title: l10n.wellbeingReleaseTitle,
              subtitle: l10n.wellbeingReleaseSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      MemoryReleaseScreen(authStore: widget.authStore),
                ),
              ),
            ),
            _buildGridTile(
              icon: Icons.edit_note_rounded,
              title: l10n.wellbeingFreewritingTitle,
              subtitle: l10n.wellbeingFreewritingSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FreewritingScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          l10n.wellbeingQuestionnairesSection,
          style: TextStyle(
            color: context.onSurfaceFaded(0.4),
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.wellbeingQuestionnairesDisclaimer,
          style: TextStyle(color: context.onSurfaceFaded(0.35), fontSize: 11.5),
        ),
        const SizedBox(height: 10),
        _buildToolTile(
          icon: Icons.favorite_border_rounded,
          title: l10n.who5CardTitle,
          subtitle: l10n.who5CardSubtitle,
          onTap: _startTest,
        ),
        const SizedBox(height: 10),
        _buildToolTile(
          icon: Icons.psychology_outlined,
          title: l10n.phq9TileTitle,
          subtitle: l10n.phq9TileSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Phq9Screen(userId: widget.userId),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildToolTile(
          icon: Icons.waves_rounded,
          title: l10n.gad7TileTitle,
          subtitle: l10n.gad7TileSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Gad7Screen(userId: widget.userId),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildToolTile(
          icon: Icons.bolt_outlined,
          title: l10n.asrsTileTitle,
          subtitle: l10n.asrsTileSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AsrsScreen(userId: widget.userId),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildToolTile(
          icon: Icons.quiz_outlined,
          title: l10n.customTestListTitle,
          subtitle: l10n.wellbeingCustomTestsSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CustomTestListScreen(authStore: widget.authStore!),
            ),
          ),
        ),
        if (widget.authStore != null) ...[
          const SizedBox(height: 10),
          _buildToolTile(
            icon: Icons.support_agent_rounded,
            title: l10n.wellbeingLiveHelpTitle,
            subtitle: l10n.wellbeingLiveHelpSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MyHelpScreen(authStore: widget.authStore!),
              ),
            ),
          ),
        ],
        if (_history.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            l10n.who5HistorySection,
            style: TextStyle(
              color: context.onSurfaceFaded(0.4),
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ..._history.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassPanel(
                opacity: 0.07,
                blurred:
                    false, // список из многих записей — см. message_bubble.dart
                borderRadius: BorderRadius.circular(14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      '${c.percentScore}%',
                      style: TextStyle(
                        color: c.suggestsFurtherAssessment
                            ? const Color(0xFFFFD166)
                            : const Color(0xFF00E6A0),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat.yMMMd().add_Hm().format(c.date),
                      style: TextStyle(
                        color: context.onSurfaceFaded(0.5),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildAttributionFooter(),
      ],
    );
  }

  Widget _buildGridTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GlassPanel(
      opacity: 0.08,
      blurred: false, // несколько таких карточек на экране одновременно
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6FB1DE), Color(0xFF4DD0C4)],
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 19),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: context.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.onSurfaceFaded(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6FB1DE), Color(0xFF4DD0C4)],
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: context.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: context.onSurfaceFaded(0.45),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.onSurfaceFaded(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTest() {
    final l10n = AppLocalizations.of(context)!;
    final index = _currentQuestion;
    final isLast = index == 4;
    final answered = _currentAnswers[index] != null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.who5Instructions,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.onSurfaceFaded(0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final active = i == index;
                final done = i < index;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: done || active
                        ? const Color(0xFF6C5CE7)
                        : context.onSurfaceFaded(0.15),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            _buildQuestion(index),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                if (index > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.onSurfaceFaded(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () => setState(() => _currentQuestion--),
                      child: Text(
                        l10n.commonBack,
                        style: TextStyle(color: context.onSurfaceFaded(0.8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 2,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: !answered
                          ? null
                          : isLast
                          ? _submitTest
                          : () => setState(() => _currentQuestion++),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: answered
                                ? [
                                    const Color(0xFF6C5CE7),
                                    const Color(0xFF00B4D8),
                                  ]
                                : [Colors.white24, Colors.white10],
                          ),
                        ),
                        child: Text(
                          isLast ? l10n.who5ShowResult : l10n.commonNext,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(int index) {
    final l10n = AppLocalizations.of(context)!;
    // Пять официальных утверждений ВОЗ-5 (World Health Organization-Five
    // Well-Being Index) и шкала ответов - официальный русский перевод,
    // с сайта who.int/ru (Psychiatric Research Unit, WHO Collaborating
    // Centre in Mental Health); английский - официальная публикация ВОЗ,
    // не свободный перевод (важно для валидности инструмента скрининга)
    final statements = [
      l10n.who5Q1,
      l10n.who5Q2,
      l10n.who5Q3,
      l10n.who5Q4,
      l10n.who5Q5,
    ];
    final options = [
      l10n.who5ScaleAllTime,
      l10n.who5ScaleMostTime,
      l10n.who5ScaleMoreThanHalf,
      l10n.who5ScaleLessThanHalf,
      l10n.who5ScaleSomeTime,
      l10n.who5ScaleNever,
    ];
    return GlassPanel(
      opacity: 0.08,
      blurred: false,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statements[index],
            style: TextStyle(
              color: context.onSurface,
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(options.length, (optionIdx) {
              // Шкала ВОЗ-5: "Всё время" = 5 баллов ... "Никогда" = 0.
              final value = 5 - optionIdx;
              final selected = _currentAnswers[index] == value;
              return ChoiceChip(
                label: Text(options[optionIdx]),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _currentAnswers[index] = value),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : context.onSurfaceFaded(0.7),
                  fontSize: 12.5,
                ),
                selectedColor: const Color(0xFF6C5CE7),
                backgroundColor: context.onSurfaceFaded(0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: context.onSurfaceFaded(0.12)),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final l10n = AppLocalizations.of(context)!;
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
                  color: isLow
                      ? const Color(0xFFFFD166)
                      : const Color(0xFF00E6A0),
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLow ? l10n.who5ResultLow : l10n.who5ResultNormal,
                style: TextStyle(
                  color: context.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isLow ? l10n.who5DescriptionLow : l10n.who5DescriptionNormal,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.onSurfaceFaded(0.65),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (isLow) ...[
          const SizedBox(height: 16),
          const CrisisResourcesPanel(),
        ],
        if (widget.onStartAiConversation != null) ...[
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                final text = l10n.who5DiscussPrompt(
                  result.percentScore.toString(),
                  isLow ? l10n.who5RecommendSpecialist : '',
                );
                widget.onStartAiConversation!(text);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF00B4D8)],
                  ),
                ),
                child: Text(
                  l10n.who5DiscussButton,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
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
                border: Border.all(color: context.onSurfaceFaded(0.16)),
              ),
              child: Text(
                l10n.who5BackToHistory,
                style: TextStyle(color: context.onSurfaceFaded(0.85)),
              ),
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.wellbeingAiDisclaimer,
            style: TextStyle(
              color: context.onSurfaceFaded(0.35),
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.who5LicenseAttribution,
            style: TextStyle(
              color: context.onSurfaceFaded(0.25),
              fontSize: 10.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
