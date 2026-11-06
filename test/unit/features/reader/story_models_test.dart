import 'package:flutter_test/flutter_test.dart';
import 'package:startale_mobile/features/reader/data/models/story_page_model.dart';
import 'package:startale_mobile/features/reader/data/models/story_response_model.dart';
import 'package:startale_mobile/features/reader/domain/entities/story_detail.dart';
import 'package:startale_mobile/features/reader/domain/entities/story_page_detail.dart';

void main() {
  group('StoryResponseModel', () {
    final tJsonComplete = {
      'id': 'story-uuid-1',
      'title': 'El Pequeño Astronauta',
      'description': 'Una aventura sobre las estrellas.',
      'scenario_id': 'scenario-uuid-1',
      'style_profile_id': 'style-uuid-1',
      'seed': 42,
      'created_at': '2026-10-31T10:00:00.000Z',
      'updated_at': '2026-10-31T11:00:00.000Z',
    };

    final tJsonMinimal = {
      'id': 'story-uuid-2',
      'title': 'Cuento Simple',
      'created_at': '2026-10-31T10:00:00.000Z',
    };

    test('fromJson parsea correctamente todos los campos documentados en el backend', () {
      final model = StoryResponseModel.fromJson(tJsonComplete);

      expect(model.id, 'story-uuid-1');
      expect(model.title, 'El Pequeño Astronauta');
      expect(model.description, 'Una aventura sobre las estrellas.');
      expect(model.scenarioId, 'scenario-uuid-1');
      expect(model.styleProfileId, 'style-uuid-1');
      expect(model.seed, 42);
      expect(model.createdAt, DateTime.parse('2026-10-31T10:00:00.000Z'));
      expect(model.updatedAt, DateTime.parse('2026-10-31T11:00:00.000Z'));
    });

    test('fromJson maneja campos opcionales nulos con valores por defecto seguros', () {
      final model = StoryResponseModel.fromJson(tJsonMinimal);

      expect(model.id, 'story-uuid-2');
      expect(model.title, 'Cuento Simple');
      expect(model.description, '');
      expect(model.scenarioId, isNull);
      expect(model.styleProfileId, isNull);
      expect(model.seed, isNull);
      expect(model.updatedAt, DateTime.parse('2026-10-31T10:00:00.000Z'));
    });

    test('extiende StoryDetail directamente como entidad del dominio', () {
      final model = StoryResponseModel.fromJson(tJsonComplete);

      expect(model, isA<StoryDetail>());
      expect(model.id, 'story-uuid-1');
      expect(model.title, 'El Pequeño Astronauta');
      expect(model.description, 'Una aventura sobre las estrellas.');
    });

    test('toJson serializa con claves snake_case exactas del contrato backend', () {
      final model = StoryResponseModel.fromJson(tJsonComplete);
      final json = model.toJson();

      expect(json['id'], 'story-uuid-1');
      expect(json['title'], 'El Pequeño Astronauta');
      expect(json['description'], 'Una aventura sobre las estrellas.');
      expect(json['scenario_id'], 'scenario-uuid-1');
      expect(json['style_profile_id'], 'style-uuid-1');
      expect(json['seed'], 42);
      expect(json['created_at'], '2026-10-31T10:00:00.000Z');
      expect(json['updated_at'], '2026-10-31T11:00:00.000Z');
    });
  });

  group('StoryPageModel', () {
    final tPageJsonComplete = {
      'id': 'page-uuid-1',
      'story_id': 'story-uuid-1',
      'page_number': 1,
      'action': 'Leo mira por el telescopio.',
      'text': 'Había una vez un niño llamado Leo que soñaba con tocar las estrellas.',
      'visual_config': {'palette': 'warm', 'camera': 'wide'},
      'character_ids': ['char-1', 'char-2'],
      'seed': 1234,
      'created_at': '2026-10-31T10:00:00.000Z',
      'updated_at': '2026-10-31T10:30:00.000Z',
    };

    final tPageJsonMinimal = {
      'id': 'page-uuid-2',
      'story_id': 'story-uuid-1',
      'page_number': 2,
      'created_at': '2026-10-31T10:00:00.000Z',
    };

    test('fromJson parsea correctamente todos los campos de StoryPageResponse', () {
      final model = StoryPageModel.fromJson(tPageJsonComplete);

      expect(model.id, 'page-uuid-1');
      expect(model.storyId, 'story-uuid-1');
      expect(model.pageNumber, 1);
      expect(model.action, 'Leo mira por el telescopio.');
      expect(model.text, 'Había una vez un niño llamado Leo que soñaba con tocar las estrellas.');
      expect(model.visualConfig['palette'], 'warm');
      expect(model.characterIds, ['char-1', 'char-2']);
      expect(model.seed, 1234);
      expect(model.createdAt, DateTime.parse('2026-10-31T10:00:00.000Z'));
      expect(model.updatedAt, DateTime.parse('2026-10-31T10:30:00.000Z'));
    });

    test('fromJson asigna valores por defecto seguros para campos ausentes', () {
      final model = StoryPageModel.fromJson(tPageJsonMinimal);

      expect(model.id, 'page-uuid-2');
      expect(model.storyId, 'story-uuid-1');
      expect(model.pageNumber, 2);
      expect(model.action, '');
      expect(model.text, '');
      expect(model.visualConfig, isEmpty);
      expect(model.characterIds, isEmpty);
      expect(model.seed, isNull);
      expect(model.updatedAt, DateTime.parse('2026-10-31T10:00:00.000Z'));
    });

    test('extiende StoryPageDetail como entidad pura de lectura', () {
      final model = StoryPageModel.fromJson(tPageJsonComplete);

      expect(model, isA<StoryPageDetail>());
      expect(model.id, 'page-uuid-1');
      expect(model.storyId, 'story-uuid-1');
      expect(model.pageNumber, 1);
      expect(model.action, 'Leo mira por el telescopio.');
      expect(model.text, 'Había una vez un niño llamado Leo que soñaba con tocar las estrellas.');
      expect(model.characterIds, ['char-1', 'char-2']);
      expect(model.demoIllustrationAsset, isNull);
    });

    test('toJson serializa conservando los nombres de campo de FastAPI/Pydantic', () {
      final model = StoryPageModel.fromJson(tPageJsonComplete);
      final json = model.toJson();

      expect(json['id'], 'page-uuid-1');
      expect(json['story_id'], 'story-uuid-1');
      expect(json['page_number'], 1);
      expect(json['action'], 'Leo mira por el telescopio.');
      expect(json['character_ids'], ['char-1', 'char-2']);
      expect(json['visual_config'], isNotNull);
    });
  });
}
