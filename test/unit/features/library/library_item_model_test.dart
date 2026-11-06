import 'package:flutter_test/flutter_test.dart';
import 'package:startale_mobile/features/library/data/models/library_item_model.dart';
import 'package:startale_mobile/features/library/domain/entities/library_item_entity.dart';

void main() {
  const tJson = {
    'id': 'b1c2d3e4-f5a6-7890-abcd-ef1234567890',
    'type': 'image',
    'resource_id': 'c1d2e3f4-a5b6-7890-abcd-ef1234567890',
    'name': 'El Bosque Estrellado',
    'description': 'Una hermosa ilustración de un bosque mágico bajo las estrellas.',
    'favorite': true,
    'resource_url': '/api/v1/media/assets/c1d2e3f4-a5b6-7890-abcd-ef1234567890',
    'media_type': 'image/png',
    'created_at': '2026-10-31T14:30:00Z',
    'updated_at': '2026-10-31T15:00:00Z',
  };

  group('LibraryItemModel & ContentType', () {
    test('deserializa correctamente un LibraryItemResponse completo', () {
      final model = LibraryItemModel.fromJson(tJson);

      expect(model.id, 'b1c2d3e4-f5a6-7890-abcd-ef1234567890');
      expect(model.type, ContentType.image);
      expect(model.resourceId, 'c1d2e3f4-a5b6-7890-abcd-ef1234567890');
      expect(model.name, 'El Bosque Estrellado');
      expect(model.description, 'Una hermosa ilustración de un bosque mágico bajo las estrellas.');
      expect(model.favorite, true);
      expect(model.resourceUrl, '/api/v1/media/assets/c1d2e3f4-a5b6-7890-abcd-ef1234567890');
      expect(model.mediaType, 'image/png');
      expect(model.createdAt, DateTime.parse('2026-10-31T14:30:00Z'));
      expect(model.updatedAt, DateTime.parse('2026-10-31T15:00:00Z'));
      expect(model.isImage, true);
      expect(model.isStory, false);
      expect(model.isMusic, false);
    });

    test('serializa a JSON respetando los nombres y tipos del contrato', () {
      final model = LibraryItemModel.fromJson(tJson);
      final json = model.toJson();

      expect(json['id'], tJson['id']);
      expect(json['type'], 'image');
      expect(json['name'], tJson['name']);
      expect(json['favorite'], true);
      expect(json['media_type'], 'image/png');
    });

    test('maneja valores nulos en media_type y defaults opcionales', () {
      final minimalJson = {
        'id': 'uuid-story-1',
        'type': 'story',
        'resource_id': 'uuid-res-1',
        'created_at': '2026-10-31T10:00:00Z',
        'updated_at': '2026-10-31T10:00:00Z',
      };

      final model = LibraryItemModel.fromJson(minimalJson);

      expect(model.type, ContentType.story);
      expect(model.isStory, true);
      expect(model.name, '');
      expect(model.description, '');
      expect(model.favorite, false);
      expect(model.mediaType, isNull);
    });

    test('ContentType enum parsing y traducción al español amigable', () {
      expect(ContentType.fromString('image'), ContentType.image);
      expect(ContentType.fromString('story'), ContentType.story);
      expect(ContentType.fromString('music'), ContentType.music);
      expect(() => ContentType.fromString('invalid'), throwsArgumentError);

      expect(ContentType.image.displayName, 'Ilustración');
      expect(ContentType.story.displayName, 'Cuento');
      expect(ContentType.music.displayName, 'Música');
    });

    test('copyWith crea una copia con campos modificados', () {
      final model = LibraryItemModel.fromJson(tJson);
      final updated = model.copyWith(favorite: false, name: 'Nuevo Nombre');

      expect(updated.favorite, false);
      expect(updated.name, 'Nuevo Nombre');
      expect(updated.id, model.id);
    });
  });
}

