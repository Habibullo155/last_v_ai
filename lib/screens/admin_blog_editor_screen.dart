import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/blog_service.dart';
import '../state/auth_store.dart';
import '../widgets/app_background.dart';

/// null postId — создание нового поста, иначе — редактирование
/// существующего (загружаем текущее содержимое перед показом формы).
class AdminBlogEditorScreen extends StatefulWidget {
  final AuthStore authStore;
  final int? postId;
  const AdminBlogEditorScreen({super.key, required this.authStore, this.postId});

  @override
  State<AdminBlogEditorScreen> createState() => _AdminBlogEditorScreenState();
}

class _AdminBlogEditorScreenState extends State<AdminBlogEditorScreen> {
  final _service = BlogService();
  final _picker = ImagePicker();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _coverImageBase64;
  bool _isPublished = false;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.postId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _load();
  }

  @override
  void dispose() {
    _service.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = widget.authStore.token;
    if (token == null) return;
    setState(() => _isLoading = true);
    try {
      final post = await _service.adminGetPost(baseUrl: widget.authStore.baseUrl, token: token, postId: widget.postId!);
      if (!mounted) return;
      _titleController.text = post.title;
      _contentController.text = post.content;
      setState(() {
        _coverImageBase64 = post.coverImageBase64;
        _isPublished = post.isPublished;
      });
    } on BlogException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickCoverImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A2036),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: Colors.white),
                title: const Text('Сделать фото', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.white),
                title: const Text('Выбрать из галереи', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              if (_coverImageBase64 != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF6B6B)),
                  title: const Text('Убрать обложку', style: TextStyle(color: Color(0xFFFF6B6B))),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _coverImageBase64 = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    // компактнее аватара, но всё равно сжимаем сразу при выборе - тот же
    // приём, что и везде в этом приложении, не раздувать пост несжатым
    // фото с камеры
    final file = await _picker.pickImage(source: source, maxWidth: 1200, maxHeight: 800, imageQuality: 75);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _coverImageBase64 = base64Encode(bytes));
  }

  Future<void> _save({required bool publish}) async {
    final token = widget.authStore.token;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (token == null || title.isEmpty || content.isEmpty) {
      setState(() => _error = 'Заполни заголовок и текст поста.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      if (_isEditing) {
        await _service.updatePost(
          baseUrl: widget.authStore.baseUrl,
          token: token,
          postId: widget.postId!,
          title: title,
          content: content,
          coverImageBase64: _coverImageBase64,
          clearCoverImage: _coverImageBase64 == null,
          isPublished: publish,
        );
      } else {
        await _service.createPost(
          baseUrl: widget.authStore.baseUrl,
          token: token,
          title: title,
          content: content,
          coverImageBase64: _coverImageBase64,
          isPublished: publish,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on BlogException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      _isEditing ? 'Редактировать пост' : 'Новый пост',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Color(0xFF6C5CE7))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_error != null) ...[
                                  Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 13)),
                                  const SizedBox(height: 12),
                                ],
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: _pickCoverImage,
                                    child: _coverImageBase64 != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(14),
                                            child: Image.memory(
                                              base64Decode(_coverImageBase64!),
                                              height: 160,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Container(
                                            height: 120,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(14),
                                              color: Colors.white.withOpacity(0.06),
                                              border: Border.all(color: Colors.white.withOpacity(0.12)),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.add_photo_alternate_outlined, color: Colors.white.withOpacity(0.5)),
                                                const SizedBox(height: 6),
                                                Text('Добавить обложку (необязательно)', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12.5)),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _titleController,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.07),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    hintText: 'Заголовок поста',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _contentController,
                                  minLines: 10,
                                  maxLines: 30,
                                  style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.5),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.07),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.all(14),
                                    hintText: 'Текст поста…',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                          padding: const EdgeInsets.symmetric(vertical: 13),
                                        ),
                                        onPressed: _isSaving ? null : () => _save(publish: false),
                                        child: Text(
                                          'Сохранить черновик',
                                          style: TextStyle(color: Colors.white.withOpacity(0.85)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(14),
                                          onTap: _isSaving ? null : () => _save(publish: true),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 13),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(14),
                                              gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00B4D8)]),
                                            ),
                                            child: _isSaving
                                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                : Text(
                                                    _isPublished ? 'Сохранить' : 'Опубликовать',
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
