import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/app_config.dart';
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/preferences_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/authentication/data/datasources/auth_remote_datasource.dart';
import 'features/authentication/data/repositories/auth_repository_impl.dart';
import 'features/authentication/domain/repositories/auth_repository.dart';
import 'features/authentication/presentation/cubit/auth_cubit.dart';
import 'features/augmented_reality/data/services/ar_native_service_impl.dart';
import 'features/augmented_reality/data/services/mock_ar_service.dart';
import 'features/augmented_reality/domain/repositories/ar_service.dart';
import 'features/augmented_reality/presentation/cubit/ar_cubit.dart';
import 'features/library/data/datasources/library_remote_datasource.dart';
import 'features/library/data/repositories/library_repository_impl.dart';
import 'features/library/domain/repositories/library_repository.dart';
import 'features/library/presentation/cubit/library_cubit.dart';
import 'features/music/data/repositories/music_repository_impl.dart';
import 'features/music/data/services/audio_player_service.dart';
import 'features/music/data/services/just_audio_player_service_impl.dart';
import 'features/music/domain/repositories/music_repository.dart';
import 'features/music/presentation/cubit/music_player_cubit.dart';
import 'features/reader/data/datasources/reader_remote_datasource.dart';
import 'features/reader/data/repositories/reader_repository_impl.dart';
import 'features/reader/domain/repositories/reader_repository.dart';
import 'features/reader/presentation/cubit/reader_cubit.dart';
import 'mock/mock_auth_repository.dart';
import 'mock/mock_library_repository.dart';
import 'mock/mock_music_repository.dart';
import 'mock/mock_parental_pin_repository.dart';
import 'mock/mock_reader_repository.dart';
import 'features/child_mode/data/datasources/parental_pin_remote_datasource.dart';
import 'features/child_mode/data/repositories/parental_pin_repository_impl.dart';
import 'features/child_mode/domain/repositories/parental_pin_repository.dart';
import 'features/child_mode/presentation/cubit/child_mode_cubit.dart';
import 'core/theme/theme_cubit.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';

final GetIt sl = GetIt.instance;

