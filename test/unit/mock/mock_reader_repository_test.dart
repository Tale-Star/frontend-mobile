import 'package:flutter_test/flutter_test.dart';
import 'package:startale_mobile/core/error/failures.dart';
import 'package:startale_mobile/mock/mock_reader_repository.dart';

void main() {
  late MockReaderRepository mockRepo;

  setUp(() {
    mockRepo = MockReaderRepository();
  });

  group('MockReaderRepository', () {
    test('res-sty-001 retorna cuento de 3 páginas con assets de demo', () async {
      final story = await mockRepo.getStory('res-sty-001');
      expect(story.title, 'La Pequeña Estrella Perdida');

      final pages = await mockRepo.getStoryPages('res-sty-001');
      expect(pages.length, 3);
      expect(pages[0].pageNumber, 1);
      expect(pages[0].demoIllustrationAsset, isNotNull);
      expect(pages[1].pageNumber, 2);
      expect(pages[2].pageNumber, 3);
    });

    test('res-sty-002 retorna cuento de 1 sola página para validación de límites', () async {
      final story = await mockRepo.getStory('res-sty-002');
      expect(story.title, contains('Relojero'));

      final pages = await mockRepo.getStoryPages('res-sty-002');
      expect(pages.length, 1);
      expect(pages.first.pageNumber, 1);
      expect(pages.first.action, contains('La lección del tiempo'));
    });

    test('res-sty-003 retorna cuento con texto extenso sin romper el layout', () async {
      final pages = await mockRepo.getStoryPages('res-sty-003');
      expect(pages.length, 2);
      expect(pages.first.text.length, greaterThan(250));
    });

    test('res-sty-empty retorna lista vacía de páginas para verificar ReaderEmpty', () async {
      final story = await mockRepo.getStory('res-sty-empty');
      expect(story.title, contains('Cuaderno en Blanco'));

      final pages = await mockRepo.getStoryPages('res-sty-empty');
      expect(pages, isEmpty);
    });

    test('res-sty-error simula fallo de servidor lanzando Failure', () async {
      expect(
        () => mockRepo.getStory('res-sty-error'),
        throwsA(isA<NetworkFailure>().having((f) => f.message, 'message', contains('No pudimos conectar'))),
      );
    });

    test('cuento desconocido lanza ServerFailure 404', () async {
      expect(
        () => mockRepo.getStory('unregistered-id'),
        throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 404)),
      );
    });
  });
}
