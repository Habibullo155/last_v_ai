import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../models/cloud_voice.dart';
import '../services/app_settings_service.dart';
import '../services/cloud_tts_service.dart';
import '../state/auth_store.dart';
import '../theme/app_text_color.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';
import 'admin_pronunciation_screen.dart';

/// Всё, что можно настроить для голоса ИИ, в одном месте — раньше было
/// разбросано (переключатель "включено/выключено" жил прямо на главном
/// экране админки, словарь произношения — отдельным пунктом меню).
class AdminVoiceScreen extends StatefulWidget {
  final AuthStore authStore;
  const AdminVoiceScreen({super.key, required this.authStore});

  @override
  State<AdminVoiceScreen> createState() => _AdminVoiceScreenState();
}

class _AdminVoiceScreenState extends State<AdminVoiceScreen> {
  final _service = AppSettingsService();
  final _cloudTts = CloudTtsService();
  final _previewPlayer = AudioPlayer();
  PublicAppSettings _settings = const PublicAppSettings(voiceEnabled: true, cloudTtsEnabled: false, ttsProvider: null);
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isResetting = false;
  String? _error;

  // локальные значения ползунков - независимы от _settings, пока админ
  // не нажмёт "Сохранить и прослушать" (или просто "Сохранить")
  double _pitch = 50;
  double _rate = 50;
  bool _pitchEnabled = false; // выключено = вообще не отправлять параметр
  bool _rateEnabled = false;
  int _sampleRate = 48000;
  bool _isPreviewPlaying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    _cloudTts.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final settings = await _service.getPublicSettings(widget.authStore.baseUrl);
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _isLoading = false;
      _pitchEnabled = settings.voicePitch != null;
      _rateEnabled = settings.voiceRate != null;
      _pitch = (settings.voicePitch ?? 50).toDouble();
      _rate = (settings.voiceRate ?? 50).toDouble();
      _sampleRate = settings.voiceSampleRate;
    });
  }

  /// Сохраняет текущие значения ползунков (или их отсутствие) и сразу
  /// проигрывает тестовую фразу — честно называется "Сохранить и
  /// прослушать", а не "Прослушать": pitch/rate — глобальная настройка
  /// сервера синтеза, а не параметр одного запроса, так что настоящего
  /// предпрослушивания без сохранения тут физически нет.
  Future<void> _saveAndPreviewPitchRate() async {
    final token = widget.authStore.token;
    if (token == null) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final updated = await _service.updateSettings(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        voicePitch: _pitchEnabled ? _pitch.round() : null,
        voiceRate: _rateEnabled ? _rate.round() : null,
        clearVoicePitch: !_pitchEnabled,
        clearVoiceRate: !_rateEnabled,
        voiceSampleRate: _sampleRate,
      );
      if (mounted) setState(() => _settings = updated);

      setState(() => _isPreviewPlaying = true);
      final bytes = await _cloudTts.synthesize(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        text: 'Привет! Так теперь звучит голос ассистента.',
        voiceName: _settings.defaultVoice,
      );
      if (mounted) await _previewPlayer.play(BytesSource(bytes));
    } on AppSettingsException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on CloudTtsException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
      if (mounted) setState(() => _isPreviewPlaying = false);
    }
  }

  Future<void> _update({bool? voiceEnabled, String? defaultVoice}) async {
    final token = widget.authStore.token;
    if (token == null) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final updated = await _service.updateSettings(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        voiceEnabled: voiceEnabled,
        defaultVoice: defaultVoice,
      );
      if (mounted) setState(() => _settings = updated);
    } on AppSettingsException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassPanel(
          opacity: 0.18,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Восстановить настройки по умолчанию?',
                  style: TextStyle(color: context.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Голос включится (если был выключен), голос по умолчанию '
                  'вернётся на первый в списке. Словарь произношения не '
                  'тронется — это отдельно накопленный контент, не настройка.',
                  style: TextStyle(color: context.onSurfaceFaded(0.6), fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Отмена', style: TextStyle(color: context.onSurfaceFaded(0.6))),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B)),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Восстановить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final token = widget.authStore.token;
    if (token == null) return;
    setState(() {
      _isResetting = true;
      _error = null;
    });
    try {
      final reset = await _service.resetToDefaults(baseUrl: widget.authStore.baseUrl, token: token);
      if (mounted) {
        setState(() {
          _settings = reset;
          _pitchEnabled = reset.voicePitch != null;
          _rateEnabled = reset.voiceRate != null;
          _pitch = (reset.voicePitch ?? 50).toDouble();
          _rate = (reset.voiceRate ?? 50).toDouble();
          _sampleRate = reset.voiceSampleRate;
        });
      }
    } on AppSettingsException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
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
                      icon: Icon(Icons.arrow_back_rounded, color: context.onSurface),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'Управление голосом',
                      style: TextStyle(color: context.onSurface, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Color(0xFF6C5CE7))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_error != null) ...[
                                  Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 13)),
                                  const SizedBox(height: 12),
                                ],
                                _buildStatusPanel(),
                                const SizedBox(height: 16),
                                _buildEnableToggle(),
                                const SizedBox(height: 20),
                                _buildDefaultVoicePicker(),
                                const SizedBox(height: 20),
                                _buildPitchRateSection(),
                                const SizedBox(height: 20),
                                _buildPronunciationLink(),
                                const SizedBox(height: 28),
                                _buildResetButton(),
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

  Widget _buildStatusPanel() {
    final configured = _settings.cloudTtsEnabled;
    return GlassPanel(
      opacity: 0.08,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            configured ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: configured ? const Color(0xFF00E6A0) : context.onSurfaceFaded(0.4),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              configured
                  ? 'Локальный сервер Silero TTS настроен (${_settings.ttsProvider ?? "silero"}) — используется вместо голоса устройства.'
                  : 'Сервер Silero TTS не настроен в .env — играет только голос устройства, список ниже недоступен.',
              style: TextStyle(color: context.onSurfaceFaded(0.6), fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnableToggle() {
    return GlassPanel(
      opacity: 0.08,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(
            _settings.voiceEnabled ? Icons.record_voice_over_rounded : Icons.voice_over_off_rounded,
            color: Colors.white70,
          ),
          const SizedBox(width: 12),
           Expanded(
            child: Text('Голосовые функции для всех пользователей', style: TextStyle(color: context.onSurface, fontSize: 13.5)),
          ),
          if (_isSaving)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C5CE7)),
            )
          else
            Switch(
              value: _settings.voiceEnabled,
              activeColor: const Color(0xFF6C5CE7),
              onChanged: (v) => _update(voiceEnabled: v),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultVoicePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ГОЛОС ПО УМОЛЧАНИЮ',
          style: TextStyle(color: context.onSurfaceFaded(0.4), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Каким голосом заговорит ИИ у пользователя, который сам ещё ничего не выбирал в своих настройках голоса.',
          style: TextStyle(color: context.onSurfaceFaded(0.35), fontSize: 11.5),
        ),
        const SizedBox(height: 10),
        if (!_settings.cloudTtsEnabled)
          GlassPanel(
            opacity: 0.06,
            borderRadius: BorderRadius.circular(14),
            padding: const EdgeInsets.all(14),
            child: Text(
              'Недоступно — сервер Silero TTS не настроен (см. панель выше).',
              style: TextStyle(color: context.onSurfaceFaded(0.4), fontSize: 12),
            ),
          )
        else
          ...sileroCloudVoices.map((v) {
            final selected = v.name == _settings.defaultVoice;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassPanel(
                opacity: selected ? 0.14 : 0.07,
                blurred: false, // список из 4 голосов на экране одновременно
                borderRadius: BorderRadius.circular(14),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _isSaving ? null : () => _update(defaultVoice: v.name),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            v.isFemale ? Icons.face_3_rounded : Icons.face_6_rounded,
                            color: context.onSurfaceFaded(0.6),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(v.label, style: TextStyle(color: context.onSurface, fontSize: 13.5))),
                          if (selected) const Icon(Icons.check_circle_rounded, color: Color(0xFF00E6A0), size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPronunciationLink() {
    return GlassPanel(
      opacity: 0.08,
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AdminPronunciationScreen(authStore: widget.authStore)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.spellcheck_rounded, color: context.onSurfaceFaded(0.7)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Словарь произношения', style: TextStyle(color: context.onSurface, fontSize: 13.5, fontWeight: FontWeight.w500)),
                      Text(
                        'Как озвучка должна "читать" конкретные слова',
                        style: TextStyle(color: context.onSurfaceFaded(0.4), fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: context.onSurfaceFaded(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPitchRateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ВЫСОТА И ТЕМП ГОЛОСА',
          style: TextStyle(color: context.onSurfaceFaded(0.4), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Необязательно — по умолчанию сервер синтеза сам решает. Значения '
          'здесь можно только услышать самому и подобрать на слух, точной '
          'документации на "что означает какое число" у сервера нет.',
          style: TextStyle(color: context.onSurfaceFaded(0.35), fontSize: 11.5, height: 1.4),
        ),
        const SizedBox(height: 10),
        if (!_settings.cloudTtsEnabled)
          GlassPanel(
            opacity: 0.06,
            borderRadius: BorderRadius.circular(14),
            padding: const EdgeInsets.all(14),
            child: Text(
              'Недоступно — сервер Silero TTS не настроен.',
              style: TextStyle(color: context.onSurfaceFaded(0.4), fontSize: 12),
            ),
          )
        else
          GlassPanel(
            opacity: 0.08,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pitchRateRow(
                  label: 'Высота голоса',
                  icon: Icons.graphic_eq_rounded,
                  enabled: _pitchEnabled,
                  value: _pitch,
                  onToggle: (v) => setState(() => _pitchEnabled = v),
                  onChanged: (v) => setState(() => _pitch = v),
                ),
                const SizedBox(height: 14),
                _pitchRateRow(
                  label: 'Темп речи',
                  icon: Icons.speed_rounded,
                  enabled: _rateEnabled,
                  value: _rate,
                  onToggle: (v) => setState(() => _rateEnabled = v),
                  onChanged: (v) => setState(() => _rate = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.high_quality_outlined, color: context.onSurfaceFaded(0.6), size: 16),
                    const SizedBox(width: 8),
                    Text('Качество звука', style: TextStyle(color: context.onSurface, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _sampleRateChip(8000, 'Ниже'),
                    const SizedBox(width: 8),
                    _sampleRateChip(24000, 'Среднее'),
                    const SizedBox(width: 8),
                    _sampleRateChip(48000, 'Высокое'),
                  ],
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _isSaving ? null : _saveAndPreviewPitchRate,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00B4D8)]),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSaving || _isPreviewPlaying)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          else
                            const Icon(Icons.volume_up_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text('Сохранить и прослушать', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // AnimatedContainer сам плавно перетекает между цветами при выборе -
  // не нужен отдельный AnimatedSwitcher для такой простой смены состояния
  Widget _sampleRateChip(int rate, String label) {
    final selected = _sampleRate == rate;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _sampleRate = rate),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: selected ? const Color(0xFF6C5CE7) : context.onSurfaceFaded(0.06),
              border: Border.all(color: selected ? const Color(0xFF6C5CE7) : context.onSurfaceFaded(0.12)),
            ),
            child: Text(
              label,
              style: TextStyle(color: selected ? Colors.white : context.onSurfaceFaded(0.6), fontSize: 12.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pitchRateRow({
    required String label,
    required IconData icon,
    required bool enabled,
    required double value,
    required ValueChanged<bool> onToggle,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, size: 16, color: enabled ? context.onSurfaceFaded(0.8) : context.onSurfaceFaded(0.3)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: TextStyle(color: enabled ? context.onSurface : context.onSurfaceFaded(0.4), fontSize: 13)),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: enabled
                  ? Text(value.round().toString(), key: const ValueKey('on'), style: const TextStyle(color: Color(0xFF00E6A0), fontSize: 12, fontWeight: FontWeight.w600))
                  : Text('не задано', key: const ValueKey('off'), style: TextStyle(color: context.onSurfaceFaded(0.3), fontSize: 11.5)),
            ),
            const SizedBox(width: 8),
            Switch(
              value: enabled,
              activeColor: const Color(0xFF6C5CE7),
              onChanged: onToggle,
            ),
          ],
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1 : 0.3,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6C5CE7),
              thumbColor: const Color(0xFF6C5CE7),
              overlayColor: const Color(0xFF6C5CE7).withOpacity(0.2),
              inactiveTrackColor: context.onSurfaceFaded(0.12),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return OutlinedButton.icon(
      onPressed: _isResetting ? null : _confirmReset,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: context.onSurfaceFaded(0.16)),
        padding: const EdgeInsets.symmetric(vertical: 13),
        foregroundColor: Colors.white70,
      ),
      icon: _isResetting
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
          : const Icon(Icons.restart_alt_rounded, size: 18),
      label: const Text('Восстановить по умолчанию'),
    );
  }
}
