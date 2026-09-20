import 'dart:convert';

import '../models/chat_conversation.dart';
import 'encrypted_storage.dart';

/// Локальное хранение истории чатов на устройстве (без бэкенда).
/// История привязана к конкретному пользователю (userId), чтобы на одном
/// устройстве разные аккаунты не видели историю друг друга.
///
/// Данные шифруются перед сохранением (см. encrypted_storage.dart) - это
/// личная переписка о своих переживаниях, хранить её чистым текстом на
/// диске неприемлемо.
class StorageService {
  String _keyFor(String userId) => 'conversations_v1_$userId';

  Future<List<ChatConversation>> loadConversations(String userId) async {
    try {
      final raw = await EncryptedStorage.getString(_keyFor(userId));
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Повреждённые данные или недоступное хранилище — не роняем приложение,
      // просто стартуем с чистой историей.
      return [];
    }
  }

  /// Возвращает false вместо исключения, если сохранить не удалось —
  /// это best-effort операция, она не должна ронять вызывающий код.
  Future<bool> saveConversations(String userId, List<ChatConversation> conversations) async {
    try {
      final raw = jsonEncode(conversations.map((c) => c.toJson()).toList());
      await EncryptedStorage.setString(_keyFor(userId), raw);
      return true;
    } catch (_) {
      return false;
    }
  }
}
