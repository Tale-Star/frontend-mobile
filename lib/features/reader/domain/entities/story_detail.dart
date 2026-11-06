import 'package:equatable/equatable.dart';

/// Entidad pura del dominio que representa el detalle de un Cuento (Story).
class StoryDetail extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? scenarioId;
  final String? styleProfileId;
  final int? seed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StoryDetail({
    required this.id,
    required this.title,
    required this.description,
    this.scenarioId,
    this.styleProfileId,
    this.seed,
    required this.createdAt,
    required this.updatedAt,
  });

  StoryDetail copyWith({
    String? id,
    String? title,
    String? description,
    String? scenarioId,
    String? styleProfileId,
    int? seed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoryDetail(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      scenarioId: scenarioId ?? this.scenarioId,
      styleProfileId: styleProfileId ?? this.styleProfileId,
      seed: seed ?? this.seed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        scenarioId,
        styleProfileId,
        seed,
        createdAt,
        updatedAt,
      ];
}

