import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:ai_last_v/l10n/app_localizations.dart';
import '../models/personal_memory.dart';
import '../services/personal_memory_service.dart';
import '../state/auth_store.dart';
import '../theme/app_text_color.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

/// Личные записи - фото (обложка/заголовок) + текстовый комментарий,
/// реально сохраняются на сервере (строго приватно, только свои видны -
/// см. backend/routers_personal_memories.py) и доступны для просмотра
/// снова в любой момент. ИИ иногда (не каждый раз) вскользь напоминает
/// о них в чате - см. personal_memory_reminder_for_prompt на бэкенде.
///
/// Раньше на этом месте была техника "Сейф" (контейнирование) -
/// символическое, НАРОЧНО не сохраняемое "убирание" мысли на потом.
/// Заменено полностью, не доработано поверх старого: разное назначение,
/// разная механика.
class PersonalMemoriesScreen extends StatefulWidget {
  final AuthStore authStore;
  const PersonalMemoriesScreen({super.key, required this.authStore});

  @override
  State<PersonalMemoriesScreen> createState() => _PersonalMemoriesScreenState();
}

class _PersonalMemoriesScreenState extends State<PersonalMemoriesScreen> {
  final _service = PersonalMemoryService();
  List<PersonalMemory>? _memories;
  String? _error;
  // photoBytes кэшируются по id - иначе каждая пересборка списка
  // заново скачивала бы все фото с сервера
  final Map<int, Uint8List> _photoCache = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = widget.authStore.token;
    if (token == null) return;
    try {
      final memories = await _service.list(
        baseUrl: widget.authStore.baseUrl,
        token: token,
      );
      if (!mounted) return;
      setState(() {
        _memories = memories;
        _error = null;
      });
      // фото подгружаем в фоне, не блокируя показ списка карточек
      for (final memory in memories) {
        if (_photoCache.containsKey(memory.id)) continue;
        _service
            .fetchPhotoBytes(
              baseUrl: widget.authStore.baseUrl,
              token: token,
              memoryId: memory.id,
            )
            .then((bytes) {
              if (mounted) setState(() => _photoCache[memory.id] = bytes);
            })
            .catchError((_) {
              // одно недогрузившееся фото не должно ронять весь список
            });
      }
    } on PersonalMemoryException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Не удалось загрузить записи — проверь соединение с сервером.',
        );
      }
    }
  }

  Future<void> _addMemory() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;

    final comment = await showDialog<String>(
      context: context,
      builder: (context) => _CommentDialog(previewBytes: bytes),
    );
    if (comment == null || comment.trim().isEmpty || !mounted) return;

    final token = widget.authStore.token;
    if (token == null) return;
    try {
      await _service.create(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        comment: comment.trim(),
        photoBytes: bytes,
        filename: file.name,
      );
      await _load();
    } on PersonalMemoryException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Не удалось сохранить запись — проверь соединение с сервером.',
        );
      }
    }
  }

  Future<void> _delete(PersonalMemory memory) async {
    final token = widget.authStore.token;
    if (token == null) return;
    try {
      await _service.delete(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        memoryId: memory.id,
      );
      _photoCache.remove(memory.id);
      await _load();
    } on PersonalMemoryException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Не удалось удалить запись — проверь соединение с сервером.',
        );
      }
    }
  }

  void _openDetail(PersonalMemory memory) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MemoryDetailScreen(
          memory: memory,
          photoBytes: _photoCache[memory.id],
          onDelete: () async {
            Navigator.of(context).pop();
            await _delete(memory);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final memories = _memories;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.adaptive.arrow_back,
                        color: context.onSurface,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        l10n.wellbeingSafeTitle,
                        style: TextStyle(
                          color: context.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_rounded,
                        color: Color(0xFF6C5CE7),
                        size: 28,
                      ),
                      onPressed: _addMemory,
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFFFB4B4),
                      fontSize: 13,
                    ),
                  ),
                ),
              Expanded(
                child: memories == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C5CE7),
                        ),
                      )
                    : memories.isEmpty
                    ? _buildEmpty(context)
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                        itemCount: memories.length,
                        itemBuilder: (context, i) => _MemoryCard(
                          memory: memories[i],
                          photoBytes: _photoCache[memories[i].id],
                          onTap: () => _openDetail(memories[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: context.onSurfaceFaded(0.3),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Пока пусто — сохрани фото с комментарием, и сможешь вернуться к нему в любой момент.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.onSurfaceFaded(0.6),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final PersonalMemory memory;
  final Uint8List? photoBytes;
  final VoidCallback onTap;
  const _MemoryCard({
    required this.memory,
    required this.photoBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: GlassPanel(
          opacity: 0.08,
          borderRadius: BorderRadius.circular(16),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: photoBytes != null
                      ? Image.memory(
                          photoBytes!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(color: context.onSurfaceFaded(0.06)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  memory.comment,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.onSurface, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoryDetailScreen extends StatelessWidget {
  final PersonalMemory memory;
  final Uint8List? photoBytes;
  final VoidCallback onDelete;
  const _MemoryDetailScreen({
    required this.memory,
    required this.photoBytes,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.adaptive.arrow_back,
                        color: context.onSurface,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFFF6B6B),
                      ),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: photoBytes != null
                              ? Image.memory(photoBytes!, fit: BoxFit.cover)
                              : Container(
                                  height: 240,
                                  color: context.onSurfaceFaded(0.06),
                                ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          memory.comment,
                          style: TextStyle(
                            color: context.onSurface,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentDialog extends StatefulWidget {
  final Uint8List previewBytes;
  const _CommentDialog({required this.previewBytes});

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A2036),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      // фон листа всегда тёмный, текст константами белый - от темы
      // приложения не зависит (тот же приём, что и у других диалогов в
      // проекте, см. message_bubble.dart)
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                widget.previewBytes,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'О чём этот момент?',
                hintStyle: const TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Отмена',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