/// Inicialización del contenedor de inyección de dependencias con get_it.
Future<void> initDependencies({
  SharedPreferences? testPrefs,
  SecureStorageService? testSecureStorage,
  Dio? testDio,
  AuthRemoteDataSource? testAuthRemoteDataSource,
  AuthRepository? testAuthRepository,
  AuthCubit? testAuthCubit,
  LibraryRemoteDataSource? testLibraryRemoteDataSource,
  LibraryRepository? testLibraryRepository,
  LibraryCubit? testLibraryCubit,
  ReaderRemoteDataSource? testReaderRemoteDataSource,
  ReaderRepository? testReaderRepository,
  ReaderCubit? testReaderCubit,
  AudioPlayerService? testAudioPlayerService,
  MusicRepository? testMusicRepository,
  MusicPlayerCubit? testMusicPlayerCubit,
  ArService? testArService,
  ArCubit? testArCubit,
  ParentalPinRemoteDataSource? testParentalPinRemoteDataSource,
  ParentalPinRepository? testParentalPinRepository,
  ChildModeCubit? testChildModeCubit,
  ThemeCubit? testThemeCubit,
  ProfileCubit? testProfileCubit,
}) async {
  // ---------------------------------------------------------------------------
  // Servicios de Almacenamiento
  // ---------------------------------------------------------------------------
  final prefs = testPrefs ?? await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<PreferencesService>(() => PreferencesService(sl()));

  final secureStorage = testSecureStorage ?? SecureStorageService();
  sl.registerLazySingleton<SecureStorageService>(() => secureStorage);

  // ---------------------------------------------------------------------------
  // Red y HTTP (Dio)
  // ---------------------------------------------------------------------------
  if (testDio != null) {
    sl.registerLazySingleton<Dio>(() => testDio);
  } else {
    final dioClient = DioClient(
      secureStorageService: sl(),
      onUnauthorized: () {
        if (sl.isRegistered<AuthCubit>()) {
          sl<AuthCubit>().logout();
        }
        if (sl.isRegistered<MusicPlayerCubit>()) {
          sl<MusicPlayerCubit>().clearSession();
        }
        if (sl.isRegistered<ChildModeCubit>()) {
          sl<ChildModeCubit>().clearSession();
        }
      },
    );
    sl.registerLazySingleton<DioClient>(() => dioClient);
    sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);
  }

  // ---------------------------------------------------------------------------
  // Autenticación (Fase 1)
  // ---------------------------------------------------------------------------
  if (testAuthRemoteDataSource != null) {
    sl.registerLazySingleton<AuthRemoteDataSource>(() => testAuthRemoteDataSource);
  } else {
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(dio: sl()),
    );
  }

  final bool useMock = AppConfig.instance.useMockData;

  if (testAuthRepository != null) {
    sl.registerLazySingleton<AuthRepository>(() => testAuthRepository);
  } else if (useMock) {
    sl.registerLazySingleton<AuthRepository>(
      () => MockAuthRepository(
        secureStorageService: sl(),
        preferencesService: sl(),
      ),
    );
  } else {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: sl(),
        secureStorageService: sl(),
        preferencesService: sl(),
      ),
    );
  }

  if (testAuthCubit != null) {
    sl.registerLazySingleton<AuthCubit>(() => testAuthCubit);
  } else {
    sl.registerLazySingleton<AuthCubit>(
      () => AuthCubit(authRepository: sl()),
    );
  }

  // ---------------------------------------------------------------------------
  // Biblioteca y Contenido (Fase 2)
  // ---------------------------------------------------------------------------
  if (testLibraryRemoteDataSource != null) {
    sl.registerLazySingleton<LibraryRemoteDataSource>(() => testLibraryRemoteDataSource);
  } else {
    sl.registerLazySingleton<LibraryRemoteDataSource>(
      () => LibraryRemoteDataSourceImpl(dio: sl()),
    );
  }

  if (testLibraryRepository != null) {
    sl.registerLazySingleton<LibraryRepository>(() => testLibraryRepository);
  } else if (useMock) {
    sl.registerLazySingleton<LibraryRepository>(
      () => MockLibraryRepository(),
    );
  } else {
    sl.registerLazySingleton<LibraryRepository>(
      () => LibraryRepositoryImpl(remoteDataSource: sl()),
    );
  }

  if (testLibraryCubit != null) {
    sl.registerLazySingleton<LibraryCubit>(() => testLibraryCubit);
  } else {
    sl.registerLazySingleton<LibraryCubit>(
      () => LibraryCubit(libraryRepository: sl()),
    );
  }

  // ---------------------------------------------------------------------------
  // Lector de Cuentos (Fase 3)
  // ---------------------------------------------------------------------------
  if (testReaderRemoteDataSource != null) {
    sl.registerLazySingleton<ReaderRemoteDataSource>(() => testReaderRemoteDataSource);
  } else {
    sl.registerLazySingleton<ReaderRemoteDataSource>(
      () => ReaderRemoteDataSourceImpl(dio: sl()),
    );
  }

  if (testReaderRepository != null) {
    sl.registerLazySingleton<ReaderRepository>(() => testReaderRepository);
  } else if (useMock) {
    sl.registerLazySingleton<ReaderRepository>(
      () => MockReaderRepository(),
    );
  } else {
    sl.registerLazySingleton<ReaderRepository>(
      () => ReaderRepositoryImpl(remoteDataSource: sl()),
    );
  }

  sl.registerFactory<ReaderCubit>(
    () => testReaderCubit ?? ReaderCubit(readerRepository: sl()),
  );

  // ---------------------------------------------------------------------------
  // Reproductor Musical FLAC (Fase 4)
  // ---------------------------------------------------------------------------
  if (testAudioPlayerService != null) {
    sl.registerLazySingleton<AudioPlayerService>(() => testAudioPlayerService);
  } else {
    sl.registerLazySingleton<AudioPlayerService>(
      () => JustAudioPlayerServiceImpl(),
    );
  }

  if (testMusicRepository != null) {
    sl.registerLazySingleton<MusicRepository>(() => testMusicRepository);
  } else if (useMock) {
    sl.registerLazySingleton<MusicRepository>(
      () => MockMusicRepository(),
    );
  } else {
    sl.registerLazySingleton<MusicRepository>(
      () => MusicRepositoryImpl(remoteDataSource: sl()),
    );
  }

  if (testMusicPlayerCubit != null) {
    sl.registerLazySingleton<MusicPlayerCubit>(() => testMusicPlayerCubit);
  } else {
    sl.registerLazySingleton<MusicPlayerCubit>(
      () => MusicPlayerCubit(
        audioPlayerService: sl(),
        secureStorageService: sl(),
        musicRepository: sl(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Realidad Aumentada (Fase 5)
  // ---------------------------------------------------------------------------
  if (testArService != null) {
    sl.registerLazySingleton<ArService>(() => testArService);
  } else if (AppConfig.instance.useMockAr) {
    sl.registerLazySingleton<ArService>(() => MockArService());
  } else {
    sl.registerLazySingleton<ArService>(() => ArNativeServiceImpl());
  }

  sl.registerFactory<ArCubit>(
    () => testArCubit ?? ArCubit(
      arService: sl(),
      readerRepository: sl(),
    ),
  );

  // ---------------------------------------------------------------------------
  // Modo Niño y Seguridad por PIN Parental (Fase 6)
  // ---------------------------------------------------------------------------
  if (testParentalPinRemoteDataSource != null) {
    sl.registerLazySingleton<ParentalPinRemoteDataSource>(
      () => testParentalPinRemoteDataSource,
    );
  } else {
    sl.registerLazySingleton<ParentalPinRemoteDataSource>(
      () => ParentalPinRemoteDataSourceImpl(dio: sl()),
    );
  }

  if (testParentalPinRepository != null) {
    sl.registerLazySingleton<ParentalPinRepository>(() => testParentalPinRepository);
  } else if (useMock) {
    sl.registerLazySingleton<ParentalPinRepository>(
      () => MockParentalPinRepository(
        secureStorageService: sl(),
        preferencesService: sl(),
        mockAuthRepository: sl<AuthRepository>() is MockAuthRepository
            ? sl<AuthRepository>() as MockAuthRepository
            : null,
      ),
    );
  } else {
    sl.registerLazySingleton<ParentalPinRepository>(
      () => ParentalPinRepositoryImpl(remoteDataSource: sl()),
    );
  }

  if (testChildModeCubit != null) {
    sl.registerLazySingleton<ChildModeCubit>(() => testChildModeCubit);
  } else {
    sl.registerLazySingleton<ChildModeCubit>(
      () => ChildModeCubit(
        parentalPinRepository: sl(),
        preferencesService: sl(),
        authCubit: sl(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Perfil, Apariencia y Ajustes (Fase 7)
  // ---------------------------------------------------------------------------
  if (testThemeCubit != null) {
    sl.registerLazySingleton<ThemeCubit>(() => testThemeCubit);
  } else {
    sl.registerLazySingleton<ThemeCubit>(
      () => ThemeCubit(preferencesService: sl()),
    );
  }

  if (testProfileCubit != null) {
    sl.registerFactory<ProfileCubit>(() => testProfileCubit);
  } else {
    sl.registerFactory<ProfileCubit>(
      () => ProfileCubit(
        authRepository: sl(),
        authCubit: sl.isRegistered<AuthCubit>() ? sl<AuthCubit>() : null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Enrutamiento (GoRouter)
  // ---------------------------------------------------------------------------
  sl.registerLazySingleton<AppRouter>(
    () => AppRouter(
      secureStorageService: sl(),
      preferencesService: sl(),
      refreshListenable: GoRouterRefreshStream(
        sl<AuthCubit>().stream,
        sl<ChildModeCubit>().stream,
      ),
    ),
  );
}

/// Limpia y reinicia el contenedor (útil para pruebas unitarias).
Future<void> resetDependencies() async {
  await sl.reset();
}
