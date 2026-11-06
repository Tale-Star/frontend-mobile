import 'package:equatable/equatable.dart';

/// Tipos de contenido oficiales administrados en la Biblioteca Tale Star.
enum ContentType {
  image,
  story,
  music;

  static ContentType fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'image':
        return ContentType.image;
      case 'story':
        return ContentType.story;
      case 'music':
        return ContentType.music;
      default:
        throw ArgumentError('Tipo de contenido desconocido: $value');
    }
  }

  static ContentType? tryFromString(String? value) {
    if (value == null) return null;
    try {
      return fromString(value);
    } catch (_) {
      return null;
    }
  }

  String get value {
    switch (this) {
      case ContentType.image:
        return 'image';
      case ContentType.story:
        return 'story';
      case ContentType.music:
        return 'music';
    }
  }

  String get displayName {
    switch (this) {
      case ContentType.image:
        return 'Ilustración';
      case ContentType.story:
        return 'Cuento';
      case ContentType.music:
        return 'Música';
    }
  }
}

/// Entidad pura del dominio para un elemento guardado en la biblioteca.
class LibraryItemEntity extends Equatable {
  final String id;
  final ContentType type;
  final String resourceId;
  final String name;
  final String description;
  final bool favorite;
  final String resourceUrl;
  final String? mediaType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LibraryItemEntity({
    required this.id,
    required this.type,
    required this.resourceId,
    required this.name,
    required this.description,
    required this.favorite,
    required this.resourceUrl,
    this.mediaType,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isImage => type == ContentType.image;
  bool get isStory => type == ContentType.story;
  bool get isMusic => type == ContentType.music;

  LibraryItemEntity copyWith({
    String? id,
    ContentType? type,
    String? resourceId,
    String? name,
    String? description,
    bool? favorite,
    String? resourceUrl,
    String? mediaType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LibraryItemEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      resourceId: resourceId ?? this.resourceId,
      name: name ?? this.name,
      description: description ?? this.description,
      favorite: favorite ?? this.favorite,
      resourceUrl: resourceUrl ?? this.resourceUrl,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        resourceId,
        name,
        description,
        favorite,
        resourceUrl,
        mediaType,
        createdAt,
        updatedAt,
      ];
}

