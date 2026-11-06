import '../core/error/failures.dart';
import '../features/library/data/models/library_item_model.dart';
import '../features/music/domain/entities/music_track.dart';
import '../features/music/domain/repositories/music_repository.dart';
import 'fixtures/demo_library_fixtures.dart';

/// Implementación simulada de [MusicRepository] para pruebas locales y Modo Demostración.
class MockMusicRepository implements MusicRepository {
  List<MusicTrack> _tracks = [];
  bool simulateNetworkError = false;

  MockMusicRepository() {
    resetToFixtures();
  }

  void resetToFixtures() {
    final musicItems = kDemoLibraryFixtures
        .where((item) => item['type'] == 'music')
        .map((json) => LibraryItemModel.fromJson(json))
        .toList();

    _tracks = musicItems.map((item) {
      return MusicTrack.fromLibraryItem(
        item,
        localAssetPath: 'assets/demo/demo_song.wav',
        duration: const Duration(minutes: 3, seconds: 15),
      );
    }).toList();
  }

  @override
  Future<List<MusicTrack>> getTracks({String? query, bool? favorite}) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final normalizedQuery = (query ?? '').toLowerCase().trim();

    if (simulateNetworkError || normalizedQuery.contains('error_red')) {
      throw const NetworkFailure(
        message: 'No pudimos conectar con el servidor de audio. Revisa tu conexión.',
      );
    }

    var result = List<MusicTrack>.from(_tracks);

    if (favorite == true) {
      result = result.where((t) => t.favorite).toList();
    }

    if (normalizedQuery.isNotEmpty) {
      result = result.where((t) {
        final matchName = t.name.toLowerCase().contains(normalizedQuery);
        final matchDesc = t.description.toLowerCase().contains(normalizedQuery);
        return matchName || matchDesc;
      }).toList();
    }

    return result;
  }

  @override
  Future<MusicTrack> getTrackById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));

    if (simulateNetworkError) {
      throw const NetworkFailure(
        message: 'Error al recuperar la pista musical solicitada.',
      );
    }

    final match = _tracks.where((t) => t.id == id || t.resourceId == id);
    if (match.isEmpty) {
      throw const ServerFailure(
        message: 'No se encontró la pista musical solicitada.',
        statusCode: 404,
      );
    }

    return match.first;
  }

  @override
  Future<MusicTrack> toggleFavorite(MusicTrack track) async {
    await Future.delayed(const Duration(milliseconds: 150));

    if (simulateNetworkError) {
      throw const NetworkFailure(
        message: 'No fue posible actualizar tu favorito de música.',
      );
    }

    final index = _tracks.indexWhere((t) => t.id == track.id);
    final updated = track.copyWith(favorite: !track.favorite);

    if (index != -1) {
      _tracks[index] = updated;
    }

    return updated;
  }
}

