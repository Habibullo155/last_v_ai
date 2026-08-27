class BlogPostSummary {
  final int id;
  final String title;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final bool hasCoverImage;

  BlogPostSummary({
    required this.id,
    required this.title,
    required this.isPublished,
    required this.createdAt,
    required this.publishedAt,
    required this.hasCoverImage,
  });

  factory BlogPostSummary.fromJson(Map<String, dynamic> json) {
    return BlogPostSummary(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      isPublished: json['is_published'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'] as String) : null,
      hasCoverImage: json['has_cover_image'] as bool? ?? false,
    );
  }
}

class BlogPost {
  final int id;
  final int authorId;
  final String? authorEmail;
  final String title;
  final String content;
  final String? coverImageBase64;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  BlogPost({
    required this.id,
    required this.authorId,
    required this.authorEmail,
    required this.title,
    required this.content,
    required this.coverImageBase64,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    required this.publishedAt,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'] as int,
      authorId: json['author_id'] as int,
      authorEmail: json['author_email'] as String?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      coverImageBase64: json['cover_image_base64'] as String?,
      isPublished: json['is_published'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'] as String) : null,
    );
  }
}
