import '../../domain/entities/user_entity.dart';

/// Modelo DTO para deserialización de respuestas de usuario del backend (`UserResponse`).
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.displayName,
    required super.pinConfigured,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      pinConfigured: (json['parental_pin_configured'] as bool?) ??
          (json['pin_configured'] as bool?) ??
          false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'pin_configured': pinConfigured,
      'parental_pin_configured': pinConfigured,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      pinConfigured: entity.pinConfigured,
      createdAt: entity.createdAt,
    );
  }
}

