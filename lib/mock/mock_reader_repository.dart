import '../../core/error/failures.dart';
import '../features/reader/domain/entities/story_detail.dart';
import '../features/reader/domain/entities/story_page_detail.dart';
import '../features/reader/domain/repositories/reader_repository.dart';

/// Implementación simulada de [ReaderRepository] para el Modo Demostración de Tale Star.
///
/// Proporciona cuentos con diversas configuraciones:
/// - Varias páginas con transiciones y assets locales (`res-sty-001`).
/// - Cuento de una sola página para verificar límites simultáneos (`res-sty-002`).
/// - Cuento con narración extensa para comprobar scroll vertical accesible (`res-sty-003`).
/// - Cuento vacío sin páginas (`res-sty-empty`).
/// - Simulación de fallos de red (`res-sty-error`).
class MockReaderRepository implements ReaderRepository {
  bool simulateNetworkError = false;

  static final Map<String, StoryDetail> _mockStories = {
    'res-sty-001': StoryDetail(
      id: 'res-sty-001',
      title: 'La Pequeña Estrella Perdida',
      description: 'Una emotiva aventura sobre la curiosidad, el valor y cómo encontrar el camino a casa.',
      scenarioId: 'scen-001',
      styleProfileId: 'style-001',
      seed: 42,
      createdAt: DateTime.parse('2026-10-31T11:00:00Z'),
      updatedAt: DateTime.parse('2026-10-31T11:00:00Z'),
    ),
    'res-sty-002': StoryDetail(
      id: 'res-sty-002',
      title: 'El Secreto del Relojero del Tiempo',
      description: 'Un relato sobre la paciencia, la empatía y la magia de los segundos compartidos.',
      scenarioId: 'scen-002',
      styleProfileId: 'style-002',
      seed: 108,
      createdAt: DateTime.parse('2026-10-28T16:20:00Z'),
      updatedAt: DateTime.parse('2026-10-28T16:20:00Z'),
    ),
    'res-sty-003': StoryDetail(
      id: 'res-sty-003',
      title: 'Las Aventuras del Ratón Astronauta',
      description: 'Mico construye su nave de cartón para explorar los cráteres de queso lunar.',
      scenarioId: 'scen-003',
      styleProfileId: 'style-003',
      seed: 999,
      createdAt: DateTime.parse('2026-10-22T08:30:00Z'),
      updatedAt: DateTime.parse('2026-10-22T08:30:00Z'),
    ),
    'res-sty-empty': StoryDetail(
      id: 'res-sty-empty',
      title: 'El Cuaderno en Blanco',
      description: 'Un cuento recién creado que aún no posee páginas escritas.',
      scenarioId: null,
      styleProfileId: null,
      seed: 0,
      createdAt: DateTime.parse('2026-11-01T10:00:00Z'),
      updatedAt: DateTime.parse('2026-11-01T10:00:00Z'),
    ),
  };

