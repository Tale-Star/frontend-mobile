import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/theme/app_theme.dart';
import 'package:startale_mobile/features/augmented_reality/presentation/cubit/ar_cubit.dart';
import 'package:startale_mobile/features/augmented_reality/presentation/cubit/ar_state.dart';
import 'package:startale_mobile/features/augmented_reality/presentation/screens/ar_story_viewer_screen.dart';
import 'package:startale_mobile/features/reader/domain/entities/story_detail.dart';
import 'package:startale_mobile/features/reader/domain/entities/story_page_detail.dart';

class MockArCubit extends Mock implements ArCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockArCubit mockArCubit;

  final tStory = StoryDetail(
    id: 'story-viewer-1',
    title: 'El Dragón de los Cielos',
    description: 'Cuento de fantasía',
    createdAt: DateTime.parse('2026-11-01T10:00:00Z'),
    updatedAt: DateTime.parse('2026-11-01T10:00:00Z'),
  );

  final tPages = [
    StoryPageDetail(
      id: 'p-1',
      storyId: 'story-viewer-1',
      pageNumber: 1,
      action: 'Apertura',
      text: 'En la cima de la montaña vivía un dragón amable.',
      characterIds: const [],
      visualConfig: const {},
      createdAt: DateTime.parse('2026-11-01T10:00:00Z'),
      updatedAt: DateTime.parse('2026-11-01T10:00:00Z'),
    ),
    StoryPageDetail(
      id: 'p-2',
      storyId: 'story-viewer-1',
      pageNumber: 2,
      action: 'Vuelo',
      text: 'Desplegó sus grandes alas doradas.',
      characterIds: const [],
      visualConfig: const {},
      createdAt: DateTime.parse('2026-11-01T10:01:00Z'),
      updatedAt: DateTime.parse('2026-11-01T10:01:00Z'),
    ),
  ];

  setUp(() {
    mockArCubit = MockArCubit();
    when(() => mockArCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockArCubit.nextPage()).thenReturn(null);
    when(() => mockArCubit.previousPage()).thenReturn(null);
  });

  Widget buildTestWidget({required VoidCallback onExit}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: BlocProvider<ArCubit>.value(
        value: mockArCubit,
        child: ArStoryViewerScreen(
          storyId: 'story-viewer-1',
          onExit: onExit,
        ),
      ),
    );
  }

  group('ArStoryViewerScreen Widget', () {
    testWidgets('renderiza título del cuento, texto narrativo y contador de página', (tester) async {
      when(() => mockArCubit.state).thenReturn(
        ArState(
          status: ArStatus.storyPlaced,
          story: tStory,
          pages: tPages,
          currentPageIndex: 0,
        ),
      );

      await tester.pumpWidget(buildTestWidget(onExit: () {}));
      await tester.pump();

      expect(find.text('El Dragón de los Cielos'), findsOneWidget);
      expect(find.text('Página 1 de 2'), findsOneWidget);
      expect(find.text('En la cima de la montaña vivía un dragón amable.'), findsOneWidget);
    });

    testWidgets('botón siguiente invoca nextPage en el cubit', (tester) async {
      when(() => mockArCubit.state).thenReturn(
        ArState(
          status: ArStatus.storyPlaced,
          story: tStory,
          pages: tPages,
          currentPageIndex: 0,
        ),
      );

      await tester.pumpWidget(buildTestWidget(onExit: () {}));
      await tester.pump();

      final nextBtn = find.byKey(const Key('ar_next_page_button'));
      expect(nextBtn, findsOneWidget);

      await tester.tap(nextBtn);
      await tester.pump();

      verify(() => mockArCubit.nextPage()).called(1);
    });

    testWidgets('botón salir invoca callback onExit', (tester) async {
      bool exitCalled = false;

      when(() => mockArCubit.state).thenReturn(
        ArState(
          status: ArStatus.storyPlaced,
          story: tStory,
          pages: tPages,
          currentPageIndex: 0,
        ),
      );

      await tester.pumpWidget(buildTestWidget(onExit: () {
        exitCalled = true;
      }));
      await tester.pump();

      final exitBtn = find.byKey(const Key('ar_viewer_exit_button'));
      expect(exitBtn, findsOneWidget);

      await tester.tap(exitBtn);
      await tester.pump();

      expect(exitCalled, isTrue);
    });
  });
}

