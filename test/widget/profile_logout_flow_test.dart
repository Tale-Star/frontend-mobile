import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/storage/preferences_service.dart';
import 'package:startale_mobile/core/theme/theme_cubit.dart';
import 'package:startale_mobile/features/authentication/domain/entities/user_entity.dart';
import 'package:startale_mobile/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:startale_mobile/features/authentication/presentation/cubit/auth_state.dart';
import 'package:startale_mobile/features/child_mode/presentation/cubit/child_mode_cubit.dart';
import 'package:startale_mobile/features/library/presentation/cubit/library_cubit.dart';
import 'package:startale_mobile/features/music/presentation/cubit/music_player_cubit.dart';
import 'package:startale_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:startale_mobile/features/profile/presentation/cubit/profile_state.dart';
import 'package:startale_mobile/features/profile/presentation/screens/profile_tab_screen.dart';
import 'package:startale_mobile/injection.dart';

class MockAuthCubit extends Mock implements AuthCubit {}
class MockProfileCubit extends Mock implements ProfileCubit {}
class MockMusicPlayerCubit extends Mock implements MusicPlayerCubit {}
class MockChildModeCubit extends Mock implements ChildModeCubit {}
class MockLibraryCubit extends Mock implements LibraryCubit {}
class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  late MockAuthCubit mockAuthCubit;
  late MockProfileCubit mockProfileCubit;
  late MockMusicPlayerCubit mockMusicPlayerCubit;
  late MockChildModeCubit mockChildModeCubit;
  late MockLibraryCubit mockLibraryCubit;
  late MockPreferencesService mockPreferencesService;
  late ThemeCubit themeCubit;

  final tUser = UserEntity(
    id: 'user-001',
    email: 'admin@talestar.com',
    displayName: 'Papá Ricardo',
    pinConfigured: true,
    createdAt: DateTime.parse('2026-10-01T10:00:00Z'),
  );

  setUp(() {
    mockAuthCubit = MockAuthCubit();
    mockProfileCubit = MockProfileCubit();
    mockMusicPlayerCubit = MockMusicPlayerCubit();
    mockChildModeCubit = MockChildModeCubit();
    mockLibraryCubit = MockLibraryCubit();
    mockPreferencesService = MockPreferencesService();

    when(() => mockPreferencesService.themeMode).thenReturn('light');
    themeCubit = ThemeCubit(preferencesService: mockPreferencesService);

    when(() => mockAuthCubit.state).thenReturn(Authenticated(tUser));
    when(() => mockAuthCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthCubit.logout()).thenAnswer((_) async {});
    when(() => mockAuthCubit.close()).thenAnswer((_) async {});

    when(() => mockProfileCubit.state).thenReturn(ProfileLoaded(user: tUser));
    when(() => mockProfileCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockProfileCubit.close()).thenAnswer((_) async {});
    when(() => mockProfileCubit.loadProfile(initialUser: any(named: 'initialUser')))
        .thenAnswer((_) async {});

    when(() => mockMusicPlayerCubit.clearSession()).thenAnswer((_) async {});
    when(() => mockChildModeCubit.clearSession()).thenAnswer((_) async {});

    // Registrar en get_it para verificar la cascada de limpieza
    if (sl.isRegistered<ProfileCubit>()) sl.unregister<ProfileCubit>();
    if (sl.isRegistered<MusicPlayerCubit>()) sl.unregister<MusicPlayerCubit>();
    if (sl.isRegistered<ChildModeCubit>()) sl.unregister<ChildModeCubit>();
    if (sl.isRegistered<LibraryCubit>()) sl.unregister<LibraryCubit>();

    sl.registerFactory<ProfileCubit>(() => mockProfileCubit);
    sl.registerLazySingleton<MusicPlayerCubit>(() => mockMusicPlayerCubit);
    sl.registerLazySingleton<ChildModeCubit>(() => mockChildModeCubit);
    sl.registerLazySingleton<LibraryCubit>(() => mockLibraryCubit);
  });

  tearDown(() {
    if (sl.isRegistered<ProfileCubit>()) sl.unregister<ProfileCubit>();
    if (sl.isRegistered<MusicPlayerCubit>()) sl.unregister<MusicPlayerCubit>();
    if (sl.isRegistered<ChildModeCubit>()) sl.unregister<ChildModeCubit>();
    if (sl.isRegistered<LibraryCubit>()) sl.unregister<LibraryCubit>();
  });

  Widget buildTestableWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: mockAuthCubit),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: const MaterialApp(
        home: ProfileTabScreen(),
      ),
    );
  }

  group('Profile Logout Cascade Integration Tests', () {
    testWidgets('confirmar logout ejecuta limpieza atómica de audio, modo niño, biblioteca y auth', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final logoutButton = find.byKey(const Key('profile_logout_button'));
      expect(logoutButton, findsOneWidget);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      expect(find.text('¿Cerrar sesión?'), findsOneWidget);

      final confirmButton = find.byKey(const Key('logout_confirm_button'));
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Verificar que se invocaron las limpiezas de sesión
      verify(() => mockMusicPlayerCubit.clearSession()).called(1);
      verify(() => mockChildModeCubit.clearSession()).called(1);
      verify(() => mockLibraryCubit.clearSession()).called(1);
      verify(() => mockAuthCubit.logout()).called(1);
    });
  });
}
