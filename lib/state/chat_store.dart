import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../config.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../services/chat_api_service.dart';
import '../services/storage_service.dart';

const _uuid = Uuid();

enum BackendStatus { unknown, checking, online, offline }

class ChatStore extends ChangeNotifier {
  // конструктор, не каскад ..field = ... после создания - так required
  // видно в сигнатуре, не забудешь подключить где-то ещё
  ChatStore({this.getAuthToken, this.onSessionExpired, this.onAssistantTextChunk});

  final StorageService _storage = StorageService();
  final ChatApiService _api = ChatApiService();

  // задаётся один раз при сборке через --dart-define=BACKEND_URL=...
  // (config.dart), кнопку сменить адрес в приложении убрали намеренно
  final String baseUrl = AppConfig.backendUrl;

  final List<ChatConversation> conversations = [];
  String? activeConversationId;
  BackendStatus backendStatus = BackendStatus.unknown;

  // id чатов, где сейчас идёт генерация. Раньше было одно глобальное
  // isSending - пока ИИ отвечал в одном чате, поле ввода блокировалось
  // везде. Теперь каждый чат независим
  final Set<String> _sendingConversationIds = {};

  // отправляется ли сообщение в ТЕКУЩЕМ чате, для блокировки инпута
  bool get isSending =>
      activeConversationId != null && _sendingConversationIds.contains(activeConversationId);

  // то же самое, но для любого чата по id - нужно сайдбару
  bool isSendingIn(String conversationId) => _sendingConversationIds.contains(conversationId);

  // токен не храним сами, источник правды - AuthStore. Функция, а не
  // строка, потому что токен может обновиться между запросами
  final String? Function()? getAuthToken;

  final Future<void> Function()? onSessionExpired; // 401 -> разлогинить

  // дёргается на каждый апдейт текста ответа, ещё до завершения генерации -
  // нужно для потокового чтения вслух (voice_store.dart: onIncomingText)
  final void Function({required String messageId, required String fullContent, required bool isDone})?
      onAssistantTextChunk;

  ChatConversation? get active => conversations
      .where((c) => c.id == activeConversationId)
      .cast<ChatConversation?>()
      .firstOrNull;

  String _userId = 'anonymous';

  Future<void> init(String userId) async {
    _userId = userId;
    try {
      final saved = await _storage.loadConversations(_userId);
      conversations.addAll(saved);
    } catch (_) {
      // подстраховка на случай непредвиденной ошибки, чтобы не зависнуть
    }
    if (conversations.isEmpty) {
      _createConversation();
    } else {
      activeConversationId = conversations.first.id;
    }
    notifyListeners();
    unawaited(refreshBackendStatus());
  }

  Future<void> refreshBackendStatus() async {
    backendStatus = BackendStatus.checking;
    notifyListeners();
    final ok = await _api.checkHealth(baseUrl);
    backendStatus = ok ? BackendStatus.online : BackendStatus.offline;
    notifyListeners();
  }

  void _createConversation() {
    final convo = ChatConversation(id: _uuid.v4(), title: 'Новый чат');
    conversations.insert(0, convo);
    activeConversationId = convo.id;
  }

  void createNewChat() {
    // если уже есть пустой чат - просто переключаемся на него
    final existingEmpty =
        conversations.where((c) => c.isEmpty).cast<ChatConversation?>().firstOrNull;
    if (existingEmpty != null) {
      activeConversationId = existingEmpty.id;
      notifyListeners();
      return;
    }
    _createConversation();
    notifyListeners();
  }

  void selectConversation(String id) {
    activeConversationId = id;
    notifyListeners();
  }

  void deleteConversation(String id) {
    conversations.removeWhere((c) => c.id == id);
    if (conversations.isEmpty) {
      _createConversation();
    } else if (activeConversationId == id) {
      activeConversationId = conversations.first.id;
    }
    _persist();
    notifyListeners();
  }

  // юзер сам переименовывает - иначе название всегда из первого сообщения
  void renameConversation(String id, String newTitle) {
    final title = newTitle.trim();
    if (title.isEmpty) return;
    final convo = conversations.where((c) => c.id == id).cast<ChatConversation?>().firstOrNull;
    if (convo == null) return;
    convo.title = title;
    unawaited(_persist());
    notifyListeners();
  }

  void deleteMessage(String messageId) {
    final convo = active;
    if (convo == null) return;
    convo.messages.removeWhere((m) => m.id == messageId);
    unawaited(_persist());
    notifyListeners();
  }

