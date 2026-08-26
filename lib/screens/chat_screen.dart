import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../state/auth_store.dart';
import '../state/chat_store.dart';
import '../state/theme_store.dart';
import '../state/voice_store.dart';
import '../utils/responsive.dart';
import '../widgets/app_background.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/conversation_sidebar.dart';
import '../widgets/glass_panel.dart';
import '../widgets/message_bubble.dart';
import '../widgets/report_dialog.dart';
import 'admin_home_screen.dart';
import 'profile_screen.dart';
import 'purchase_screen.dart';
import 'settings_screen.dart';
import '../services/help_service.dart';
import 'help_session_chat_screen.dart';
import 'my_help_screen.dart';
import 'my_reports_screen.dart';
import 'operator_dashboard_screen.dart';
import 'support_screen.dart';
import 'wellbeing_screen.dart';

class ChatScreen extends StatefulWidget {
  final ChatStore store;
  final AuthStore authStore;
  final ThemeStore themeStore;
  final VoiceStore voiceStore;
  // true в MainShellScreen (нижнее меню на мобильных) - там Профиль и
  // Самочувствие уже есть внизу, не дублируем в выпадающем меню
  final bool hideShellDuplicates;
  const ChatScreen({
    super.key,
    required this.store,
    required this.authStore,
    required this.themeStore,
    required this.voiceStore,
    this.hideShellDuplicates = false,
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

  Future<void> _handleSend(String text, {List<String>? images}) async {
    _scrollToBottom();
    await widget.store.sendMessage(text, images: images);
    _scrollToBottom();
    _maybeAutoReadLastResponse();
  }

  // только запасной путь для голоса на устройстве - облачный уже прочитан
  // по предложениям во время генерации (onAssistantTextChunk -> onIncomingText)
  void _maybeAutoReadLastResponse() {
    final voice = widget.voiceStore;
    if (!voice.settings.autoReadEnabled || !voice.isVoiceAvailable) return;
    if (voice.isCloudTtsAvailable) return;
    final convo = widget.store.active;
    if (convo == null || convo.messages.isEmpty) return;
    final last = convo.messages.last;
    if (last.role == MessageRole.assistant && !last.isError && last.content.trim().isNotEmpty) {
      voice.speak(last.content);
    }
  }

  // ближайшее сообщение юзера перед ответом - вопрос, на который отвечала
  // модель, для жалобы (видно вопрос и ответ вместе)
  String _precedingUserMessage(List<ChatMessage> messages, int assistantIndex) {
    for (var i = assistantIndex - 1; i >= 0; i--) {
      if (messages[i].role == MessageRole.user) return messages[i].content;
    }
    return '(вопрос не найден)';
  }

  // последние 15 сообщений для оператора при запросе живой помощи - не
  // автоматически, юзер подтверждает это в диалоге ниже
  String? _recentChatSnapshot() {
    final messages = widget.store.active?.messages;
    if (messages == null || messages.isEmpty) return null;
    final recent = messages.length > 15 ? messages.sublist(messages.length - 15) : messages;
    final lines = recent.map((m) {
      final who = m.role == MessageRole.user ? 'Пользователь' : 'ИИ';
      return '$who: ${m.content}';
    });
    return lines.join('\n');
  }

  Future<void> _requestLiveHelp() async {
    final snapshot = _recentChatSnapshot();

    // 'share' | 'no_share' | null(отмена) — раньше единственная кнопка
    // "Позвать" неявно тащила с собой перепиской, если она была; теперь
    // это отдельный, явный выбор самого пользователя, а не подразумеваемое
    // поведение.
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassPanel(
          opacity: 0.18,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Позвать человека на помощь?',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Подключится врач или специалист из команды. Это не замена '
                  'экстренной службе — если ситуация требует срочной '
                  'медицинской помощи, звони 103.',
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.5),
                ),
                if (snapshot != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Показать ему последние сообщения этого разговора с ИИ (до 15), '
                    'чтобы не объяснять всё заново?',
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12.5, height: 1.4),
                  ),
                ],
                const SizedBox(height: 18),
                if (snapshot != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                      onPressed: () => Navigator.of(context).pop('share'),
                      child: const Text('Да, показать разговор с ИИ'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.2))),
                      onPressed: () => Navigator.of(context).pop('no_share'),
                      child: Text('Нет, не показывать', style: TextStyle(color: Colors.white.withOpacity(0.85))),
                    ),
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                      onPressed: () => Navigator.of(context).pop('no_share'),
                      child: const Text('Позвать'),
                    ),
                  ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Отмена', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (choice == null || !mounted) return;

    final token = widget.authStore.token;
    if (token == null) return;

    final service = HelpService();
    try {
      final session = await service.createSession(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        chatContext: choice == 'share' ? snapshot : null,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HelpSessionChatScreen(authStore: widget.authStore, session: session)),
      );
    } on HelpException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      service.dispose();
    }
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
                    authStore: widget.authStore,
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
                    child: ConversationSidebar(store: widget.store, authStore: widget.authStore),
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
                            onEdit: messages[i].role == MessageRole.user
                                ? (newText) async {
                                    await widget.store.editAndResend(messages[i].id, newText);
                                    _scrollToBottom();
                                    _maybeAutoReadLastResponse();
                                  }
                                : null,
                            onReport: messages[i].role == MessageRole.assistant
                                ? () => showReportDialog(
                                      context,
                                      authStore: widget.authStore,
                                      userMessage: _precedingUserMessage(messages, i),
                                      aiResponse: messages[i].content,
                                    )
                                : null,
                            onSpeak: messages[i].role == MessageRole.assistant &&
                                    widget.voiceStore.isVoiceAvailable
                                ? () => widget.voiceStore.speak(messages[i].content)
                                : null,
                            // дизлайк = тот же поток, что жалоба - причина и на разбор
                            // админам. Лайк - просто локальная пометка
                            onRate: messages[i].role == MessageRole.assistant && !messages[i].isStreaming
                                ? (liked) {
                                    if (liked) {
                                      widget.store.rateMessage(messages[i].id, true);
                                    } else {
                                      widget.store.rateMessage(messages[i].id, false);
                                      showReportDialog(
                                        context,
                                        authStore: widget.authStore,
                                        userMessage: _precedingUserMessage(messages, i),
                                        aiResponse: messages[i].content,
                                      );
                                    }
                                  }
                                : null,
                            // только для последнего ответа, кнопка теперь в пузыре
                            onRegenerate: messages[i].role == MessageRole.assistant &&
                                    i == messages.length - 1 &&
                                    canRegenerate
                                ? () async {
                                    await widget.store.regenerateLastResponse();
                                    _scrollToBottom();
                                    _maybeAutoReadLastResponse();
                                  }
                                : null,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: ChatInputBar(
                  enabled: !widget.store.isSending,
                  onSend: _handleSend,
                  voiceStore: widget.voiceStore,
                  onCallHelp: _requestLiveHelp,
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
          _buildMenuButton(context),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    final isAdmin = widget.authStore.user?.isAdmin ?? false;
    final isOperator = widget.authStore.user?.isOperator ?? false;
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
              MaterialPageRoute(
                builder: (_) => WellbeingScreen(
                  userId: userId,
                  voiceStore: widget.voiceStore,
                  onStartAiConversation: (text) async {
                    widget.store.createNewChat();
                    await widget.store.sendMessage(text);
                    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            );
            break;
          case 'purchase':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PurchaseScreen(authStore: widget.authStore)),
            );
            break;
          case 'settings':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  authStore: widget.authStore,
                  chatStore: widget.store,
                  themeStore: widget.themeStore,
                  voiceStore: widget.voiceStore,
                ),
              ),
            );
            break;
          case 'my_reports':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MyReportsScreen(authStore: widget.authStore)),
            );
            break;
          case 'my_help':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MyHelpScreen(authStore: widget.authStore)),
            );
            break;
          case 'operator':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => OperatorDashboardScreen(authStore: widget.authStore)),
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
        if (!widget.hideShellDuplicates) ...[
          _menuItem('profile', Icons.account_circle_outlined, 'Личный кабинет'),
          _menuItem('wellbeing', Icons.self_improvement_rounded, 'Самочувствие'),
        ],
        _menuItem('purchase', Icons.workspace_premium_rounded, 'Подписка'),
        _menuItem('settings', Icons.settings_outlined, 'Настройки'),
        _menuItem('my_reports', Icons.flag_outlined, 'Мои жалобы'),
        _menuItem('my_help', Icons.support_rounded, 'Живая помощь'),
        if (isOperator) _menuItem('operator', Icons.headset_mic_rounded, 'Кабинет оператора'),
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
              child: const Icon(Icons.spa_rounded,
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
