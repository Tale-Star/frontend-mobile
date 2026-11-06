import '../entities/music_track.dart';

/// Contrato del repositorio para pistas musicales de Tale Star.
abstract class MusicRepository {
  /// Obtiene la lista de pistas musicales del usuario, con soporte opcional de búsqueda y favoritos.
  Future<List<MusicTrack>> getTracks({String? query, bool? favorite});

  /// Obtiene el detalle de una pista musical por su ID de biblioteca.
  Future<MusicTrack> getTrackById(String id);

  /// Alterna el estado de favorito de una pista musical.
  Future<MusicTrack> toggleFavorite(MusicTrack track);
}

