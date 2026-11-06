import 'package:flutter_test/flutter_test.dart';
import 'package:startale_mobile/features/library/domain/entities/library_item_entity.dart';
import 'package:startale_mobile/features/music/domain/entities/music_track.dart';

void main() {
  group('MusicTrack Entity', () {
    test('soporta comparación por igualdad mediante Equatable', () {
      const track1 = MusicTrack(
        id: 'track-1',
        resourceId: 'res-1',
        name: 'Melodía Lunar',
        resourceUrl: '/api/v1/media/assets/res-1',
        mediaType: 'audio/flac',
      );

      const track2 = MusicTrack(
        id: 'track-1',
        resourceId: 'res-1',
        name: 'Melodía Lunar',
        resourceUrl: '/api/v1/media/assets/res-1',
        mediaType: 'audio/flac',
      );

      expect(track1, equals(track2));
    });

    test('isFlac detecta correctamente formato FLAC por MIME o extensión', () {
      const flacMimeTrack = MusicTrack(
        id: 't-1',
        resourceId: 'r-1',
        name: 'Pista 1',
        resourceUrl: '/api/v1/media/assets/r-1',
        mediaType: 'audio/flac',
      );
      expect(flacMimeTrack.isFlac, isTrue);

      const flacExtTrack = MusicTrack(
        id: 't-2',
        resourceId: 'r-2',
        name: 'Pista 2',
        resourceUrl: 'https://example.com/audio/song.flac',
        mediaType: 'audio/octet-stream',
      );
      expect(flacExtTrack.isFlac, isTrue);

      const localFlacTrack = MusicTrack(
        id: 't-3',
        resourceId: 'r-3',
        name: 'Pista 3',
        resourceUrl: '/api/v1/media/assets/r-3',
        mediaType: '',
        localAssetPath: 'assets/demo/demo_song.flac',
      );
      expect(localFlacTrack.isFlac, isTrue);

      const mp3Track = MusicTrack(
        id: 't-4',
        resourceId: 'r-4',
        name: 'Pista 4',
        resourceUrl: '/api/v1/media/assets/r-4',
        mediaType: 'audio/mpeg',
      );
      expect(mp3Track.isFlac, isFalse);
    });

    test('audioFormatLabel genera etiquetas descriptivas adecuadas', () {
      const flacTrack = MusicTrack(
        id: 't-1',
        resourceId: 'r-1',
        name: 'Pista FLAC',
        resourceUrl: '/assets/r-1',
        mediaType: 'audio/flac',
      );
      expect(flacTrack.audioFormatLabel, 'FLAC Lossless');

      const wavTrack = MusicTrack(
        id: 't-2',
        resourceId: 'r-2',
        name: 'Pista WAV',
        resourceUrl: '/assets/r-2',
        mediaType: 'audio/wav',
      );
      expect(wavTrack.audioFormatLabel, 'WAV Audio');

      const mp3Track = MusicTrack(
        id: 't-3',
        resourceId: 'r-3',
        name: 'Pista MP3',
        resourceUrl: '/assets/r-3',
        mediaType: 'audio/mpeg',
      );
      expect(mp3Track.audioFormatLabel, 'MP3 Hi-Fi');

      const opusTrack = MusicTrack(
        id: 't-4',
        resourceId: 'r-4',
        name: 'Pista OPUS',
        resourceUrl: '/assets/r-4',
        mediaType: 'audio/opus',
      );
      expect(opusTrack.audioFormatLabel, 'OPUS Audio');

      const aacTrack = MusicTrack(
        id: 't-5',
        resourceId: 'r-5',
        name: 'Pista AAC',
        resourceUrl: '/assets/r-5',
        mediaType: 'audio/aac',
      );
      expect(aacTrack.audioFormatLabel, 'AAC Audio');

      const genericTrack = MusicTrack(
        id: 't-6',
        resourceId: 'r-6',
        name: 'Pista Genérica',
        resourceUrl: '/assets/r-6',
        mediaType: 'audio/custom',
      );
      expect(genericTrack.audioFormatLabel, 'Audio Estéreo');
    });

    test('fromLibraryItem mapea correctamente los campos y valores por defecto', () {
      final item = LibraryItemEntity(
        id: 'lib-mus-1',
        type: ContentType.music,
        resourceId: 'res-mus-1',
        name: 'Cuna Cósmica',
        description: 'Canción para dormir',
        favorite: true,
        resourceUrl: '/api/v1/media/assets/res-mus-1',
        mediaType: 'audio/flac',
        createdAt: DateTime.parse('2026-11-01T12:00:00Z'),
        updatedAt: DateTime.parse('2026-11-01T12:30:00Z'),
      );

      final track = MusicTrack.fromLibraryItem(
        item,
        localAssetPath: 'assets/demo/demo_song.wav',
        duration: const Duration(minutes: 2, seconds: 45),
      );

      expect(track.id, 'lib-mus-1');
      expect(track.resourceId, 'res-mus-1');
      expect(track.name, 'Cuna Cósmica');
      expect(track.description, 'Canción para dormir');
      expect(track.favorite, isTrue);
      expect(track.mediaType, 'audio/flac');
      expect(track.localAssetPath, 'assets/demo/demo_song.wav');
      expect(track.duration, const Duration(minutes: 2, seconds: 45));
    });

    test('copyWith produce una nueva instancia con valores actualizados', () {
      const track = MusicTrack(
        id: 't-1',
        resourceId: 'r-1',
        name: 'Canción Original',
        resourceUrl: '/audio/1',
        mediaType: 'audio/flac',
        favorite: false,
      );

      final updated = track.copyWith(
        name: 'Canción Renombrada',
        favorite: true,
        duration: const Duration(seconds: 120),
      );

      expect(updated.id, 't-1');
      expect(updated.name, 'Canción Renombrada');
      expect(updated.favorite, isTrue);
      expect(updated.duration, const Duration(seconds: 120));
      expect(track.favorite, isFalse); // Inmutabilidad
    });
  });
}

