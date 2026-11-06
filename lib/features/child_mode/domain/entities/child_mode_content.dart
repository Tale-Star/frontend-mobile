import 'package:equatable/equatable.dart';

/// Tipos de contenido que pueden reproducirse o consumirse dentro del Modo Niño.
enum ChildModeContentType {
  story,
  image,
  music,
}

extension ChildModeContentTypeX on ChildModeContentType {
  String toValue() {
    switch (this) {
      case ChildModeContentType.story:
        return 'story';
      case ChildModeContentType.image:
        return 'image';
      case ChildModeContentType.music:
        return 'music';
    }
  }

  static ChildModeContentType fromValue(String value) {
    switch (value) {
      case 'image':
        return ChildModeContentType.image;
      case 'music':
        return ChildModeContentType.music;
      case 'story':
      default:
        return ChildModeContentType.story;
    }
  }

  String get labelSpanish {
    switch (this) {
      case ChildModeContentType.story:
        return 'Cuento infantil';
      case ChildModeContentType.image:
        return 'Ilustración';
      case ChildModeContentType.music:
        return 'Música instrumental';
    }
  }
}

/// Entidad pura del dominio que describe el recurso en consumo protegido.
class ChildModeContent extends Equatable {
  final ChildModeContentType contentType;
  final String contentId;
  final String title;
  final String routeContext;
  final DateTime activatedAt;

  const ChildModeContent({
    required this.contentType,
    required this.contentId,
    required this.title,
    required this.routeContext,
    required this.activatedAt,
  });

  @override
  List<Object?> get props => [
        contentType,
        contentId,
        title,
        routeContext,
        activatedAt,
      ];
}

