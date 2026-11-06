import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:startale_mobile/core/theme/app_theme.dart';
import 'package:startale_mobile/features/augmented_reality/presentation/widgets/ar_story_card_3d.dart';
import 'package:startale_mobile/features/augmented_reality/presentation/widgets/ar_top_bar.dart';
import 'package:startale_mobile/features/reader/domain/entities/story_page_detail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tLongNarrative =
      'Había una vez, en el rincón más brillante del firmamento, una pequeña estrella llamada Estelita. '
      'A diferencia de las estrellas mayores que preferían permanecer quietas titilando en su sitio, '
      'Estelita adoraba bailar al ritmo del viento cósmico y asomarse curiosa a mirar las copas de los árboles en la Tierra.\n\n'
      'Una noche de luna plateada, un destello juguetón la hizo descender más de la cuenta. Cuando quiso regresar, '
      'la distancia parecía infinita. Fue entonces cuando divisó una fortaleza de piedra blanca que flotaba '
      'serenamente sobre las nubes, habitada por aves guardianas que cuidaban el descanso nocturno de los niños.\n\n'
      'Con la tierna ayuda de una bandada de golondrinas estelares y el brillo de miles de luciérnagas amigas, '
      'Estelita tomó un suave impulso y trepó por un arcoíris nocturno de vuelta a su hogar.';

  final tPage1 = StoryPageDetail(
    id: 'page-1',
    storyId: 'story-1',
    pageNumber: 1,
    action: 'Inicio',
    text: tLongNarrative,
    characterIds: const [],
    visualConfig: const {},
    createdAt: DateTime.parse('2026-11-01T10:00:00Z'),
    updatedAt: DateTime.parse('2026-11-01T10:00:00Z'),
    demoIllustrationAsset: 'assets/demo/demo_forest.png',
  );

  final tPage2 = StoryPageDetail(
    id: 'page-2',
    storyId: 'story-1',
    pageNumber: 2,
    action: 'Segunda página',
    text: 'Texto breve de la segunda página para verificar el reinicio del scroll.',
    characterIds: const [],
    visualConfig: const {},
    createdAt: DateTime.parse('2026-11-01T10:01:00Z'),
    updatedAt: DateTime.parse('2026-11-01T10:01:00Z'),
    demoIllustrationAsset: 'assets/demo/demo_castle.png',
  );

  Widget buildCardWidget({
    required StoryPageDetail page,
    required int pageNumber,
    required ValueChanged<double> onScaleChanged,
    required void Function(double, double) onRotationChanged,
    required VoidCallback onResetTransform,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: ArStoryCard3d(
            page: page,
            pageNumber: pageNumber,
            totalPages: 3,
            scale: 1.0,
            rotationY: 0.0,
            rotationX: 0.0,
            onScaleChanged: onScaleChanged,
            onRotationChanged: onRotationChanged,
            onResetTransform: onResetTransform,
          ),
        ),
      ),
    );
  }

  group('ArStoryCard3d - Área Narrativa Desplazable y Ausencia de Truncamiento', () {
    testWidgets('renderiza texto narrativo extenso completo sin ellipsis', (tester) async {
      await tester.pumpWidget(buildCardWidget(
        page: tPage1,
        pageNumber: 1,
        onScaleChanged: (_) {},
        onRotationChanged: (_, _) {},
        onResetTransform: () {},
      ));
      await tester.pumpAndSettle();

      final textFinder = find.byKey(const Key('ar_page_narrative_text'));
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.maxLines, isNull);
      expect(textWidget.overflow, isNull);
      expect(textWidget.data, contains('Estelita tomó un suave impulso'));
    });

    testWidgets('área narrativa se desplaza verticalmente hasta el final del texto', (tester) async {
      await tester.pumpWidget(buildCardWidget(
        page: tPage1,
        pageNumber: 1,
        onScaleChanged: (_) {},
        onRotationChanged: (_, _) {},
        onResetTransform: () {},
      ));
      await tester.pumpAndSettle();

      final scrollableFinder = find.byType(SingleChildScrollView);
      expect(scrollableFinder, findsOneWidget);

      // Desplazar hacia arriba para leer el final del texto
      await tester.drag(scrollableFinder, const Offset(0, -300));
      await tester.pumpAndSettle();

      // El último párrafo debe permanecer renderizado sin errores
      expect(find.textContaining('arcoíris nocturno'), findsOneWidget);
    });

    testWidgets('cambio de página reinicia la posición del scroll', (tester) async {
      await tester.pumpWidget(buildCardWidget(
        page: tPage1,
        pageNumber: 1,
        onScaleChanged: (_) {},
        onRotationChanged: (_, _) {},
        onResetTransform: () {},
      ));
      await tester.pumpAndSettle();

      final scrollableFinder = find.byType(SingleChildScrollView);
      await tester.drag(scrollableFinder, const Offset(0, -250));
      await tester.pumpAndSettle();

      // Cambiar a la página 2
      await tester.pumpWidget(buildCardWidget(
        page: tPage2,
        pageNumber: 2,
        onScaleChanged: (_) {},
        onRotationChanged: (_, _) {},
        onResetTransform: () {},
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Texto breve de la segunda página'), findsOneWidget);
    });

    testWidgets('gesto de arrastre sobre la ilustración dispara onRotationChanged', (tester) async {
      double lastRotY = 0.0;

      await tester.pumpWidget(buildCardWidget(
        page: tPage1,
        pageNumber: 1,
        onScaleChanged: (_) {},
        onRotationChanged: (rotY, _) {
          lastRotY = rotY;
        },
        onResetTransform: () {},
      ));
      await tester.pumpAndSettle();

      final illustrationGesture = find.byKey(const Key('ar_story_card_illustration_gesture'));
      expect(illustrationGesture, findsOneWidget);

      await tester.drag(illustrationGesture, const Offset(60, 0));
      await tester.pumpAndSettle();

      expect(lastRotY, isNot(0.0));
    });
  });

  group('ArTopBar - Encabezado Responsivo sin Truncamiento de Título Extenso', () {
    testWidgets('título extenso como "La Pequeña Estrella Perdida" se renderiza completamente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ArTopBar(
              onExit: () {},
              title: 'La Pequeña Estrella Perdida',
              subtitle: 'Página 3 de 3',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('La Pequeña Estrella Perdida'), findsOneWidget);
      expect(find.text('Página 3 de 3'), findsOneWidget);

      final titleWidget = tester.widget<Text>(find.byKey(const Key('ar_top_chip_text')));
      expect(titleWidget.maxLines, equals(2));
    });
  });
}

