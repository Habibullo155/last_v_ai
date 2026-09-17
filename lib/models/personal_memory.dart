/// Личная запись - фото (обложка/заголовок) + текстовый комментарий.
/// Сама фотография не хранится в этой модели - только метаданные,
/// сам файл отдаётся отдельным запросом (services/personal_memory_service.dart).
class PersonalMemory {
  final int id;
  final String comment;
  final DateTime createdAt;

  PersonalMemory({required this.id, required this.comment, required this.createdAt});

  factory PersonalMemory.fromJson(Map<String, dynamic> json) => PersonalMemory(
    id: json['id'] as int,
    comment: json['comment'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
