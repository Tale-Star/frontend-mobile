import '../../domain/entities/story_page_detail.dart';

/// Modelo DTO para deserializar páginas de un cuento (`StoryPageResponse`).
///
/// Refleja estrictamente el schema Pydantic del backend oficial:
/// `id`, `story_id`, `page_number`, `action`, `text`, `visual_config`, `character_ids`, `seed`, `created_at`, `updated_at`.
/// No incluye campos inventados como `illustration_url` o `illustration_asset_id`.
class StoryPageModel extends StoryPageDetail {
  const StoryPageModel({
    required super.id,
    required super.storyId,
    required super.pageNumber,
    required super.action,
    required super.text,
    required super.visualConfig,
    required super.characterIds,
    super.seed,
    required super.createdAt,
    required super.updatedAt,
  });

  factory StoryPageModel.fromJson(Map<String, dynamic> json) {
    final rawCharacters = json['character_ids'];
    final characterIds = (rawCharacters is List)
        ? rawCharacters.map((e) => e.toString()).toList()
        : <String>[];

    final rawVisual = json['visual_config'];
    final visualConfig = (rawVisual is Map<String, dynamic>)
        ? rawVisual
        : (rawVisual is Map ? Map<String, dynamic>.from(rawVisual) : <String, dynamic>{});

    return StoryPageModel(
      id: json['id'] as String,
      storyId: json['story_id'] as String,
      pageNumber: (json['page_number'] as num).toInt(),
      action: (json['action'] as String?) ?? '',
      text: (json['text'] as String?) ?? '',
      visualConfig: visualConfig,
      characterIds: characterIds,
      seed: json['seed'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'story_id': storyId,
      'page_number': pageNumber,
      'action': action,
      'text': text,
      'visual_config': visualConfig,
      'character_ids': characterIds,
      'seed': seed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StoryPageModel.fromEntity(StoryPageDetail entity) {
    return StoryPageModel(
      id: entity.id,
      storyId: entity.storyId,
      pageNumber: entity.pageNumber,
      action: entity.action,
      text: entity.text,
      visualConfig: entity.visualConfig,
      characterIds: entity.characterIds,
      seed: entity.seed,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

