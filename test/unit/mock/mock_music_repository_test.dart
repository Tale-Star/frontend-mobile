import 'package:flutter_test/flutter_test.dart';
import 'package:startale_mobile/core/error/failures.dart';
import 'package:startale_mobile/mock/mock_music_repository.dart';

void main() {
  late MockMusicRepository repository;

  setUp(() {
    repository = MockMusicRepository();
  });

  group('MockMusicRepository', () {
    test('getTracks retorna la colección de pistas musicales de demostración', () async {
      final tracks = await repository.getTracks();

      expect(tracks, isNotEmpty);
      expect(tracks.length, equals(3));
      for (final track in tracks) {
        expect(track.localAssetPath, equals('assets/demo/demo_song.wav'));
        expect(track.mediaType, equals('audio/flac'));
      }
    });

    test('getTracks con filtro favorite filtra solo pistas favoritas', () async {
      final favoriteTracks = await repository.getTracks(favorite: true);

      expect(favoriteTracks, isNotEmpty);
      for (final track in favoriteTracks) {
        expect(track.favorite, isTrue);
      }
    });

    test('getTracks con query filtra por texto en nombre o descripción', () async {
      final matches = await repository.getTracks(query: 'cuna');

      expect(matches.length, equals(1));
      expect(matches.first.name, contains('Cuna'));
    });

    test('getTrackById retorna la pista correspondiente o lanza ServerFailure', () async {
      final track = await repository.getTrackById('mus-demo-001');
      expect(track.name, 'Canción de Cuna Cósmica');

      expect(
        () => repository.getTrackById('mus-inexistente'),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('toggleFavorite invierte el estado de favorito', () async {
      final track = await repository.getTrackById('mus-demo-001');
      final originalStatus = track.favorite;

      final updated = await repository.toggleFavorite(track);
      expect(updated.favorite, !originalStatus);

      final fetched = await repository.getTrackById('mus-demo-001');
      expect(fetched.favorite, !originalStatus);
    });

    test('simulateNetworkError lanza NetworkFailure en getTracks y getTrackById', () async {
      repository.simulateNetworkError = true;

      expect(
        () => repository.getTracks(),
        throwsA(isA<NetworkFailure>()),
      );

      expect(
        () => repository.getTrackById('mus-demo-001'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}

