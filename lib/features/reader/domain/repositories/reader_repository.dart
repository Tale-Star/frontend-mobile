import '../entities/story_detail.dart';
import '../entities/story_page_detail.dart';

/// Contrato abstracto del repositorio de lectura de cuentos (Fase 3).
abstract class ReaderRepository {
  /// Obtiene los detalles del cuento por su [storyId] (`GET /api/v1/stories/{story_id}`).
  Future<StoryDetail> getStory(String storyId);

  /// Obtiene el listado de páginas del cuento ordenadas por [page_number] (`GET /api/v1/stories/{story_id}/pages`).
  Future<List<StoryPageDetail>> getStoryPages(String storyId);
}

