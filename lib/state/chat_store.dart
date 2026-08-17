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
  /// [getAuthToken] и [onSessionExpired] передаются через конструктор, а не
  /// выставляются полями после создания (как было раньше через каскад
  /// `..getAuthToken = ...`) — так их обязательность видна прямо в сигнатуре
  /// и их нельзя случайно забыть подключить в каком-то другом месте кода.
  ChatStore({this.getAuthToken, this.onSessionExpired});

  final StorageService _storage = StorageService();
  final ChatApiService _api = ChatApiService();

  /// Адрес бэкенда задаётся один раз при сборке приложения через
  /// --dart-define=BACKEND_URL=... (см. lib/config.dart) — как .env для
  /// бэкенда, только на этапе компиляции, а не в рантайме. Раньше в
  /// приложении была кнопка сменить адрес прямо на экране — убрали: обычный
  /// пользователь не должен иметь возможность произвольно перенаправить
  /// приложение на чужой сервер.
  final String baseUrl = AppConfig.backendUrl;

  final List<ChatConversation> conversations = [];
  String? activeConversationId;
  BackendStatus backendStatus = BackendStatus.unknown;

  /// ID чатов, для которых ПРЯМО СЕЙЧАС идёт генерация ответа. Раньше здесь
  /// было одно глобальное поле isSending: пока ИИ отвечал в одном чате,
  /// поле ввода блокировалось во ВСЕХ чатах — переключиться и написать в
  /// другой было невозможно, хотя генерация там даже не начиналась. Теперь
  /// это набор конкретных id, и запросы к разным чатам идут независимо и
  /// могут выполняться параллельно.
  final Set<String> _sendingConversationIds = {};

  /// Отправляется ли сообщение в ТЕКУЩЕМ активном чате — используется для
  /// блокировки поля ввода на экране. Не показывает состояние других чатов.
  bool get isSending =>
      activeConversationId != null && _sendingConversationIds.contains(activeConversationId);

  /// В отличие от [isSending] (только активный чат) — проверяет ЛЮБОЙ чат
  /// по id, используется в сайдбаре, чтобы показать, что конкретный чат
  /// ещё генерирует ответ, даже если сейчас открыт другой.
  bool isSendingIn(String conversationId) => _sendingConversationIds.contains(conversationId);

  /// Store не хранит токен сам — его источник правды AuthStore. ChatScreen
  /// подставляет сюда функцию, возвращающую актуальный токен на момент
  /// каждого запроса (токен может обновиться/протухнуть между вызовами).
  final String? Function()? getAuthToken;

  /// Вызывается, если сервер ответил 401 (сессия истекла/недействительна) —
  /// UI-слой должен разлогинить пользователя.
  final Future<void> Function()? onSessionExpired;

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
      // loadConversations уже сама не бросает исключений — это подстраховка
      // на случай непредвиденной ошибки, чтобы приложение не зависло на
      // экране загрузки навсегда.
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
    // Если уже есть пустой чат — просто переключаемся на него.
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

  /// Пользователь сам переименовывает чат — иначе название всегда берётся
  /// из первого сообщения и никогда не меняется.
  void renameConversation(String id, String newTitle) {
    final title = newTitle.trim();
    if (title.isEmpty) return;
    final convo = conversations.where((c) => c.id == id).cast<ChatConversation?>().firstOrNull;
    if (convo == null) return;
    convo.title = title;
    unawaited(_persist());
    notifyListeners();
  }

  /// Удаляет одно сообщение из активного чата (например, случайно
  /// отправленное или неудачный ответ, который не хочется хранить).
  void deleteMessage(String messageId) {
    final convo = active;
    if (convo == null) return;
    convo.messages.removeWhere((m) => m.id == messageId);
    unawaited(_persist());
    notifyListeners();
  }

  /// Ставит/снимает лайк-дизлайк на ответ. Повторный тап по уже
  /// выставленной оценке снимает её (toggle), а не переключает на
  /// противоположную — так интуитивнее.
  void rateMessage(String messageId, bool liked) {
    final convo = active;
    if (convo == null) return;
    final message = convo.messages.where((m) => m.id == messageId).firstOrNull;
    if (message == null) return;
    message.liked = message.liked == liked ? null : liked;
    unawaited(_persist());
    notifyListeners();
  }

  /// Редактирует своё же отправленное сообщение и переспрашивает заново —
  /// как в ChatGPT/Gemini: всё, что шло ПОСЛЕ отредактированного сообщения
  /// (включая старый ответ модели на него), удаляется, а на его месте
  /// генерируется новый ответ на исправленный текст.
  Future<void> editAndResend(String messageId, String newText) async {
    final convo = active;
    if (convo == null || newText.trim().isEmpty || _sendingConversationIds.contains(convo.id)) return;

    final index = convo.messages.indexWhere((m) => m.id == messageId);
    if (index == -1 || convo.messages[index].role != MessageRole.user) return;

    // Обрезаем всё начиная с редактируемого сообщения (включительно) —
    // дальше sendMessage() добавит новое пользовательское сообщение и
    // сгенерирует свежий ответ, как на обычную отправку.
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

  /// Перегенерировать последний ответ модели — убирает предыдущий ответ
  /// (если он есть) и запрашивает новый на ту же историю сообщений, без
  /// повторной отправки вопроса пользователем.
  Future<void> regenerateLastResponse() async {
    final convo = active;
    if (convo == null || _sendingConversationIds.contains(convo.id) || convo.messages.isEmpty) return;

    if (convo.messages.last.role == MessageRole.assistant) {
      convo.messages.removeLast();
    }
    if (convo.messages.isEmpty || convo.messages.last.role != MessageRole.user) {
      // Нечего перегенерировать — последний вопрос пользователя не найден.
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

      // При быстрой генерации токенов (или на медленном устройстве) вызов
      // notifyListeners() на КАЖДЫЙ токен означает перестройку всего дерева
      // виджетов чата чаще, чем это вообще заметно глазу. Ограничиваем
      // частоту — конечное состояние всё равно гарантированно долетит до
      // экрана через notifyListeners() в блоке finally ниже.
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
        }
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
