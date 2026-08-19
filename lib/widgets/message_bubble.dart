import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../theme/app_text_color.dart';
import 'animated_ai_avatar.dart';
import 'glass_panel.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onSpeak;
  final ValueChanged<String>? onEdit;
  final ValueChanged<bool>? onRate;
  final VoidCallback? onRegenerate;
  const MessageBubble({
    super.key,
    required this.message,
    this.onDelete,
    this.onReport,
    this.onSpeak,
    this.onEdit,
    this.onRate,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final time = DateFormat.Hm().format(message.createdAt);

    final bubble = GlassPanel(
      opacity: isUser ? 0.16 : 0.09,
      tint: isUser ? const Color(0xFF6C5CE7) : null,
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
            if (message.content.isNotEmpty)
              SelectableText(
                message.content,
                style: TextStyle(
                  color: message.isError
                      ? const Color(0xFFFFB4B4)
                      : context.onSurfaceFaded(0.94),
                  fontSize: 15.5,
                  height: 1.45,
                ),
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: context.onSurfaceFaded(0.38),
                    fontSize: 11,
                  ),
                ),
                if (!message.isStreaming) ...[
                  const SizedBox(width: 8),
                  _CopyIconButton(text: message.content),
                  if (onRate != null) ...[
                    const SizedBox(width: 4),
                    _RateIconButton(
                      icon: Icons.thumb_up_outlined,
                      activeIcon: Icons.thumb_up_rounded,
                      active: message.liked == true,
                      onTap: () => onRate!(true),
                    ),
                    const SizedBox(width: 2),
                    _RateIconButton(
                      icon: Icons.thumb_down_outlined,
                      activeIcon: Icons.thumb_down_rounded,
                      active: message.liked == false,
                      onTap: () => onRate!(false),
                    ),
                  ],
                  if (onRegenerate != null) ...[
                    const SizedBox(width: 2),
                    _RateIconButton(
                      icon: Icons.refresh_rounded,
                      activeIcon: Icons.refresh_rounded,
                      active: false,
                      onTap: onRegenerate!,
                    ),
                  ],
                ],
              ],
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
          if (!isUser) _avatar(context, isUser: false),
          if (!isUser) const SizedBox(width: 8),
          Flexible(child: bubbleWithGestures),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _avatar(context, isUser: true),
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
        // Меню бэкграунд намеренно всегда тёмный (Color(0xFF1A2036) выше) —
        // как модальный лист поверх всего, читаемость текста внутри него
        // от темы приложения не зависит, поэтому здесь спокойно оставляем
        // белый текст константами — это не тот случай, что бьётся о
        // светлую тему (сам лист остаётся тёмным в обоих режимах).
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.white70),
                title: const Text('Редактировать и переспросить', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditDialog(context);
                },
              ),
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

  Future<void> _showEditDialog(BuildContext context) async {
    final controller = TextEditingController(text: message.content);
    await showDialog(
      context: context,
      // Диалог редактирования — тоже отдельный "тёмный лист" поверх
      // приложения (как и меню выше), не основная поверхность экрана,
      // поэтому внутренний текст здесь тоже намеренно на тёмном фоне
      // независимо от темы приложения.
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassPanel(
          tint: const Color(0xFF1A2036),
          opacity: 0.95,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Редактировать сообщение',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ответ модели на это сообщение и всё, что было после, будет удалено — модель ответит заново на исправленный текст.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 6,
                  minLines: 1,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Отмена', style: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                      onPressed: () {
                        final text = controller.text.trim();
                        Navigator.of(context).pop();
                        if (text.isNotEmpty && text != message.content) {
                          onEdit?.call(text);
                        }
                      },
                      child: const Text('Переспросить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatar(BuildContext context, {required bool isUser}) {
    if (!isUser && message.isStreaming) {
      return AnimatedAiAvatar(isActive: true, size: 34);
    }
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isUser
              ? [const Color(0xFF6C5CE7), const Color(0xFF00D9C0)]
              // Спокойные приглушённые сине-зелёные тона вместо резкого
              // розово-фиолетового — и значок волны/дыхания вместо "искр",
              // это осознанный выбор именно для образа ассистента.
              : [const Color(0xFF6FB1DE), const Color(0xFF4DD0C4)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.spa_rounded,
        size: 18,
        color: Colors.white,
      ),
    );
  }
}

/// Раньше копирование было только в скрытом меню по долгому нажатию —
/// оказалось недостаточно заметно. Теперь есть ещё и видимая маленькая
/// иконка прямо в пузыре, рядом со временем.
class _CopyIconButton extends StatelessWidget {
  final String text;
  const _CopyIconButton({required this.text});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: text));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Скопировано'), duration: Duration(seconds: 1)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(Icons.copy_rounded, size: 13, color: context.onSurfaceFaded(0.38)),
        ),
      ),
    );
  }
}

/// Маленькая иконка-кнопка для лайка/дизлайка/перегенерации — рядом с
/// иконкой копирования, а не спрятана в меню и не отдельным рядом под
/// всем списком сообщений.
class _RateIconButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final VoidCallback onTap;
  const _RateIconButton({
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            active ? activeIcon : icon,
            size: 13,
            color: active ? const Color(0xFF6C5CE7) : context.onSurfaceFaded(0.38),
          ),
        ),
      ),
    );
  }
}
