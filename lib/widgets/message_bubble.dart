import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import 'glass_panel.dart';
import 'typing_dots.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onSpeak;
  const MessageBubble({
    super.key,
    required this.message,
    this.onDelete,
    this.onReport,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final time = DateFormat.Hm().format(message.createdAt);

    final bubble = GlassPanel(
      opacity: isUser ? 0.16 : 0.09,
      tint: isUser ? const Color(0xFF6C5CE7) : Colors.white,
      // Пузыри рендерятся по одному на каждое сообщение в прокручиваемом
      // списке — реальное размытие фона (BackdropFilter) тут дорого
      // масштабируется с числом видимых сообщений. Полупрозрачная заливка
      // и обводка сохраняют ощущение "стекла" почти бесплатно.
      blurred: false,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: Radius.circular(isUser ? 20 : 4),
        bottomRight: Radius.circular(isUser ? 4 : 20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.isStreaming && message.content.isEmpty)
              const TypingDots()
            else
              SelectableText(
                message.content,
                style: TextStyle(
                  color: message.isError
                      ? const Color(0xFFFFB4B4)
                      : Colors.white.withOpacity(0.94),
                  fontSize: 15.5,
                  height: 1.45,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              time,
              style: TextStyle(
                color: Colors.white.withOpacity(0.38),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );

    final hasMenu = !message.isStreaming;
    final bubbleWithGestures = !hasMenu
        ? bubble
        : GestureDetector(
            onLongPress: () => _showMessageMenu(context),
            child: bubble,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _avatar(isUser: false),
          if (!isUser) const SizedBox(width: 8),
          Flexible(child: bubbleWithGestures),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _avatar(isUser: true),
        ],
      ),
    );
  }

  void _showMessageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2036),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Colors.white70),
              title: const Text('Скопировать текст', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.of(context).pop();
                await Clipboard.setData(ClipboardData(text: message.content));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Скопировано'), duration: Duration(seconds: 1)),
                  );
                }
              },
            ),
            if (onSpeak != null)
              ListTile(
                leading: const Icon(Icons.volume_up_rounded, color: Colors.white70),
                title: const Text('Прочитать вслух', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  onSpeak?.call();
                },
              ),
            if (onReport != null)
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Color(0xFFFFD166)),
                title: const Text('Пожаловаться на ответ', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  onReport?.call();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFFB4B4)),
                title: const Text('Удалить сообщение', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  onDelete?.call();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatar({required bool isUser}) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isUser
              ? [const Color(0xFF6C5CE7), const Color(0xFF00D9C0)]
              : [const Color(0xFFFF7AC6), const Color(0xFF6C5CE7)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
        size: 18,
        color: Colors.white,
      ),
    );
  }
}
