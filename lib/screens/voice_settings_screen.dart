import 'package:flutter/material.dart';

import '../state/voice_store.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

enum _VoiceGender { female, male, other }

/// Эвристика по имени голоса — НЕ надёжна на 100% (движки синтеза речи
/// по-разному называют голоса на разных платформах), поэтому рядом с
/// каждым вариантом есть кнопка "прослушать": если категория ошиблась,
/// пользователь всё равно может на слух найти нужный голос.
_VoiceGender _guessGender(String name) {
  final lower = name.toLowerCase();
  const femaleMarkers = [
    'female', 'woman', '#female', 'milena', 'anna', 'alyona', 'алёна', 'анна',
    'elena', 'елена', 'olga', 'ольга', 'irina', 'ирина', 'katya', 'катя',
  ];
  const maleMarkers = [
    'male', 'man', '#male', 'yuri', 'юрий', 'pavel', 'павел', 'maxim',
    'максим', 'dmitri', 'дмитрий', 'ivan', 'иван', 'boris', 'борис',
  ];
  for (final m in femaleMarkers) {
    if (lower.contains(m)) return _VoiceGender.female;
  }
  for (final m in maleMarkers) {
    if (lower.contains(m)) return _VoiceGender.male;
  }
  return _VoiceGender.other;
}

class VoiceSettingsScreen extends StatefulWidget {
  final VoiceStore voiceStore;
  const VoiceSettingsScreen({super.key, required this.voiceStore});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  final _wordController = TextEditingController();
  final _pronunciationController = TextEditingController();

