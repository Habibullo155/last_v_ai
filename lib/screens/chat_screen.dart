import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../state/auth_store.dart';
import '../state/chat_store.dart';
import '../state/theme_store.dart';
import '../state/voice_store.dart';
import '../utils/responsive.dart';
import '../widgets/app_background.dart';
import '../widgets/backend_status_pill.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/conversation_sidebar.dart';
import '../widgets/glass_panel.dart';
import '../widgets/message_bubble.dart';
import '../widgets/report_dialog.dart';
import 'admin_home_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart';
import 'voice_settings_screen.dart';
import 'wellbeing_screen.dart';

class ChatScreen extends StatefulWidget {
  final ChatStore store;
  final AuthStore authStore;
  final ThemeStore themeStore;
  final VoiceStore voiceStore;
  const ChatScreen({
    super.key,
    required this.store,
    required this.authStore,
    required this.themeStore,
    required this.voiceStore,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleSend(String text) async {
    _scrollToBottom();
    await widget.store.sendMessage(text);
    _scrollToBottom();
    _maybeAutoReadLastResponse();
  }

  /// Озвучивает последний ответ ассистента, если включена автоозвучка в
  /// настройках голоса — вызывается сразу после того, как стриминг ответа
  /// закончился (и на обычную отправку, и на перегенерацию).
  void _maybeAutoReadLastResponse() {
    final voice = widget.voiceStore;
    if (!voice.settings.autoReadEnabled || !voice.isVoiceFeatureEnabled) return;
    final convo = widget.store.active;
    if (convo == null || convo.messages.isEmpty) return;
    final last = convo.messages.last;
    if (last.role == MessageRole.assistant && !last.isError && last.content.trim().isNotEmpty) {
      voice.speak(last.content);
    }
  }

  /// Ищет ближайшее сообщение пользователя ПЕРЕД ответом ассистента с
  /// индексом [assistantIndex] — это и есть вопрос, на который отвечала
  /// модель, нужен для жалобы (чтобы разбирающий видел вопрос и ответ вместе).
  String _precedingUserMessage(List<ChatMessage> messages, int assistantIndex) {
    for (var i = assistantIndex - 1; i >= 0; i--) {
      if (messages[i].role == MessageRole.user) return messages[i].content;
    }
    return '(вопрос не найден)';
  }

  @override
  Widget build(BuildContext context) {
    final showSidebar = Responsive.showPersistentSidebar(context);
    final sidebarWidth = Responsive.sidebarWidth(context);

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      drawer: showSidebar
          ? null
          : Drawer(
              backgroundColor: Colors.transparent,
              child: AppBackground(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 50, 12, 12),
                  child: ConversationSidebar(
                    store: widget.store,
                    onSelected: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showSidebar) ...[
                  SizedBox(
                    width: sidebarWidth,
                    child: ConversationSidebar(store: widget.store),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(child: _buildChatArea(context, showSidebar)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatArea(BuildContext context, bool showSidebar) {
    final maxWidth = Responsive.chatMaxWidth(context);

    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final convo = widget.store.active;
        final messages = convo?.messages ?? const <ChatMessage>[];
        final canRegenerate = messages.isNotEmpty &&
            messages.last.role == MessageRole.assistant &&
            !messages.last.isStreaming &&
            !widget.store.isSending;

        return Column(
          children: [
            _buildTopBar(context, showSidebar, convo?.title ?? 'Новый чат'),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: messages.isEmpty
                      ? _EmptyState(onPromptTap: _handleSend)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: messages.length,
                          itemBuilder: (context, i) => MessageBubble(
                            message: messages[i],
                            onDelete: () => widget.store.deleteMessage(messages[i].id),
                            onReport: messages[i].role == MessageRole.assistant
                                ? () => showReportDialog(
                                      context,
                                      authStore: widget.authStore,
                                      userMessage: _precedingUserMessage(messages, i),
                                      aiResponse: messages[i].content,
                                    )
                                : null,
                            onSpeak: messages[i].role == MessageRole.assistant &&
                                    widget.voiceStore.isVoiceFeatureEnabled
                                ? () => widget.voiceStore.speak(messages[i].content)
                                : null,
                          ),
                        ),
                ),
              ),
            ),
            if (canRegenerate) ...[
              const SizedBox(height: 8),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        await widget.store.regenerateLastResponse();
                        _scrollToBottom();
                        _maybeAutoReadLastResponse();
                      },
                      icon: Icon(Icons.refresh_rounded, size: 16, color: Colors.white.withOpacity(0.6)),
                      label: Text(
                        'Перегенерировать ответ',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: ChatInputBar(
                  enabled: !widget.store.isSending,
                  onSend: _handleSend,
                  voiceStore: widget.voiceStore,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ИИ может ошибаться. Проверяй важную информацию самостоятельно.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.28), fontSize: 10.5),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, bool showSidebar, String title) {
    return GlassPanel(
      opacity: 0.08,
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (!showSidebar)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          BackendStatusPill(store: widget.store),
          const SizedBox(width: 8),
          _buildMenuButton(context),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    final isAdmin = widget.authStore.user?.isAdmin ?? false;
    return PopupMenuButton<String>(
      tooltip: 'Меню',
      icon: const Icon(Icons.account_circle_rounded, color: Colors.white),
      color: const Color(0xFF1A2036),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProfileScreen(authStore: widget.authStore)),
            );
            break;
          case 'wellbeing':
            final userId = widget.authStore.user?.id.toString();
            if (userId == null) return;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => WellbeingScreen(userId: userId)),
            );
            break;
          case 'settings':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  authStore: widget.authStore,
                  chatStore: widget.store,
                  themeStore: widget.themeStore,
                ),
              ),
            );
            break;
          case 'voice':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VoiceSettingsScreen(voiceStore: widget.voiceStore)),
            );
            break;
          case 'support':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SupportScreen(authStore: widget.authStore)),
            );
            break;
          case 'admin':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AdminHomeScreen(authStore: widget.authStore)),
            );
            break;
        }
      },
      itemBuilder: (context) => [
        _menuItem('profile', Icons.account_circle_outlined, 'Личный кабинет'),
        _menuItem('wellbeing', Icons.self_improvement_rounded, 'Самочувствие'),
        _menuItem('settings', Icons.settings_outlined, 'Настройки'),
        _menuItem('voice', Icons.record_voice_over_rounded, 'Голос'),
        _menuItem('support', Icons.support_agent_rounded, 'Поддержка'),
        if (isAdmin) _menuItem('admin', Icons.admin_panel_settings_rounded, 'Админ-панель'),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ValueChanged<String> onPromptTap;
  const _EmptyState({required this.onPromptTap});

  static const _suggestions = [
    'Объясни квантовую физику простыми словами',
    'Напиши план тренировок на неделю',
    'Помоги придумать название для проекта',
    'Как улучшить свой код на Dart?',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF00D9C0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.5),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 34),
            ),
            const SizedBox(height: 20),
            Text(
              'Чем помочь сегодня?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.92),
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _suggestions
                  .map((s) => _SuggestionChip(text: s, onTap: () => onPromptTap(s)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _SuggestionChip({required this.text, required this.onTap});

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}
