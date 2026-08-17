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

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    DateTime? createdAt,
    this.isStreaming = false,
    this.isError = false,
    this.liked,
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
    );
  }
}
