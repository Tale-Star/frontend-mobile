import 'package:equatable/equatable.dart';

/// Entidad pura del dominio que representa una Página individual de un Cuento (StoryPage).
///
/// Nota arquitectónica sobre el Bloqueo StoryPage–Ilustración:
/// El backend oficial en su esquema `StoryPageResponse` no expone una URL o ID de asset de imagen.
/// El campo opcional [demoIllustrationAsset] se provee exclusivamente para la experiencia
/// enriquecida del Modo Demostración sin inventar campos en el contrato del backend.
class StoryPageDetail extends Equatable {
  final String id;
  final String storyId;
  final int pageNumber;
  final String action;
  final String text;
  final Map<String, dynamic> visualConfig;
  final List<String> characterIds;
  final int? seed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? demoIllustrationAsset;

  const StoryPageDetail({
    required this.id,
    required this.storyId,
    required this.pageNumber,
    required this.action,
    required this.text,
    required this.visualConfig,
    required this.characterIds,
    this.seed,
    required this.createdAt,
    required this.updatedAt,
    this.demoIllustrationAsset,
  });

  StoryPageDetail copyWith({
    String? id,
    String? storyId,
    int? pageNumber,
    String? action,
    String? text,
    Map<String, dynamic>? visualConfig,
    List<String>? characterIds,
    int? seed,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? demoIllustrationAsset,
  }) {
    return StoryPageDetail(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      pageNumber: pageNumber ?? this.pageNumber,
      action: action ?? this.action,
      text: text ?? this.text,
      visualConfig: visualConfig ?? this.visualConfig,
      characterIds: characterIds ?? this.characterIds,
      seed: seed ?? this.seed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      demoIllustrationAsset: demoIllustrationAsset ?? this.demoIllustrationAsset,
    );
  }

  @override
  List<Object?> get props => [
        id,
        storyId,
        pageNumber,
        action,
        text,
        visualConfig,
        characterIds,
        seed,
        createdAt,
        updatedAt,
        demoIllustrationAsset,
      ];
}

