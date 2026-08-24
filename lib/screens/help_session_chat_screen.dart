import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/gad7_checkin.dart';
import '../models/help_session.dart';
import '../models/phq9_checkin.dart';
import '../models/wellbeing_checkin.dart';
import '../services/gad7_service.dart';
import '../services/help_service.dart';
import '../services/phq9_service.dart';
import '../services/wellbeing_service.dart';
import '../state/auth_store.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

// экран переписки внутри сессии живой помощи, общий для юзера и
// оператора - кто есть кто определяется по currentUserId
//
// обновление по опросу (polling), не WebSocket - в проекте нет
// инфраструктуры для постоянного соединения (SSE только для стриминга
// ответов ИИ, другой протокол), добавлять WebSocket ради одной фичи -
// намного больше работы. Опрос раз в несколько секунд даёт приемлемую
// задержку, не мгновенную
class HelpSessionChatScreen extends StatefulWidget {
  final AuthStore authStore;
  final HelpSession session;
  const HelpSessionChatScreen({super.key, required this.authStore, required this.session});

  @override
  State<HelpSessionChatScreen> createState() => _HelpSessionChatScreenState();
}

class _HelpSessionChatScreenState extends State<HelpSessionChatScreen> {
  final _service = HelpService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  List<HelpMessage> _messages = [];
  late HelpSession _session;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isRatingSaving = false;
  String? _error;

  int? get _myId => widget.authStore.user?.id;

  bool get _isRequester => _myId != null && _myId == _session.userId;

  // участник переписки, не админ - тот может только смотреть для
  // надзора, не писать. Поле ввода и "Завершить" только для участников
  bool get _isParticipant => _myId != null && (_myId == _session.userId || _myId == _session.operatorId);

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _service.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final token = widget.authStore.token;
    if (token == null) return;
    if (!silent) setState(() => _isLoading = true);
    try {
      final messages = await _service.getMessages(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        sessionId: _session.id,
      );
      if (!mounted) return;
      final hadFewerMessages = messages.length > _messages.length;
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      if (hadFewerMessages) _scrollToBottom();
    } on HelpException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final token = widget.authStore.token;
    final text = _controller.text.trim();
    if (token == null || text.isEmpty || _session.status == HelpSessionStatus.closed) return;

