import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ai_last_v/l10n/app_localizations.dart';
import '../models/blog_post.dart';
import '../services/blog_service.dart';
import '../state/auth_store.dart';
import '../theme/app_text_color.dart';
import '../utils/concurrency.dart';
import '../utils/lru_cache.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_panel.dart';
import 'blog_post_screen.dart';

class BlogListScreen extends StatefulWidget {
  final AuthStore authStore;
  const BlogListScreen({super.key, required this.authStore});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  final _service = BlogService();
  List<BlogPostSummary> _posts = [];
  bool _isLoading = true;
  String? _error;
  // обложки кэшируются по id поста - подгружаются в фоне, не блокируя
  // показ самого списка (текст+лайки видны сразу, фото появляется следом)
  // ограничен по размеру (LruCache) - раньше обычный Map копил обложки
  // постов навсегда без вытеснения, что при просмотре длинной ленты
  // блога гарантированно привело бы к OOM
  final _coverCache = LruCache<int, Uint8List>(maxEntries: 60);

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
      final posts = await _service.listPublishedPosts(
        baseUrl: widget.authStore.baseUrl,
        token: token,
      );
      if (mounted) setState(() => _posts = posts);
      // не более 4 одновременных загрузок обложек (runWithConcurrencyLimit) -
      // раньше запускался отдельный запрос НА КАЖДЫЙ пост сразу
      final toFetch = posts
          .where((p) => p.hasCoverImage && !_coverCache.containsKey(p.id))
          .toList();
      unawaited(
        runWithConcurrencyLimit(toFetch, 4, (post) async {
          try {
            final bytes = await _service.fetchCoverBytes(
              baseUrl: widget.authStore.baseUrl,
              token: token,
              postId: post.id,
            );
            if (mounted) setState(() => _coverCache.put(post.id, bytes));
          } catch (_) {
            // одна недогрузившаяся обложка не должна ронять весь список
          }
        }),
      );
    } on BlogException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                    Text(
                      l10n.blogTitle,
                      style: TextStyle(
                        color: context.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF6C5CE7),
                            ),
                          )
                        : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Color(0xFFFFB4B4)),
                            ),
                          )
                        : _posts.isEmpty
                        ? Center(
                            child: Text(
                              l10n.blogListEmpty,
                              style: TextStyle(
                                color: context.onSurfaceFaded(0.4),
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 560,
                                  ),
                                  child: Column(
                                    children: _posts
                                        .map(
                                          (p) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 18,
                                            ),
                                            child: _PostCard(
                                              post: p,
                                              coverBytes: _coverCache.get(p.id),
                                              onTap: () =>
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          BlogPostScreen(
                                                            authStore: widget
                                                                .authStore,
                                                            postId: p.id,
                                                          ),
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
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

/// Карточка поста в духе Instagram - фото во всю ширину сверху (если
/// у поста есть обложка), заголовок+короткое превью текста под ним,
/// лайки/комментарии внизу. Раньше карточка была чисто текстовой
/// строкой без фото вообще - теперь фото это главный, первый элемент,
/// на который падает взгляд, как в настоящей ленте.
class _PostCard extends StatelessWidget {
  final BlogPostSummary post;
  final Uint8List? coverBytes;
  final VoidCallback onTap;
  const _PostCard({
    required this.post,
    required this.coverBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: GlassPanel(
          opacity: 0.08,
          borderRadius: BorderRadius.circular(18),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.hasCoverImage)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: coverBytes != null
                        ? Image.memory(
                            coverBytes!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: context.onSurfaceFaded(0.06),
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF6C5CE7),
                            ),
                          ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: TextStyle(
                        color: context.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (post.excerpt.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        post.excerpt,
                        style: TextStyle(
                          color: context.onSurfaceFaded(0.6),
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          size: 15,
                          color: context.onSurfaceFaded(0.4),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${post.likeCount}',
                          style: TextStyle(
                            color: context.onSurfaceFaded(0.45),
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Icon(
                          Icons.chat_bubble_rounded,
                          size: 14,
                          color: context.onSurfaceFaded(0.4),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${post.commentCount}',
                          style: TextStyle(
                            color: context.onSurfaceFaded(0.45),
                            fontSize: 12.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          post.publishedAt != null
                              ? DateFormat.yMMMd().format(post.publishedAt!)
                              : '',
                          style: TextStyle(
                            color: context.onSurfaceFaded(0.35),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
