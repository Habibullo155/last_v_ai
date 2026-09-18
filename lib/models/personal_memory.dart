/// Личная запись (Сейф) - текстовая мысль, фото опционально.
/// Сама фотография не хранится в этой модели - только метаданные,
/// сам файл отдаётся отдельным запросом (services/personal_memory_service.dart).
class PersonalMemory {
  final int id;
  final String comment;
  final DateTime createdAt;
  final bool hasPhoto;

  PersonalMemory({required this.id, required this.comment, required this.createdAt, required this.hasPhoto});

  factory PersonalMemory.fromJson(Map<String, dynamic> json) => PersonalMemory(
    id: json['id'] as int,
    comment: json['comment'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    hasPhoto: json['has_photo'] as bool? ?? false,
  );
}
