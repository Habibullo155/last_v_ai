import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/blog_post.dart';
import '../services/blog_service.dart';
import '../state/auth_store.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';

class BlogPostScreen extends StatefulWidget {
  final AuthStore authStore;
  final int postId;
  const BlogPostScreen({super.key, required this.authStore, required this.postId});

  @override
  State<BlogPostScreen> createState() => _BlogPostScreenState();
}

class _BlogPostScreenState extends State<BlogPostScreen> {
  final _service = BlogService();
  BlogPost? _post;
  bool _isLoading = true;
  String? _error;

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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final post = await _service.getPost(baseUrl: widget.authStore.baseUrl, token: token, postId: widget.postId);
      if (mounted) setState(() => _post = post);
    } on BlogException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                    const Text(
                      'Пост',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Color(0xFF6C5CE7))
                      : _error != null
                          ? Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4)))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 640),
                                child: _buildContent(_post!),
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

  Widget _buildContent(BlogPost post) {
    return GlassPanel(
      opacity: 0.08,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.coverImageBase64 != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(base64Decode(post.coverImageBase64!), fit: BoxFit.cover, width: double.infinity, height: 200),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            post.title,
            style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700, height: 1.3),
          ),
          const SizedBox(height: 8),
          if (post.publishedAt != null)
            Text(
              DateFormat.yMMMMd().format(post.publishedAt!),
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12.5),
            ),
          const SizedBox(height: 18),
          SelectableText(
            post.content,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15.5, height: 1.6),
          ),
        ],
      ),
    );
  }
}
