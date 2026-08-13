import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glass_panel.dart';

class ChatInputBar extends StatefulWidget {
  final bool enabled;
  final ValueChanged<String> onSend;

  const ChatInputBar({super.key, required this.enabled, required this.onSend});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  // Отдельный узел для перехвата Enter — создаём один раз, а не в build(),
  // иначе на каждой перерисовке плодились бы висячие FocusNode (утечка).
  final _keyboardFocusNode = FocusNode(debugLabel: 'chat-input-keyboard');

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    HapticFeedback.lightImpact();
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      opacity: 0.12,
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: KeyboardListener(
              focusNode: _keyboardFocusNode,
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    !HardwareKeyboard.instance.isShiftPressed) {
                  _submit();
                }
              },
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                minLines: 1,
                maxLines: 6,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: const Color(0xFF00D9C0),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.enabled
                      ? 'Напиши сообщение…'
                      : 'Ожидание ответа модели…',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                ),
              ),
            ),
          ),
          _SendButton(enabled: widget.enabled, onTap: _submit),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _SendButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: enabled
                  ? [const Color(0xFF6C5CE7), const Color(0xFF00D9C0)]
                  : [Colors.white24, Colors.white10],
            ),
          ),
          child: Icon(
            enabled ? Icons.arrow_upward_rounded : Icons.hourglass_top_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
