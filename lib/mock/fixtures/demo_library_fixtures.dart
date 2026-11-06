/// Fixtures JSON representativos para el Modo Demostración de Tale Star.
///
/// Cumplen estrictamente con el contrato del backend oficial `LibraryItemResponse`.
/// No contienen credenciales, URLs privadas ni tokens de acceso.
const List<Map<String, dynamic>> kDemoLibraryFixtures = [
  // ---------------------------------------------------------------------------
  // Imágenes Ilustradas (Con assets locales para visor a pantalla completa y zoom)
  // ---------------------------------------------------------------------------
  {
    'id': 'img-demo-001',
    'type': 'image',
    'resource_id': 'res-img-001',
    'name': 'El Bosque de las Luciérnagas',
    'description': 'Un sendero nocturno mágico iluminado por miles de estrellas y luciérnagas doradas.',
    'favorite': true,
    'resource_url': 'assets/demo/demo_forest.png',
    'media_type': 'image/png',
    'created_at': '2026-11-01T14:30:00Z',
    'updated_at': '2026-11-01T14:30:00Z',
  },
  {
    'id': 'img-demo-002',
    'type': 'image',
    'resource_id': 'res-img-002',
    'name': 'El Castillo entre las Nubes',
    'description': 'Una fortaleza celestial donde habitan los guardianes del viento y las aves viajeras.',
    'favorite': false,
    'resource_url': 'assets/demo/demo_castle.png',
    'media_type': 'image/png',
    'created_at': '2026-10-29T10:15:00Z',
    'updated_at': '2026-10-29T10:15:00Z',
  },
  {
    'id': 'img-demo-003',
    'type': 'image',
    'resource_id': 'res-img-003',
    'name': 'Viaje por la Galaxia Púrpura',
    'description': 'Un pequeño cohete surcando nebulosas misteriosas y polvo de estrellas cósmico.',
    'favorite': true,
    'resource_url': 'assets/demo/demo_space.png',
    'media_type': 'image/png',
    'created_at': '2026-10-25T18:40:00Z',
    'updated_at': '2026-10-25T18:40:00Z',
  },
  {
    'id': 'img-demo-004',
    'type': 'image',
    'resource_id': 'res-img-004',
    'name': 'El Dragón Amigo de los Libros',
    'description': 'Un dragón bondadoso y sonriente que cuida una inmensa biblioteca milenaria.',
    'favorite': false,
    'resource_url': 'assets/demo/demo_dragon.png',
    'media_type': 'image/png',
    'created_at': '2026-10-20T09:00:00Z',
    'updated_at': '2026-10-20T09:00:00Z',
  },

  // ---------------------------------------------------------------------------
  // Cuentos Educativos (Muestran diálogo informativo hacia Fase 3)
  // ---------------------------------------------------------------------------
  {
    'id': 'sty-demo-001',
    'type': 'story',
    'resource_id': 'res-sty-001',
    'name': 'La Pequeña Estrella Perdida',
    'description': 'Una emotiva aventura sobre la curiosidad, el valor y cómo encontrar el camino a casa.',
    'favorite': true,
    'resource_url': '/api/v1/stories/res-sty-001',
    'media_type': null,
    'created_at': '2026-10-31T11:00:00Z',
    'updated_at': '2026-10-31T11:00:00Z',
  },
  {
    'id': 'sty-demo-002',
    'type': 'story',
    'resource_id': 'res-sty-002',
    'name': 'El Secreto del Relojero del Tiempo',
    'description': 'Un relato sobre la paciencia, la empatía y la magia de los segundos compartidos.',
    'favorite': false,
    'resource_url': '/api/v1/stories/res-sty-002',
    'media_type': null,
    'created_at': '2026-10-28T16:20:00Z',
    'updated_at': '2026-10-28T16:20:00Z',
  },
  {
    'id': 'sty-demo-003',
    'type': 'story',
    'resource_id': 'res-sty-003',
    'name': 'Las Aventuras del Ratón Astronauta',
    'description': 'Mico construye su nave de cartón para explorar los cráteres de queso lunar.',
    'favorite': true,
    'resource_url': '/api/v1/stories/res-sty-003',
    'media_type': null,
    'created_at': '2026-10-22T08:30:00Z',
    'updated_at': '2026-10-22T08:30:00Z',
  },

  // ---------------------------------------------------------------------------
  // Música y Melodías (Muestran diálogo informativo hacia Fase 4)
  // ---------------------------------------------------------------------------
  {
    'id': 'mus-demo-001',
    'type': 'music',
    'resource_id': 'res-mus-001',
    'name': 'Canción de Cuna Cósmica',
    'description': 'Melodía suave con piano y arpa para inducir la calma y el descanso reparador.',
    'favorite': true,
    'resource_url': '/api/v1/media/assets/res-mus-001',
    'media_type': 'audio/flac',
    'created_at': '2026-10-30T21:00:00Z',
    'updated_at': '2026-10-30T21:00:00Z',
  },
  {
    'id': 'mus-demo-002',
    'type': 'music',
    'resource_id': 'res-mus-002',
    'name': 'La Marcha de los Juguetes Traviesos',
    'description': 'Ritmo alegre y juguetón con xilófonos y campanas para momentos de creatividad.',
    'favorite': false,
    'resource_url': '/api/v1/media/assets/res-mus-002',
    'media_type': 'audio/flac',
    'created_at': '2026-10-26T15:10:00Z',
    'updated_at': '2026-10-26T15:10:00Z',
  },
  {
    'id': 'mus-demo-003',
    'type': 'music',
    'resource_id': 'res-mus-003',
    'name': 'Sinfonía del Bosque Encantado',
    'description': 'Acústica con flauta traversa y violonchelo que recrea el susurro del viento.',
    'favorite': false,
    'resource_url': '/api/v1/media/assets/res-mus-003',
    'media_type': 'audio/flac',
    'created_at': '2026-10-21T12:00:00Z',
    'updated_at': '2026-10-21T12:00:00Z',
  },
];

