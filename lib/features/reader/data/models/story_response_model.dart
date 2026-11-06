import '../../domain/entities/story_detail.dart';

/// Modelo DTO para deserializar la respuesta del backend (`StoryResponse`).
///
/// Refleja estrictamente el schema Pydantic del backend oficial:
/// `id`, `title`, `description`, `scenario_id`, `style_profile_id`, `seed`, `created_at`, `updated_at`.
class StoryResponseModel extends StoryDetail {
  const StoryResponseModel({
    required super.id,
    required super.title,
    required super.description,
    super.scenarioId,
    super.styleProfileId,
    super.seed,
    required super.createdAt,
    required super.updatedAt,
  });

  factory StoryResponseModel.fromJson(Map<String, dynamic> json) {
    return StoryResponseModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      scenarioId: json['scenario_id'] as String?,
      styleProfileId: json['style_profile_id'] as String?,
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
      'title': title,
      'description': description,
      'scenario_id': scenarioId,
      'style_profile_id': styleProfileId,
      'seed': seed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StoryResponseModel.fromEntity(StoryDetail entity) {
    return StoryResponseModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      scenarioId: entity.scenarioId,
      styleProfileId: entity.styleProfileId,
      seed: entity.seed,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

