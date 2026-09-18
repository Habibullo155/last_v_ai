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

/// Сейф - личные записи, реально сохраняются на сервере (строго
/// приватно - см. backend/routers_personal_memories.py). Мысль текстом,
/// фото опционально - раньше фото было обязательной "обложкой", позже
/// переосмыслено: не всегда есть что сфотографировать, а мысль записать
/// хочется. Название "Сейф" вернули - изначально здесь была
/// символическая, НЕ сохраняемая техника "убирания" мысли на потом,
/// затем переименовано в "Мои моменты" под фото-механику, теперь имя
/// вернули обратно при переходе на текст+фото(опционально). При
/// открытии записи - кнопка перейти в чат и обсудить её с ИИ, и кнопка
/// удалить, если запись больше не нужна.
class PersonalMemoriesScreen extends StatefulWidget {
  final AuthStore authStore;
  // передаётся из wellbeing_screen.dart - тот же колбэк, что открывает
  // AI-разговор с готовым текстом сообщения (см. _openDetail ниже)
  final Future<void> Function(String text)? onStartAiConversation;
  const PersonalMemoriesScreen({
    super.key,
    required this.authStore,
    this.onStartAiConversation,
  });

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
      // фото подгружаем в фоне только там, где оно реально есть - не
      // дёргаем /photo для текстовых записей, там гарантированно 404
      for (final memory in memories) {
        if (!memory.hasPhoto || _photoCache.containsKey(memory.id)) continue;
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
    final result = await showDialog<_NewMemoryDraft>(
      context: context,
      builder: (context) => const _AddMemoryDialog(),
    );
    if (result == null || !mounted) return;

    final token = widget.authStore.token;
    if (token == null) return;
    try {
      await _service.create(
        baseUrl: widget.authStore.baseUrl,
        token: token,
        comment: result.comment,
        photoBytes: result.photoBytes,
        filename: result.filename,
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
          onDiscuss: widget.onStartAiConversation == null
              ? null
              : () async {
                  Navigator.of(context).pop();
                  await widget.onStartAiConversation!(
                    'Хочу обсудить одну свою запись из Сейфа: «${memory.comment}»',
                  );
                },
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
              Icons.lock_outline_rounded,
              color: context.onSurfaceFaded(0.3),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Пока пусто — запиши мысль (фото не обязательно), и сможешь вернуться к ней в любой момент.',
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
                  child: memory.hasPhoto
                      ? (photoBytes != null
                            ? Image.memory(
                                photoBytes!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(color: context.onSurfaceFaded(0.06)))
                      : Container(
                          color: context.onSurfaceFaded(0.06),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.notes_rounded,
                            color: context.onSurfaceFaded(0.25),
                            size: 28,
                          ),
                        ),
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
  final Future<void> Function()? onDiscuss;
  final VoidCallback onDelete;
  const _MemoryDetailScreen({
    required this.memory,
    required this.photoBytes,
    required this.onDiscuss,
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
                        if (memory.hasPhoto)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: photoBytes != null
                                ? Image.memory(photoBytes!, fit: BoxFit.cover)
                                : Container(
                                    height: 240,
                                    color: context.onSurfaceFaded(0.06),
                                  ),
                          ),
                        if (memory.hasPhoto) const SizedBox(height: 20),
                        Text(
                          memory.comment,
                          style: TextStyle(
                            color: context.onSurface,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (onDiscuss != null)
                          SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: onDiscuss,
                              icon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 18,
                              ),
                              label: const Text('Обсудить с ИИ'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C5CE7),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
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

class _NewMemoryDraft {
  final String comment;
  final Uint8List? photoBytes;
  final String? filename;
  _NewMemoryDraft({required this.comment, this.photoBytes, this.filename});
}

class _AddMemoryDialog extends StatefulWidget {
  const _AddMemoryDialog();

  @override
  State<_AddMemoryDialog> createState() => _AddMemoryDialogState();
}

class _AddMemoryDialogState extends State<_AddMemoryDialog> {
  final _controller = TextEditingController();
  Uint8List? _photoBytes;
  String? _filename;

  @override
  void initState() {
    super.initState();
    // без этого кнопка "Сохранить" не реагировала бы на ввод текста
    // сама по себе - только при СЛУЧАЙНОЙ перестройке виджета по другой
    // причине (например, после выбора фото)
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photoBytes = bytes;
      _filename = file.name;
    });
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
                hintText: 'О чём хочешь написать?',
                hintStyle: const TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 12),
            // фото опционально - не обязательный элемент записи
            if (_photoBytes != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      _photoBytes!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => setState(() {
                      _photoBytes = null;
                      _filename = null;
                    }),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Colors.white70,
                  size: 18,
                ),
                label: const Text(
                  'Добавить фото (необязательно)',
                  style: TextStyle(color: Colors.white70),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
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
                    onPressed: _controller.text.trim().isEmpty
                        ? null
                        : () => Navigator.of(context).pop(
                            _NewMemoryDraft(
                              comment: _controller.text.trim(),
                              photoBytes: _photoBytes,
                              filename: _filename,
                            ),
                          ),
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