    setState(() => _isSending = true);
    try {
      final message = await _service.sendMessage(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        sessionId: _session.id,
        content: text,
      );
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, message];
        _controller.clear();
      });
      _scrollToBottom();
    } on HelpException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _close() async {
    final token = widget.authStore.token;
    if (token == null) return;
    try {
      final updated = await _service.closeSession(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        sessionId: _session.id,
      );
      if (mounted) setState(() => _session = updated);
    } on HelpException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _submitRating(int stars, String? comment) async {
    final token = widget.authStore.token;
    if (token == null) return;
    setState(() => _isRatingSaving = true);
    try {
      final updated = await _service.rateSession(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        sessionId: _session.id,
        rating: stars,
        comment: comment,
      );
      if (mounted) setState(() => _session = updated);
    } on HelpException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isRatingSaving = false);
    }
  }

  // собирает последний результат каждого из трёх опросников (если он
  // вообще проходился) и даёт выбрать, какой отправить оператору —
  // отдельным сообщением в этой же (уже приватной) переписке, не через
  // новый канал. Ничего не отправляется без явного тапа пользователя.
  Future<void> _shareTestResults() async {
    final userId = widget.authStore.user?.id.toString() ?? '';
    final who5 = (await WellbeingService().loadCheckins(userId));
    final phq9 = (await Phq9Service().loadCheckins(userId));
    final gad7 = (await Gad7Service().loadCheckins(userId));

    if (!mounted) return;

    if (who5.isEmpty && phq9.isEmpty && gad7.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пока нет пройденных опросников — их можно пройти в разделе «Самочувствие».')),
      );
      return;
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A2036),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Какой результат отправить?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 12),
              if (who5.isNotEmpty)
                _resultTile(
                  context,
                  title: 'ВОЗ-5 — общее самочувствие',
                  date: who5.first.date,
                  score: '${who5.first.percentScore}%',
                  onTap: () => Navigator.of(context).pop('who5'),
                ),
              if (phq9.isNotEmpty)
                _resultTile(
                  context,
                  title: 'PHQ-9 — депрессивные симптомы',
                  date: phq9.first.date,
                  score: '${phq9.first.rawScore}/27',
                  onTap: () => Navigator.of(context).pop('phq9'),
                ),
              if (gad7.isNotEmpty)
                _resultTile(
                  context,
                  title: 'GAD-7 — тревожные симптомы',
                  date: gad7.first.date,
                  score: '${gad7.first.rawScore}/21',
                  onTap: () => Navigator.of(context).pop('gad7'),
                ),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !mounted) return;

    String text;
    switch (choice) {
      case 'who5':
        final c = who5.first;
        text = 'Результат опросника ВОЗ-5 (${DateFormat.yMMMd().format(c.date)}): '
            '${c.percentScore}%${c.suggestsFurtherAssessment ? " — методика рекомендует обсудить со специалистом" : ""}.';
        break;
      case 'phq9':
        final c = phq9.first;
        text = 'Результат опросника PHQ-9 (${DateFormat.yMMMd().format(c.date)}): '
            '${c.rawScore}/27, методика описывает это как «${c.severityLabel}»'
            '${c.hasRiskSignal ? ". Отмечены мысли о самоповреждении в пункте 9" : ""}.';
        break;
      case 'gad7':
        final c = gad7.first;
        text = 'Результат опросника GAD-7 (${DateFormat.yMMMd().format(c.date)}): '
            '${c.rawScore}/21, методика описывает это как «${c.severityLabel}».';
        break;
      default:
        return;
    }

    final token = widget.authStore.token;
    if (token == null) return;
    try {
      final message = await _service.sendMessage(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        sessionId: _session.id,
        content: text,
      );
      if (mounted) {
        setState(() => _messages = [..._messages, message]);
        _scrollToBottom();
      }
    } on HelpException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Widget _resultTile(
    BuildContext context, {
    required String title,
    required DateTime date,
    required String score,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 13.5)),
                    Text(DateFormat.yMMMd().format(date), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11.5)),
                  ],
                ),
              ),
              Text(score, style: const TextStyle(color: Color(0xFF00E6A0), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = _session.status == HelpSessionStatus.closed;
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Живая помощь', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(
                            isClosed
                                ? 'Обращение закрыто'
                                : _session.operatorEmail != null
                                    ? 'Подключён: ${_session.operatorEmail}'
                                    : 'Ждём, когда кто-то подключится…',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (!isClosed && _isRequester && _session.operatorId != null)
                      IconButton(
                        tooltip: 'Отправить результаты теста',
                        icon: Icon(Icons.assignment_turned_in_outlined, color: Colors.white.withOpacity(0.7)),
                        onPressed: _shareTestResults,
                      ),
                    if (!isClosed && _isParticipant)
                      TextButton(
                        onPressed: _close,
                        child: Text('Завершить', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                      ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 12.5)),
                ),
              if (_session.chatContext != null && _session.chatContext!.isNotEmpty)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _ChatContextPanel(text: _session.chatContext!),
                    ),
                  ),
                ),
              if (isClosed && _isRequester && _session.operatorId != null)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _RatingPanel(
                        currentRating: _session.rating,
                        isSaving: _isRatingSaving,
                        onSubmit: _submitRating,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: _messages.isEmpty
                              ? Center(
                                  child: Text(
                                    _session.operatorEmail == null
                                        ? 'Заявка отправлена — сообщение появится, как только кто-то подключится.'
                                        : 'Напиши, что случилось.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white.withOpacity(0.4)),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  itemCount: _messages.length,
                                  itemBuilder: (context, i) => _buildMessage(_messages[i]),
                                ),
                        ),
                      ),
              ),
              if (!isClosed && _isParticipant)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: GlassPanel(
                        opacity: 0.12,
                        borderRadius: BorderRadius.circular(24),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                minLines: 1,
                                maxLines: 4,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Написать сообщение…',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                                ),
                                onSubmitted: (_) => _send(),
                              ),
                            ),
                            IconButton(
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.send_rounded, color: Colors.white),
                              onPressed: _isSending ? null : _send,
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

  Widget _buildMessage(HelpMessage message) {
    final isMine = message.senderId == _myId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: GlassPanel(
              opacity: isMine ? 0.16 : 0.09,
              tint: isMine ? const Color(0xFF6C5CE7) : null,
              blurred: false,
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message.content, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.Hm().format(message.createdAt),
                    style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// снимок сообщений с ИИ, которым юзер согласился поделиться (см.
// подтверждение в chat_screen.dart). Развёрнут по умолчанию
class _ChatContextPanel extends StatefulWidget {
  final String text;
  const _ChatContextPanel({required this.text});

  @override
  State<_ChatContextPanel> createState() => _ChatContextPanelState();
}

class _ChatContextPanelState extends State<_ChatContextPanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      opacity: 0.07,
      blurred: false,
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 14, color: Colors.white.withOpacity(0.5)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Что происходило в чате с ИИ до этого обращения',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Text(
                  widget.text,
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12.5, height: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// оценка оператора звёздами, видна только тому, кто запрашивал помощь,
// после закрытия. Можно переоценить - сервер просто перезаписывает
class _RatingPanel extends StatefulWidget {
  final int? currentRating;
  final bool isSaving;
  final void Function(int stars, String? comment) onSubmit;
  const _RatingPanel({required this.currentRating, required this.isSaving, required this.onSubmit});

  @override
  State<_RatingPanel> createState() => _RatingPanelState();
}

class _RatingPanelState extends State<_RatingPanel> {
  late int _selected = widget.currentRating ?? 0;
  final _commentController = TextEditingController();
  bool _showCommentField = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alreadyRated = widget.currentRating != null;
    return GlassPanel(
      opacity: 0.09,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alreadyRated ? 'Твоя оценка' : 'Как прошло общение с оператором?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              final filled = starIndex <= _selected;
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: filled ? const Color(0xFFFFD166) : Colors.white.withOpacity(0.3),
                  size: 30,
                ),
                onPressed: widget.isSaving
                    ? null
                    : () => setState(() {
                          _selected = starIndex;
                          _showCommentField = true;
                        }),
              );
            }),
          ),
          if (_showCommentField && !alreadyRated) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(10),
                hintText: 'Комментарий (необязательно)',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                onPressed: widget.isSaving || _selected == 0
                    ? null
                    : () => widget.onSubmit(_selected, _commentController.text.trim().isEmpty ? null : _commentController.text.trim()),
                child: widget.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Отправить'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
