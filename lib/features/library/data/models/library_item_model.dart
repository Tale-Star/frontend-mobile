import '../../domain/entities/library_item_entity.dart';

/// Modelo DTO para deserializar elementos de biblioteca del backend (`LibraryItemResponse`).
class LibraryItemModel extends LibraryItemEntity {
  const LibraryItemModel({
    required super.id,
    required super.type,
    required super.resourceId,
    required super.name,
    required super.description,
    required super.favorite,
    required super.resourceUrl,
    super.mediaType,
    required super.createdAt,
    required super.updatedAt,
  });

  factory LibraryItemModel.fromJson(Map<String, dynamic> json) {
    return LibraryItemModel(
      id: json['id'] as String,
      type: ContentType.fromString(json['type'] as String),
      resourceId: json['resource_id'] as String,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      favorite: (json['favorite'] as bool?) ?? false,
      resourceUrl: (json['resource_url'] as String?) ?? '',
      mediaType: json['media_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'resource_id': resourceId,
      'name': name,
      'description': description,
      'favorite': favorite,
      'resource_url': resourceUrl,
      'media_type': mediaType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory LibraryItemModel.fromEntity(LibraryItemEntity entity) {
    return LibraryItemModel(
      id: entity.id,
      type: entity.type,
      resourceId: entity.resourceId,
      name: entity.name,
      description: entity.description,
      favorite: entity.favorite,
      resourceUrl: entity.resourceUrl,
      mediaType: entity.mediaType,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

