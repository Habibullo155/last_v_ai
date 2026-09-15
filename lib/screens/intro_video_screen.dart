import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Показывается ОДИН РАЗ при первом запуске приложения на устройстве
/// (флаг в SharedPreferences, не связано с аккаунтом - см. app.dart), до
/// экрана входа. Видео без звука намеренно - веб-браузеры блокируют
/// автовоспроизведение со звуком без явного действия человека, а для
/// анимации логотипа звук не принципиален. Если видео по какой-то
/// причине не загрузится (сбой на конкретной платформе, отсутствующий
/// файл и т.п.) - НЕ блокируем вход в приложение, просто сразу
/// переходим дальше.
class IntroVideoScreen extends StatefulWidget {
  final VoidCallback onDone;
  const IntroVideoScreen({super.key, required this.onDone});

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  VideoPlayerController? _controller;
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.asset('assets/video/intro.mp4');
    try {
      await controller.initialize();
      await controller.setVolume(0);
      controller.addListener(_onTick);
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      await controller.play();
    } catch (_) {
      // не смогли проиграть - не задерживаем человека на пустом экране
      controller.dispose();
      _finish();
    }
  }

  void _onTick() {
    final controller = _controller;
    if (controller == null || _isDone) return;
    final value = controller.value;
    if (value.isInitialized && !value.isPlaying && value.position >= value.duration) {
      _finish();
    }
  }

  void _finish() {
    if (_isDone) return;
    _isDone = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1E),
      body: Stack(
        children: [
          if (controller != null && controller.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: TextButton(
                onPressed: _finish,
                child: const Text('Пропустить', style: TextStyle(color: Colors.white70)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
