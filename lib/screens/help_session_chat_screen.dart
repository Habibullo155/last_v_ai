import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/help_session.dart';
import '../services/help_service.dart';
import '../state/auth_store.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

/// Экран переписки внутри одной сессии живой помощи — общий для
/// пользователя и для оператора (кто есть кто определяется по
/// currentUserId, не по отдельному коду для каждой роли).
///
/// Обновление сообщений — по опросу (polling), не по WebSocket: в этом
/// проекте нет инфраструктуры для постоянного соединения (SSE
/// используется только для стриминга ответов ИИ, это другой протокол),
/// добавлять WebSocket-стек ради одной фичи — заметно больший объём
/// работы. Опрос раз в несколько секунд даёт приемлемую задержку для
/// живого разговора, не мгновенную.
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
  String? _error;

  int? get _myId => widget.authStore.user?.id;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _load();
    // 4 секунды — достаточно живо для разговора, не настолько часто,
    // чтобы заметно нагружать сервер большим числом одновременных сессий.
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
                    if (!isClosed)
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
              if (!isClosed)
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
