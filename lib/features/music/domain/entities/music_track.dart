import 'package:equatable/equatable.dart';
import 'package:startale_mobile/features/library/domain/entities/library_item_entity.dart';

/// Entidad de dominio que representa una pista musical ambiental de Tale Star.
class MusicTrack extends Equatable {
  final String id;
  final String resourceId;
  final String name;
  final String description;
  final String resourceUrl;
  final String mediaType;
  final bool favorite;
  final Duration? duration;
  final String? localAssetPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MusicTrack({
    required this.id,
    required this.resourceId,
    required this.name,
    this.description = '',
    required this.resourceUrl,
    required this.mediaType,
    this.favorite = false,
    this.duration,
    this.localAssetPath,
    this.createdAt,
    this.updatedAt,
  });

  /// Determina si la pista está en formato FLAC sin pérdidas.
  bool get isFlac =>
      mediaType.toLowerCase().contains('flac') ||
      resourceUrl.toLowerCase().endsWith('.flac') ||
      (localAssetPath != null && localAssetPath!.toLowerCase().endsWith('.flac'));

  /// Etiqueta descriptiva del formato y calidad de audio.
  String get audioFormatLabel {
    if (isFlac) {
      return 'FLAC Lossless';
    }
    final lowerMedia = mediaType.toLowerCase();
    final lowerUrl = resourceUrl.toLowerCase();
    if (lowerMedia.contains('wav') || lowerUrl.endsWith('.wav')) {
      return 'WAV Audio';
    }
    if (lowerMedia.contains('mpeg') ||
        lowerMedia.contains('mp3') ||
        lowerUrl.endsWith('.mp3')) {
      return 'MP3 Hi-Fi';
    }
    if (lowerMedia.contains('opus') || lowerUrl.endsWith('.opus')) {
      return 'OPUS Audio';
    }
    if (lowerMedia.contains('aac') || lowerUrl.endsWith('.aac')) {
      return 'AAC Audio';
    }
    return 'Audio Estéreo';
  }

  /// Construye un [MusicTrack] a partir de un [LibraryItemEntity].
  factory MusicTrack.fromLibraryItem(
    LibraryItemEntity item, {
    String? localAssetPath,
    Duration? duration,
  }) {
    return MusicTrack(
      id: item.id,
      resourceId: item.resourceId,
      name: item.name,
      description: item.description,
      resourceUrl: item.resourceUrl,
      mediaType: (item.mediaType != null && item.mediaType!.isNotEmpty)
          ? item.mediaType!
          : 'audio/flac',
      favorite: item.favorite,
      duration: duration,
      localAssetPath: localAssetPath,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }

  /// Retorna una copia con propiedades modificadas.
  MusicTrack copyWith({
    String? id,
    String? resourceId,
    String? name,
    String? description,
    String? resourceUrl,
    String? mediaType,
    bool? favorite,
    Duration? duration,
    String? localAssetPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MusicTrack(
      id: id ?? this.id,
      resourceId: resourceId ?? this.resourceId,
      name: name ?? this.name,
      description: description ?? this.description,
      resourceUrl: resourceUrl ?? this.resourceUrl,
      mediaType: mediaType ?? this.mediaType,
      favorite: favorite ?? this.favorite,
      duration: duration ?? this.duration,
      localAssetPath: localAssetPath ?? this.localAssetPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        resourceId,
        name,
        description,
        resourceUrl,
        mediaType,
        favorite,
        duration,
        localAssetPath,
        createdAt,
        updatedAt,
      ];
}

