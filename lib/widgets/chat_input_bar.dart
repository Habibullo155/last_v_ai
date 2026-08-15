import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/voice_store.dart';
import '../theme/app_text_color.dart';
import 'glass_panel.dart';

class ChatInputBar extends StatefulWidget {
  final bool enabled;
  final ValueChanged<String> onSend;
  final VoiceStore? voiceStore;

  const ChatInputBar({super.key, required this.enabled, required this.onSend, this.voiceStore});

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

  Future<void> _toggleListening() async {
    final voice = widget.voiceStore;
    if (voice == null) return;
    if (voice.isListening) {
      await voice.stopListening();
      return;
    }
    HapticFeedback.lightImpact();
    await voice.startListening(
      onResult: (text) {
        _controller.text = text;
        _controller.selection = TextSelection.collapsed(offset: text.length);
      },
    );
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
    final voice = widget.voiceStore;
    final showMic = voice != null && voice.isVoiceAvailable && voice.isSttAvailable;

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
                style: TextStyle(color: context.onSurface, fontSize: 15),
                cursorColor: const Color(0xFF00D9C0),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.enabled
                      ? 'Напиши сообщение…'
                      : 'Ожидание ответа модели…',
                  hintStyle: TextStyle(color: context.onSurfaceFaded(0.4)),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                ),
              ),
            ),
          ),
          if (showMic) ...[
            AnimatedBuilder(
              animation: voice,
              builder: (context, _) => _MicButton(
                isListening: voice.isListening,
                enabled: widget.enabled,
                onTap: _toggleListening,
              ),
            ),
            const SizedBox(width: 6),
          ],
          _SendButton(enabled: widget.enabled, onTap: _submit),
        ],
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool isListening;
  final bool enabled;
  final VoidCallback onTap;
  const _MicButton({required this.isListening, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isListening ? const Color(0xFFFF6B6B).withOpacity(0.25) : context.onSurfaceFaded(0.06),
          ),
          child: Icon(
            isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
            color: isListening ? const Color(0xFFFF6B6B) : context.onSurfaceFaded(0.7),
            size: 20,
          ),
        ),
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
                  : [context.onSurfaceFaded(0.24), context.onSurfaceFaded(0.10)],
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
