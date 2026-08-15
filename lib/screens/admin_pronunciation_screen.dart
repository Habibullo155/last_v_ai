import 'package:flutter/material.dart';

import '../services/pronunciation_service.dart';
import '../state/auth_store.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

class AdminPronunciationScreen extends StatefulWidget {
  final AuthStore authStore;
  const AdminPronunciationScreen({super.key, required this.authStore});

  @override
  State<AdminPronunciationScreen> createState() => _AdminPronunciationScreenState();
}

class _AdminPronunciationScreenState extends State<AdminPronunciationScreen> {
  final _service = PronunciationService();
  final _wordController = TextEditingController();
  final _pronunciationController = TextEditingController();

  List<Map<String, String>> _entries = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    _wordController.dispose();
    _pronunciationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = widget.authStore.token;
    if (token == null) return;
    setState(() => _isLoading = true);
    try {
      final entries = await _service.listAdmin(baseUrl: widget.authStore.baseUrl, token: token);
      if (mounted) setState(() => _entries = entries);
    } on PronunciationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addOrUpdate() async {
    final token = widget.authStore.token;
    final word = _wordController.text.trim();
    final pronunciation = _pronunciationController.text.trim();
    if (token == null || word.isEmpty || pronunciation.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await _service.upsert(baseUrl: widget.authStore.baseUrl, token: token, word: word, pronunciation: pronunciation);
      _wordController.clear();
      _pronunciationController.clear();
      await _load();
    } on PronunciationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete(String word) async {
    final token = widget.authStore.token;
    if (token == null) return;
    try {
      await _service.delete(baseUrl: widget.authStore.baseUrl, token: token, word: word);
      await _load();
    } on PronunciationException catch (e) {
      if (mounted) setState(() => _error = e.message);
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
                    const Expanded(
                      child: Text(
                        'Словарь произношения',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Действует для всех пользователей — если движок озвучки '
                            'неправильно произносит слово (название, аббревиатуру, '
                            'термин), задай здесь правильное "чтение". У каждого '
                            'пользователя есть ещё и свой личный словарь в настройках '
                            'голоса — он имеет приоритет над этим общим.',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12.5, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          _buildEditor(),
                          if (_error != null) ...[
                            const SizedBox(height: 10),
                            Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 13)),
                          ],
                          const SizedBox(height: 20),
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
                            )
                          else if (_entries.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Center(
                                child: Text('Словарь пуст', style: TextStyle(color: Colors.white.withOpacity(0.4))),
                              ),
                            )
                          else
                            ..._entries.map(_buildEntryTile),
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

  Widget _buildEditor() {
    return GlassPanel(
      opacity: 0.08,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(14),
      child: Row(
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
          const SizedBox(width: 6),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C5CE7)),
                  )
                : const Icon(Icons.add_circle_rounded, color: Color(0xFF6C5CE7)),
            onPressed: _isSaving ? null : _addOrUpdate,
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(Map<String, String> entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassPanel(
        opacity: 0.07,
        blurred: false, // список из многих слов — см. message_bubble.dart
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${entry['word']} → ${entry['pronunciation']}',
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFFFB4B4)),
              onPressed: () => _delete(entry['word'] ?? ''),
            ),
          ],
        ),
      ),
    );
  }
}
