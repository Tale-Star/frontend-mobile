import 'package:startale_mobile/features/library/data/datasources/library_remote_datasource.dart';
import '../../domain/entities/music_track.dart';
import '../../domain/repositories/music_repository.dart';

/// Implementación del repositorio de música utilizando el origen remoto de biblioteca.
class MusicRepositoryImpl implements MusicRepository {
  final LibraryRemoteDataSource remoteDataSource;

  MusicRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MusicTrack>> getTracks({String? query, bool? favorite}) async {
    final items = await remoteDataSource.getLibraryItems(
      type: 'music',
      q: query,
      favorite: favorite,
    );
    return items.map((model) => MusicTrack.fromLibraryItem(model)).toList();
  }

  @override
  Future<MusicTrack> getTrackById(String id) async {
    final model = await remoteDataSource.getLibraryItem(id);
    return MusicTrack.fromLibraryItem(model);
  }

  @override
  Future<MusicTrack> toggleFavorite(MusicTrack track) async {
    final updatedModel = await remoteDataSource.patchLibraryItem(
      track.id,
      favorite: !track.favorite,
    );
    return MusicTrack.fromLibraryItem(
      updatedModel,
      localAssetPath: track.localAssetPath,
      duration: track.duration,
    );
  }
}
