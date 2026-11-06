import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/router/route_names.dart';
import 'package:startale_mobile/features/library/domain/entities/library_item_entity.dart';
import 'package:startale_mobile/features/library/presentation/cubit/library_cubit.dart';
import 'package:startale_mobile/features/library/presentation/cubit/library_state.dart';
import 'package:startale_mobile/features/library/presentation/screens/library_screen.dart';
import 'package:startale_mobile/features/library/presentation/screens/stories_tab_screen.dart';

class MockLibraryCubit extends MockCubit<LibraryState> implements LibraryCubit {}

void main() {
  late MockLibraryCubit mockLibraryCubit;

  final tStoryItem = LibraryItemEntity(
    id: 'lib-item-1',
    type: ContentType.story,
    resourceId: 'res-sty-001',
    name: 'El Pequeño Astronauta',
    description: 'Aventura por las estrellas.',
    favorite: false,
    resourceUrl: '/api/v1/stories/res-sty-001',
    createdAt: DateTime.parse('2026-10-31T10:00:00.000Z'),
    updatedAt: DateTime.parse('2026-10-31T10:00:00.000Z'),
  );

  setUp(() {
    mockLibraryCubit = MockLibraryCubit();
    when(() => mockLibraryCubit.loadLibrary(type: any(named: 'type'))).thenAnswer((_) async {});
  });

  Widget buildRouterForStoriesTab() {
    final router = GoRouter(
      initialLocation: '/stories',
      routes: [
        GoRoute(
          path: '/stories',
          name: RouteNames.stories,
          builder: (context, state) => BlocProvider<LibraryCubit>.value(
            value: mockLibraryCubit,
            child: const StoriesTabScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.readerPath,
          name: RouteNames.reader,
          builder: (context, state) {
            final storyId = state.pathParameters['storyId'] ?? '';
            return Scaffold(
              body: Center(
                child: Text('ReaderScreen storyId: $storyId'),
              ),
            );
          },
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  Widget buildRouterForLibraryScreen() {
    final router = GoRouter(
      initialLocation: '/library',
      routes: [
        GoRoute(
          path: '/library',
          name: RouteNames.library,
          builder: (context, state) => BlocProvider<LibraryCubit>.value(
            value: mockLibraryCubit,
            child: const LibraryScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.readerPath,
          name: RouteNames.reader,
          builder: (context, state) {
            final storyId = state.pathParameters['storyId'] ?? '';
            return Scaffold(
              body: Center(
                child: Text('ReaderScreen storyId: $storyId'),
              ),
            );
          },
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  group('Navegación hacia el Lector de Cuentos (Fase 3)', () {
    testWidgets('tocar una tarjeta de cuento en StoriesTabScreen navega hacia el Lector con resourceId', (tester) async {
      when(() => mockLibraryCubit.state).thenReturn(
        LibraryLoaded(items: [tStoryItem]),
      );

      await tester.pumpWidget(buildRouterForStoriesTab());
      await tester.pumpAndSettle();

      expect(find.text('El Pequeño Astronauta'), findsOneWidget);

      await tester.tap(find.byKey(Key('story_card_${tStoryItem.id}')));
      await tester.pumpAndSettle();

      expect(find.text('ReaderScreen storyId: res-sty-001'), findsOneWidget);
    });

    testWidgets('tocar un cuento en LibraryScreen navega directamente hacia el Lector con resourceId', (tester) async {
      when(() => mockLibraryCubit.state).thenReturn(
        LibraryLoaded(items: [tStoryItem]),
      );

      await tester.pumpWidget(buildRouterForLibraryScreen());
      await tester.pumpAndSettle();

      expect(find.text('El Pequeño Astronauta'), findsOneWidget);

      await tester.tap(find.text('El Pequeño Astronauta'));
      await tester.pumpAndSettle();

      expect(find.text('ReaderScreen storyId: res-sty-001'), findsOneWidget);
    });
  });
}