  static final Map<String, List<StoryPageDetail>> _mockPages = {
    // res-sty-001: 3 páginas con assets de demo
    'res-sty-001': [
      StoryPageDetail(
        id: 'page-001-1',
        storyId: 'res-sty-001',
        pageNumber: 1,
        action: 'Comienzo del viaje',
        text: 'Había una vez, en el rincón más brillante del firmamento, una pequeña estrella llamada Estelita. A diferencia de las estrellas mayores que preferían permanecer quietas titilando en su sitio, Estelita adoraba bailar al ritmo del viento cósmico y asomarse curiosa a mirar las copas de los árboles en la Tierra.',
        visualConfig: {'theme': 'night_sky'},
        characterIds: const ['char-estelita'],
        seed: 101,
        createdAt: DateTime.parse('2026-10-31T11:00:00Z'),
        updatedAt: DateTime.parse('2026-10-31T11:00:00Z'),
        demoIllustrationAsset: 'assets/demo/demo_forest.png',
      ),
      StoryPageDetail(
        id: 'page-001-2',
        storyId: 'res-sty-001',
        pageNumber: 2,
        action: 'El castillo en las nubes',
        text: 'Una noche de luna plateada, un destello juguetón la hizo descender más de la cuenta. Cuando quiso regresar, la distancia parecía infinita. Fue entonces cuando divisó una fortaleza de piedra blanca que flotaba serenamente sobre las nubes, habitada por aves guardianas que cuidaban el descanso nocturno de los niños.',
        visualConfig: {'theme': 'cloud_castle'},
        characterIds: const ['char-estelita', 'char-guardian'],
        seed: 102,
        createdAt: DateTime.parse('2026-10-31T11:05:00Z'),
        updatedAt: DateTime.parse('2026-10-31T11:05:00Z'),
        demoIllustrationAsset: 'assets/demo/demo_castle.png',
      ),
      StoryPageDetail(
        id: 'page-001-3',
        storyId: 'res-sty-001',
        pageNumber: 3,
        action: 'Regreso al hogar',
        text: 'Con la tierna ayuda de una bandada de golondrinas estelares y el brillo de miles de luciérnagas amigas, Estelita tomó un suave impulso y trepó por un arcoíris nocturno de vuelta a su hogar. Desde aquella noche, brilla con una luz especial que recuerda a todos los niños que nunca están verdaderamente solos.',
        visualConfig: {'theme': 'space_nebula'},
        characterIds: const ['char-estelita'],
        seed: 103,
        createdAt: DateTime.parse('2026-10-31T11:10:00Z'),
        updatedAt: DateTime.parse('2026-10-31T11:10:00Z'),
        demoIllustrationAsset: 'assets/demo/demo_space.png',
      ),
    ],

    // res-sty-002: Cuento de 1 sola página (límites anterior y siguiente deshabilitados)
    'res-sty-002': [
      StoryPageDetail(
        id: 'page-002-1',
        storyId: 'res-sty-002',
        pageNumber: 1,
        action: 'La lección del tiempo',
        text: 'En un taller acogedor impregnado de aroma a cedro y sonoros "tic-tac", el anciano relojero don Mateo ajustaba el resorte de un reloj centenario. Su nieta Sofía le preguntó: "¿Cuál es el reloj más valioso que has construido, abuelo?". Don Mateo sonrió con ternura y respondió: "El más valioso no es de oro ni de cuarzo, Sofía; es aquel que marca los minutos que pasamos juntos leyendo historias antes de dormir. Porque el tiempo compartido con amor nunca se pierde, se queda guardado para siempre en el corazón."',
        visualConfig: {'theme': 'clockmaker_room'},
        characterIds: const ['char-mateo', 'char-sofia'],
        seed: 201,
        createdAt: DateTime.parse('2026-10-28T16:20:00Z'),
        updatedAt: DateTime.parse('2026-10-28T16:20:00Z'),
        demoIllustrationAsset: null, // Prueba del marco temático placeholder oficial
      ),
    ],

    // res-sty-003: Cuento con narración extensa para comprobar scroll vertical accesible
    'res-sty-003': [
      StoryPageDetail(
        id: 'page-003-1',
        storyId: 'res-sty-003',
        pageNumber: 1,
        action: 'Construcción del cohete',
        text: 'Mico no era un ratoncito común de campo. Mientras sus hermanos coleccionaban semillas de girasol y pedacitos de corteza para sus nidos, Mico pasaba las tardes mirando por el telescopio que había armado con un carrete de hilo y dos lupas de relojero.\n\n"Voy a construir una nave espacial", anunció una soleada mañana de primavera ante la mirada asombrada de toda su familia. Reunió una caja de cartón de zapatos, dos botones grandes para el panel de navegación, tres tapones de corcho como propulsores y papel aluminio brillante de una tableta de chocolate para proteger el fuselaje del frío intergaláctico.\n\nDurante semanas midió, cortó y ajustó cada detalle con paciencia infinita. Cuando sus patitas estaban cansadas, recordaba las fotografías de cráteres lunares y volvía a sonreír con determinación. Su casco era un dedal plateado con un visor de celofán transparente que le permitía contemplar el infinito.',
        visualConfig: {'theme': 'space_workshop'},
        characterIds: const ['char-mico'],
        seed: 301,
        createdAt: DateTime.parse('2026-10-22T08:30:00Z'),
        updatedAt: DateTime.parse('2026-10-22T08:30:00Z'),
        demoIllustrationAsset: 'assets/demo/demo_dragon.png',
      ),
      StoryPageDetail(
        id: 'page-003-2',
        storyId: 'res-sty-003',
        pageNumber: 2,
        action: 'El despegue imaginario',
        text: 'Llegó el día tan esperado. Colocó su nave en lo alto de la colina de dientes de león, acomodó su pequeña mochila con nueces y encendió su imaginación con una cuenta regresiva que resonó en todo el bosque: "¡Cinco, cuatro, tres, dos, uno... ignición!".\n\nCon un suave soplido del viento y la fuerza de su inmensa ilusión, el cohete comenzó a ascender por encima de las ramas de los robles, atravesó la primera capa de nubes esponjosas y navegó por un océano de estrellas que parecían gemas centelleantes.\n\nDesde su ventanilla, la Tierra se veía como una hermosa canica azul y verde. Mico comprendió entonces la lección más hermosa: no importa qué tan pequeño seas en tamaño, cuando sueñas con todo el corazón, tu mundo no tiene límites.',
        visualConfig: {'theme': 'space_orbit'},
        characterIds: const ['char-mico'],
        seed: 302,
        createdAt: DateTime.parse('2026-10-22T08:35:00Z'),
        updatedAt: DateTime.parse('2026-10-22T08:35:00Z'),
        demoIllustrationAsset: null,
      ),
    ],

    // res-sty-empty: Sin páginas
    'res-sty-empty': [],
  };

  @override
  Future<StoryDetail> getStory(String storyId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (simulateNetworkError || storyId == 'res-sty-error') {
      throw const NetworkFailure(
        message: 'No pudimos conectar con los servidores de Tale Star. Revisa tu conexión a internet.',
      );
    }

    final story = _mockStories[storyId];
    if (story == null) {
      throw const ServerFailure(
        message: 'El cuento solicitado no existe en la biblioteca.',
        statusCode: 404,
      );
    }

    return story;
  }

  @override
  Future<List<StoryPageDetail>> getStoryPages(String storyId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (simulateNetworkError || storyId == 'res-sty-error') {
      throw const NetworkFailure(
        message: 'Error de conexión al cargar las páginas del cuento.',
      );
    }

    final pages = _mockPages[storyId];
    if (pages == null) {
      // Si la historia no existe en el catálogo
      if (!_mockStories.containsKey(storyId)) {
        throw const ServerFailure(
          message: 'Cuento no encontrado.',
          statusCode: 404,
        );
      }
      return [];
    }

    // Retorna ordenadas ascendentemente por page_number
    final sorted = List<StoryPageDetail>.from(pages)
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    return sorted;
  }
}

