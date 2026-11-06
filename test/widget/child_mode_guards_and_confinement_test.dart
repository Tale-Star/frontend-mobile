import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/storage/preferences_service.dart';
import 'package:startale_mobile/core/theme/theme_cubit.dart';
import 'package:startale_mobile/features/authentication/domain/entities/user_entity.dart';
import 'package:startale_mobile/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:startale_mobile/features/authentication/presentation/cubit/auth_state.dart';
import 'package:startale_mobile/features/child_mode/domain/entities/child_mode_content.dart';
import 'package:startale_mobile/features/child_mode/domain/repositories/parental_pin_repository.dart';
import 'package:startale_mobile/features/child_mode/presentation/cubit/child_mode_cubit.dart';
import 'package:startale_mobile/features/child_mode/presentation/screens/pin_setup_screen.dart';
import 'package:startale_mobile/features/child_mode/presentation/widgets/child_mode_active_badge.dart';
import 'package:startale_mobile/features/library/domain/entities/library_item_entity.dart';
import 'package:startale_mobile/features/library/presentation/cubit/library_cubit.dart';
import 'package:startale_mobile/features/library/presentation/cubit/library_state.dart';
import 'package:startale_mobile/features/library/presentation/screens/image_viewer_screen.dart';
import 'package:startale_mobile/features/music/domain/entities/music_track.dart';
import 'package:startale_mobile/features/music/presentation/cubit/music_player_cubit.dart';
import 'package:startale_mobile/features/music/presentation/cubit/music_player_state.dart';
import 'package:startale_mobile/features/music/presentation/screens/music_player_screen.dart';
import 'package:startale_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:startale_mobile/features/profile/presentation/cubit/profile_state.dart';
import 'package:startale_mobile/features/profile/presentation/screens/profile_tab_screen.dart';
import 'package:startale_mobile/features/reader/domain/entities/story_detail.dart';
import 'package:startale_mobile/features/reader/domain/entities/story_page_detail.dart';
import 'package:startale_mobile/features/reader/presentation/cubit/reader_cubit.dart';
import 'package:startale_mobile/features/reader/presentation/cubit/reader_state.dart';
import 'package:startale_mobile/features/reader/presentation/screens/story_reader_screen.dart';
import 'package:startale_mobile/injection.dart';

class MockParentalPinRepository extends Mock implements ParentalPinRepository {}
class MockPreferencesService extends Mock implements PreferencesService {}
class MockAuthCubit extends Mock implements AuthCubit {}
class MockReaderCubit extends MockCubit<ReaderState> implements ReaderCubit {}
class MockLibraryCubit extends Mock implements LibraryCubit {}
class MockMusicPlayerCubit extends Mock implements MusicPlayerCubit {}
class MockProfileCubit extends Mock implements ProfileCubit {}

