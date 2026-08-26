import 'chat_source.dart';

enum MessageRole { user, assistant, system }

/// null — не оценено, true — лайк, false — дизлайк.
class ChatMessage {
  final String id;
  final MessageRole role;
  String content;
  final DateTime createdAt;
  bool isStreaming;
  bool isError;
  bool? liked;
  // Источники из загруженных документов (RAG) — заполняется только для
  // админа, сервер сам решает, присылать ли это поле вообще (см.
  // chat_api_service.dart). Не сохраняется между сессиями — это просто
  // отображение "откуда взят этот конкретный ответ прямо сейчас".
  List<ChatSource>? sources;
  // Прикреплённые фото — base64 (без префикса data:), уже сжатые при
  // выборе (ChatInputBar: maxWidth/imageQuality), чтобы не раздувать
  // локальное хранилище истории чатов. В отличие от sources — реальный
  // контент пользователя, сохраняется вместе с остальным сообщением.
  List<String>? images;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    DateTime? createdAt,
    this.isStreaming = false,
    this.isError = false,
    this.liked,
    this.sources,
    this.images,
  }) : createdAt = createdAt ?? DateTime.now();

  String get roleKey => switch (role) {
        MessageRole.user => 'user',
        MessageRole.assistant => 'assistant',
        MessageRole.system => 'system',
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': roleKey,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'liked': liked,
        'images': images,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String? ?? 'user';
    final role = MessageRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => MessageRole.user,
    );
    return ChatMessage(
      id: json['id'] as String,
      role: role,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      liked: json['liked'] as bool?,
      images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }
}
