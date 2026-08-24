import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';
import '../state/auth_store.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

/// Имя ассистента и дополнительные инструкции ("о чём и как ему отвечать") —
/// admin-only, влияет на все разговоры сразу. Намеренно НЕ может отключить
/// или заменить встроенные правила безопасности (см. main.py) — это
/// добавка поверх обычного тона, не замена защиты.
class AdminAiScreen extends StatefulWidget {
  final AuthStore authStore;
  const AdminAiScreen({super.key, required this.authStore});

  @override
  State<AdminAiScreen> createState() => _AdminAiScreenState();
}

class _AdminAiScreenState extends State<AdminAiScreen> {
  final _service = AppSettingsService();
  final _nameController = TextEditingController();
  final _promptController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isResetting = false;
  String? _error;
  String? _savedNotice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = widget.authStore.token;
    if (token == null) return;
    setState(() => _isLoading = true);
    try {
      final persona = await _service.getPersonaSettings(baseUrl: widget.authStore.baseUrl, token: token);
      if (!mounted) return;
      _nameController.text = persona.assistantName;
      _promptController.text = persona.assistantCustomPrompt;
    } on AppSettingsException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final token = widget.authStore.token;
    if (token == null) return;
    setState(() {
      _isSaving = true;
      _error = null;
      _savedNotice = null;
    });
    try {
      await _service.updatePersonaSettings(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        assistantName: _nameController.text.trim(),
        assistantCustomPrompt: _promptController.text.trim(),
      );
      if (mounted) setState(() => _savedNotice = 'Сохранено');
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
                const Text(
                  'Сбросить имя и инструкции ИИ?',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ассистент вернётся к обычному поведению без имени и '
                  'дополнительных инструкций.',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Отмена', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B)),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Сбросить'),
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
      _savedNotice = null;
    });
    try {
      final reset = await _service.resetPersonaSettings(baseUrl: widget.authStore.baseUrl, token: token);
      if (mounted) {
        _nameController.text = reset.assistantName;
        _promptController.text = reset.assistantCustomPrompt;
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
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Личность ИИ',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
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
                                GlassPanel(
                                  opacity: 0.08,
                                  borderRadius: BorderRadius.circular(16),
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Icon(Icons.shield_outlined, color: Colors.white.withOpacity(0.6), size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Встроенные правила безопасности и поддерживающий тон '
                                          'нельзя отключить или переопределить отсюда — то, что '
                                          'ты задашь ниже, добавляется поверх них, не вместо.',
                                          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12, height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'ИМЯ АССИСТЕНТА',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.07),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    hintText: 'Например: Люмен (необязательно)',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'ДОПОЛНИТЕЛЬНЫЕ ИНСТРУКЦИИ',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Чем должен заниматься ассистент, какого стиля держаться — добавляется к каждому разговору.',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11.5),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _promptController,
                                  maxLines: 6,
                                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.07),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.all(14),
                                    hintText: 'Например: специализируешься на поддержке в учёбе, объясняй просто и с примерами.',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(14),
                                          onTap: _isSaving ? null : _save,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 13),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(14),
                                              gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00B4D8)]),
                                            ),
                                            child: _isSaving
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                  )
                                                : const Text('Сохранить', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_savedNotice != null) ...[
                                  const SizedBox(height: 8),
                                  Text(_savedNotice!, style: const TextStyle(color: Color(0xFF00E6A0), fontSize: 12.5)),
                                ],
                                const SizedBox(height: 20),
                                OutlinedButton.icon(
                                  onPressed: _isResetting ? null : _confirmReset,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white.withOpacity(0.16)),
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    foregroundColor: Colors.white70,
                                  ),
                                  icon: _isResetting
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
                                      : const Icon(Icons.restart_alt_rounded, size: 18),
                                  label: const Text('Сбросить'),
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