  // повторный тап по уже выставленной оценке снимает её, не переключает
  // на противоположную
  void rateMessage(String messageId, bool liked) {
    final convo = active;
    if (convo == null) return;
    final message = convo.messages.where((m) => m.id == messageId).firstOrNull;
    if (message == null) return;
    message.liked = message.liked == liked ? null : liked;
    unawaited(_persist());
    notifyListeners();
  }

  // как в ChatGPT: всё после отредактированного сообщения удаляется,
  // генерируется новый ответ на исправленный текст
  Future<void> editAndResend(String messageId, String newText) async {
    final convo = active;
    if (convo == null || newText.trim().isEmpty || _sendingConversationIds.contains(convo.id)) return;

    final index = convo.messages.indexWhere((m) => m.id == messageId);
    if (index == -1 || convo.messages[index].role != MessageRole.user) return;

    // обрезаем начиная с редактируемого, sendMessage() добавит новое как обычно
    convo.messages.removeRange(index, convo.messages.length);
    await sendMessage(newText);
  }

  Future<void> sendMessage(String text) async {
    final convo = active;
    if (convo == null || text.trim().isEmpty || _sendingConversationIds.contains(convo.id)) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: text.trim(),
    );
    convo.messages.add(userMsg);

    if (convo.title == 'Новый чат') {
      convo.title = text.trim().length > 40
          ? '${text.trim().substring(0, 40)}…'
          : text.trim();
    }

    await _streamAssistantReply(convo);
  }

  // убирает предыдущий ответ и запрашивает новый на ту же историю,
  // без повторной отправки вопроса
  Future<void> regenerateLastResponse() async {
    final convo = active;
    if (convo == null || _sendingConversationIds.contains(convo.id) || convo.messages.isEmpty) return;

    if (convo.messages.last.role == MessageRole.assistant) {
      convo.messages.removeLast();
    }
    if (convo.messages.isEmpty || convo.messages.last.role != MessageRole.user) {
      // нечего перегенерировать - последний вопрос юзера не найден
      notifyListeners();
      return;
    }

    await _streamAssistantReply(convo);
  }

  Future<void> _streamAssistantReply(ChatConversation convo) async {
    final assistantMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      content: '',
      isStreaming: true,
    );
    convo.messages.add(assistantMsg);
    convo.updatedAt = DateTime.now();
    _sendingConversationIds.add(convo.id);
    notifyListeners();

    try {
      final history = convo.messages
          .where((m) => m.id != assistantMsg.id)
          .toList(growable: false);

      // notifyListeners() на каждый токен перестраивал бы дерево виджетов
      // чаще, чем заметно глазу - ограничиваем частоту, финальное
      // состояние долетит через finally ниже
      var lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
      const notifyInterval = Duration(milliseconds: 50);

      await for (final event in _api.sendMessage(
        baseUrl: baseUrl,
        history: history,
        authToken: getAuthToken?.call(),
      )) {
        if (event.error != null) {
          assistantMsg.content += event.error!;
          assistantMsg.isError = true;
          assistantMsg.isStreaming = false;
          if (event.isAuthError) {
            unawaited(onSessionExpired?.call());
          } else {
            backendStatus = BackendStatus.offline;
          }
          break;
        }
        assistantMsg.content += event.token;
        if (event.done) {
          assistantMsg.isStreaming = false;
          if (event.sources != null) assistantMsg.sources = event.sources;
        }
        onAssistantTextChunk?.call(
          messageId: assistantMsg.id,
          fullContent: assistantMsg.content,
          isDone: event.done,
        );
        final now = DateTime.now();
        if (now.difference(lastNotify) >= notifyInterval) {
          lastNotify = now;
          notifyListeners();
        }
      }
    } finally {
      assistantMsg.isStreaming = false;
      _sendingConversationIds.remove(convo.id);
      convo.updatedAt = DateTime.now();
      _reorderActiveToTop();
      await _persist();
      notifyListeners();
    }
  }

  void _reorderActiveToTop() {
    final id = activeConversationId;
    if (id == null) return;
    final idx = conversations.indexWhere((c) => c.id == id);
    if (idx <= 0) return;
    final convo = conversations.removeAt(idx);
    conversations.insert(0, convo);
  }

  Future<void> _persist() => _storage.saveConversations(_userId, conversations);

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