void main() {
  late MockParentalPinRepository mockPinRepo;
  late MockPreferencesService mockPrefs;
  late MockAuthCubit mockAuthCubit;
  late MockReaderCubit mockReaderCubit;
  late MockLibraryCubit mockLibraryCubit;
  late MockMusicPlayerCubit mockMusicPlayerCubit;
  late MockProfileCubit mockProfileCubit;
  late ChildModeCubit childModeCubit;
  late ThemeCubit themeCubit;

  final tUser = UserEntity(
    id: 'user-001',
    email: 'padre@talestar.app',
    displayName: 'Padre Demo',
    pinConfigured: true,
    createdAt: DateTime.parse('2026-10-31T12:00:00Z'),
  );

  final tStory = StoryDetail(
    id: 'story-123',
    title: 'La Pequeña Estrella Perdida',
    description: 'Un cuento espacial',
    createdAt: DateTime.parse('2026-10-31T10:00:00Z'),
    updatedAt: DateTime.parse('2026-10-31T10:00:00Z'),
  );

  final tPage1 = StoryPageDetail(
    id: 'p1',
    storyId: 'story-123',
    pageNumber: 1,
    text: 'Había una vez una pequeña estrella.',
    action: 'Mira al cielo nocturno.',
    characterIds: const [],
    visualConfig: const {},
    createdAt: DateTime.parse('2026-10-31T10:00:00Z'),
    updatedAt: DateTime.parse('2026-10-31T10:00:00Z'),
  );

  setUp(() async {
    await resetDependencies();

    mockPinRepo = MockParentalPinRepository();
    mockPrefs = MockPreferencesService();
    mockAuthCubit = MockAuthCubit();
    mockReaderCubit = MockReaderCubit();
    mockLibraryCubit = MockLibraryCubit();
    mockMusicPlayerCubit = MockMusicPlayerCubit();
    mockProfileCubit = MockProfileCubit();

    when(() => mockProfileCubit.state).thenReturn(ProfileLoaded(user: tUser));
    when(() => mockProfileCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockProfileCubit.close()).thenAnswer((_) async {});
    when(() => mockProfileCubit.loadProfile(initialUser: any(named: 'initialUser')))
        .thenAnswer((_) async {});
    when(() => mockProfileCubit.refresh()).thenAnswer((_) async {});

    when(() => mockPrefs.isChildModeActive).thenReturn(false);
    when(() => mockPrefs.themeMode).thenReturn('light');
    when(() => mockPrefs.setThemeMode(any())).thenAnswer((_) async => true);
    themeCubit = ThemeCubit(preferencesService: mockPrefs);
    when(() => mockPrefs.saveChildModeSession(
          contentType: any(named: 'contentType'),
          contentId: any(named: 'contentId'),
          title: any(named: 'title'),
          routeContext: any(named: 'routeContext'),
          userId: any(named: 'userId'),
        )).thenAnswer((_) async {});
    when(() => mockPrefs.clearChildModeSession()).thenAnswer((_) async {});

    when(() => mockAuthCubit.state).thenReturn(Authenticated(tUser));
    when(() => mockAuthCubit.stream).thenAnswer((_) => Stream.value(Authenticated(tUser)));

    when(() => mockReaderCubit.state).thenReturn(ReaderLoaded(
      story: tStory,
      pages: [tPage1],
      currentPageIndex: 0,
    ));
    when(() => mockReaderCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockReaderCubit.loadStory(any())).thenAnswer((_) async {});

    when(() => mockLibraryCubit.state).thenReturn(const LibraryInitial());
    when(() => mockLibraryCubit.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockMusicPlayerCubit.state).thenReturn(const MusicPlayerState());
    when(() => mockMusicPlayerCubit.stream).thenAnswer((_) => const Stream.empty());

    childModeCubit = ChildModeCubit(
      parentalPinRepository: mockPinRepo,
      preferencesService: mockPrefs,
      authCubit: mockAuthCubit,
    );

    sl.registerLazySingleton<ReaderCubit>(() => mockReaderCubit);
    sl.registerLazySingleton<ParentalPinRepository>(() => mockPinRepo);
    sl.registerLazySingleton<ChildModeCubit>(() => childModeCubit);
    sl.registerFactory<ProfileCubit>(() => mockProfileCubit);
  });

  tearDown(() async {
    childModeCubit.close();
    themeCubit.close();
    await resetDependencies();
  });

  Widget buildAppWith(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: themeCubit),
        BlocProvider<AuthCubit>.value(value: mockAuthCubit),
        BlocProvider<ChildModeCubit>.value(value: childModeCubit),
        BlocProvider<LibraryCubit>.value(value: mockLibraryCubit),
        BlocProvider<MusicPlayerCubit>.value(value: mockMusicPlayerCubit),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('Child Mode Confinement & Guards Widget Tests', () {
    testWidgets('StoryReaderScreen muestra botón activar modo niño cuando está inactivo', (tester) async {
      await tester.pumpWidget(buildAppWith(const StoryReaderScreen(storyId: 'story-123')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reader_child_mode_button')), findsOneWidget);
      expect(find.byType(ChildModeActiveBadge), findsNothing);
    });

    testWidgets('StoryReaderScreen muestra ChildModeActiveBadge cuando el modo está activo', (tester) async {
      await childModeCubit.activate(
        contentType: ChildModeContentType.story,
        contentId: 'story-123',
        contentTitle: 'La Pequeña Estrella Perdida',
        routeContext: '/stories/story-123/read',
      );

      await tester.pumpWidget(buildAppWith(const StoryReaderScreen(storyId: 'story-123')));
      await tester.pumpAndSettle();

      expect(find.byType(ChildModeActiveBadge), findsOneWidget);
      expect(find.byKey(const Key('reader_child_mode_button')), findsNothing);
    });

    testWidgets('StoryReaderScreen pulsar atrás con modo activo abre diálogo de PIN', (tester) async {
      await childModeCubit.activate(
        contentType: ChildModeContentType.story,
        contentId: 'story-123',
        contentTitle: 'La Pequeña Estrella Perdida',
        routeContext: '/stories/story-123/read',
      );

      await tester.pumpWidget(buildAppWith(const StoryReaderScreen(storyId: 'story-123')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('reader_back_button')));
      await tester.pumpAndSettle();

      expect(find.text('PIN Parental'), findsOneWidget);
      expect(find.text('Ingresa el PIN de 4 dígitos para salir de Modo Niño.'), findsOneWidget);
    });

    testWidgets('ImageViewerScreen muestra badge y confina salida en Modo Niño', (tester) async {
      final tItem = LibraryItemEntity(
        id: 'img-001',
        name: 'Estrella fugaz',
        type: ContentType.image,
        resourceId: 'res-img-001',
        description: 'Una bella ilustración',
        resourceUrl: 'https://example.com/star.png',
        favorite: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await childModeCubit.activate(
        contentType: ChildModeContentType.image,
        contentId: 'img-001',
        contentTitle: 'Estrella fugaz',
        routeContext: '/media/image/img-001',
      );

      await tester.pumpWidget(buildAppWith(ImageViewerScreen(imageId: 'img-001', initialItem: tItem)));
      await tester.pump();

      expect(find.byType(ChildModeActiveBadge), findsOneWidget);

      await tester.tap(find.byKey(const Key('viewer_back_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PIN Parental'), findsOneWidget);
    });

    testWidgets('MusicPlayerScreen muestra badge y confina salida en Modo Niño', (tester) async {
      final tTrack = MusicTrack(
        id: 'track-001',
        resourceId: 'res-001',
        name: 'Melodía de la Noche',
        resourceUrl: 'https://example.com/audio.flac',
        mediaType: 'audio/flac',
      );

      when(() => mockMusicPlayerCubit.state).thenReturn(
        MusicPlayerState(currentTrack: tTrack),
      );

      await childModeCubit.activate(
        contentType: ChildModeContentType.music,
        contentId: 'track-001',
        contentTitle: 'Melodía de la Noche',
        routeContext: '/music/player',
      );

      await tester.pumpWidget(buildAppWith(const MusicPlayerScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ChildModeActiveBadge), findsOneWidget);

      await tester.tap(find.byKey(const Key('player_back_button')));
      await tester.pumpAndSettle();

      expect(find.text('PIN Parental'), findsOneWidget);
    });

    testWidgets('ProfileTabScreen navegar a configuración de PIN parental', (tester) async {
      await tester.pumpWidget(buildAppWith(const ProfileTabScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_pin_card')), findsOneWidget);

      await tester.tap(find.byKey(const Key('profile_pin_card')));
      await tester.pumpAndSettle();

      expect(find.byType(PinSetupScreen), findsOneWidget);
    });
  });
}
