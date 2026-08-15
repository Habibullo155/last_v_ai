import 'package:flutter/material.dart';

import '../state/voice_store.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

class VoiceSettingsScreen extends StatefulWidget {
  final VoiceStore voiceStore;
  const VoiceSettingsScreen({super.key, required this.voiceStore});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
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
        const SizedBox(height: 16),
        GlassPanel(
          opacity: 0.08,
          borderRadius: BorderRadius.circular(18),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Скорость речи', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
              Slider(
                value: voice.settings.rate,
                min: 0.1,
                max: 1.0,
                activeColor: const Color(0xFF6C5CE7),
                onChanged: (value) => voice.updateSettings(voice.settings.copyWith(rate: value)),
              ),
              const SizedBox(height: 8),
              Text('Высота голоса', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
              Slider(
                value: voice.settings.pitch,
                min: 0.5,
                max: 2.0,
                activeColor: const Color(0xFF6C5CE7),
                onChanged: (value) => voice.updateSettings(voice.settings.copyWith(pitch: value)),
              ),
            ],
          ),
        ),
        if (voice.availableVoices.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionLabel('ГОЛОС'),
          GlassPanel(
            opacity: 0.08,
            borderRadius: BorderRadius.circular(18),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: voice.availableVoices.length,
                itemBuilder: (context, i) {
                  final v = voice.availableVoices[i];
                  final selected = v['name'] == voice.settings.voiceName && v['locale'] == voice.settings.voiceLocale;
                  return ListTile(
                    dense: true,
                    title: Text(
                      v['name'] ?? '',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(v['locale'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                    trailing: selected ? const Icon(Icons.check_rounded, color: Color(0xFF00E6A0), size: 18) : null,
                    onTap: () => voice.updateSettings(
                      voice.settings.copyWith(voiceName: v['name'], voiceLocale: v['locale']),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => voice.speak('Привет! Так звучит выбранный голос.'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00B4D8)]),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(voice.isSpeaking ? Icons.stop_circle_rounded : Icons.play_circle_outline_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    voice.isSpeaking ? 'Остановить' : 'Проверить голос',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
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