  @override
  void dispose() {
    _wordController.dispose();
    _pronunciationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voice = widget.voiceStore;

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
                      'Голос',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
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
                      child: AnimatedBuilder(
                        animation: voice,
                        builder: (context, _) => _buildContent(context, voice),
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

  Widget _buildContent(BuildContext context, VoiceStore voice) {
    if (!voice.isVoiceFeatureEnabled) {
      return GlassPanel(
        opacity: 0.08,
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.mic_off_rounded, color: Colors.white.withOpacity(0.4), size: 28),
            const SizedBox(height: 12),
            Text(
              'Голосовые функции временно выключены администратором.',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13.5, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassPanel(
          opacity: 0.08,
          borderRadius: BorderRadius.circular(18),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(
                voice.settings.voiceUiEnabled ? Icons.record_voice_over_rounded : Icons.voice_over_off_rounded,
                color: Colors.white70,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Использовать голос', style: TextStyle(color: Colors.white)),
              ),
              Switch(
                value: voice.settings.voiceUiEnabled,
                activeColor: const Color(0xFF6C5CE7),
                onChanged: (value) => voice.updateSettings(voice.settings.copyWith(voiceUiEnabled: value)),
              ),
            ],
          ),
        ),
        if (!voice.settings.voiceUiEnabled) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Микрофон и озвучка ответов скрыты. Включи переключатель выше, чтобы вернуть их.',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12.5, height: 1.4),
            ),
          ),
        ] else ...[
          const SizedBox(height: 20),
          _buildVoiceOptions(voice),
        ],
      ],
    );
  }

  Widget _buildVoiceOptions(VoiceStore voice) {
    final femaleVoices = voice.availableVoices.where((v) => _guessGender(v['name'] ?? '') == _VoiceGender.female).toList();
    final maleVoices = voice.availableVoices.where((v) => _guessGender(v['name'] ?? '') == _VoiceGender.male).toList();
    final otherVoices = voice.availableVoices.where((v) => _guessGender(v['name'] ?? '') == _VoiceGender.other).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel('РАСПОЗНАВАНИЕ РЕЧИ'),
        GlassPanel(
          opacity: 0.08,
          borderRadius: BorderRadius.circular(18),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                voice.isSttAvailable ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: voice.isSttAvailable ? const Color(0xFF00E6A0) : Colors.white38,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  voice.isSttAvailable
                      ? 'Микрофон доступен — кнопка появится рядом с полем ввода'
                      : 'Микрофон недоступен на этом устройстве (нет разрешения или движка распознавания)',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionLabel('ОЗВУЧКА ОТВЕТОВ'),
        GlassPanel(
          opacity: 0.08,
          borderRadius: BorderRadius.circular(18),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Expanded(
                child: Text('Озвучивать ответы автоматически', style: TextStyle(color: Colors.white)),
              ),
              Switch(
                value: voice.settings.autoReadEnabled,
                activeColor: const Color(0xFF6C5CE7),
                onChanged: (value) =>
                    voice.updateSettings(voice.settings.copyWith(autoReadEnabled: value)),
              ),
            ],
          ),
        ),
        if (voice.availableVoices.isEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Голоса ещё не загрузились или недоступны на этом устройстве.',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12.5),
          ),
        ] else ...[
          if (femaleVoices.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionLabel('ЖЕНСКИЙ ГОЛОС'),
            ...femaleVoices.map((v) => _buildVoiceTile(voice, v)),
          ],
          if (maleVoices.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionLabel('МУЖСКОЙ ГОЛОС'),
            ...maleVoices.map((v) => _buildVoiceTile(voice, v)),
          ],
          if (otherVoices.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionLabel('ДРУГИЕ ВАРИАНТЫ'),
            Text(
              'Не удалось определить голос по имени — просто послушай и выбери.',
              style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11.5),
            ),
            const SizedBox(height: 8),
            ...otherVoices.map((v) => _buildVoiceTile(voice, v)),
          ],
        ],
        const SizedBox(height: 24),
        _sectionLabel('СЛОВАРЬ ПРОИЗНОШЕНИЯ'),
        Text(
          'Если голос неправильно произносит какое-то слово — задай, как '
          'его нужно "прочитать".',
          style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 10),
        _buildPronunciationEditor(voice),
      ],
    );
  }

  Widget _buildVoiceTile(VoiceStore voice, Map<String, String> v) {
    final selected = v['name'] == voice.settings.voiceName && v['locale'] == voice.settings.voiceLocale;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassPanel(
        opacity: selected ? 0.14 : 0.07,
        blurred: false, // список из многих голосов — см. message_bubble.dart
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => voice.updateSettings(
              voice.settings.copyWith(voiceName: v['name'], voiceLocale: v['locale']),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v['name'] ?? '',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(v['locale'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.play_circle_outline_rounded, color: Colors.white.withOpacity(0.6), size: 20),
                    tooltip: 'Прослушать',
                    onPressed: () => voice.previewVoice(v['name'] ?? '', v['locale'] ?? ''),
                  ),
                  if (selected) const Icon(Icons.check_circle_rounded, color: Color(0xFF00E6A0), size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPronunciationEditor(VoiceStore voice) {
    final overrides = voice.settings.pronunciationOverrides;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (overrides.isNotEmpty)
          GlassPanel(
            opacity: 0.07,
            borderRadius: BorderRadius.circular(14),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: overrides.entries
                  .map((e) => ListTile(
                        dense: true,
                        title: Text('${e.key} → ${e.value}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white54),
                          onPressed: () {
                            final updated = Map<String, String>.from(overrides)..remove(e.key);
                            voice.updateSettings(voice.settings.copyWith(pronunciationOverrides: updated));
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _wordController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  hintText: 'Слово',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white38, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _pronunciationController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  hintText: 'Произношение',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF6C5CE7)),
              onPressed: () {
                final word = _wordController.text.trim();
                final pronunciation = _pronunciationController.text.trim();
                if (word.isEmpty || pronunciation.isEmpty) return;
                final updated = Map<String, String>.from(overrides)..[word] = pronunciation;
                voice.updateSettings(voice.settings.copyWith(pronunciationOverrides: updated));
                _wordController.clear();
                _pronunciationController.clear();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
