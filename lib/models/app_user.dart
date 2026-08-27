class AppUser {
  final int id;
  final String email;
  final String role; // "user" | "admin"
  final String tariff;
  final bool isActive;
  final DateTime createdAt;
  final String? fullName;
  final int? age;
  final String? hobbies;
  final String? avatarBase64;
  final bool isOperator;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.tariff,
    required this.isActive,
    required this.createdAt,
    this.fullName,
    this.age,
    this.hobbies,
    this.avatarBase64,
    this.isOperator = false,
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'user',
      tariff: json['tariff'] as String? ?? 'free',
      isActive: json['is_active'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      fullName: json['full_name'] as String?,
      age: json['age'] as int?,
      hobbies: json['hobbies'] as String?,
      avatarBase64: json['avatar_base64'] as String?,
      isOperator: json['is_operator'] as bool? ?? false,
    );
  }
}
