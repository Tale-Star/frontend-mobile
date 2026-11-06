import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/augmented_reality/presentation/cubit/ar_cubit.dart';
import '../../features/augmented_reality/presentation/screens/ar_surface_scanner_screen.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/child_mode/presentation/cubit/child_mode_cubit.dart';
import '../../features/child_mode/presentation/screens/pin_setup_screen.dart';
import '../../features/child_mode/presentation/screens/pin_validation_dialog.dart';
import '../../features/library/domain/entities/library_item_entity.dart';
import '../../features/library/presentation/screens/image_viewer_screen.dart';
import '../../features/library/presentation/screens/images_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/library/presentation/screens/music_tab_screen.dart';
import '../../features/library/presentation/screens/stories_tab_screen.dart';
import '../../features/music/presentation/screens/music_player_screen.dart';
import '../../features/music/presentation/widgets/persistent_mini_player.dart';
import '../../features/profile/presentation/screens/profile_tab_screen.dart';
import '../../features/reader/presentation/screens/story_reader_screen.dart';
import '../../injection.dart';
import '../../shared/widgets/ts_app_bar.dart';
import '../../shared/widgets/ts_bottom_nav.dart';
import '../storage/preferences_service.dart';
import '../storage/secure_storage_service.dart';
import 'route_names.dart';

/// Configuración de GoRouter con ShellRoute para la navegación con pestañas oficiales.
class AppRouter {
  final SecureStorageService _secureStorageService;
  final PreferencesService _preferencesService;
  final Listenable? _refreshListenable;

  AppRouter({
    required SecureStorageService secureStorageService,
    required PreferencesService preferencesService,
    Listenable? refreshListenable,
  })  : _secureStorageService = secureStorageService,
        _preferencesService = preferencesService,
        _refreshListenable = refreshListenable;

  late final GoRouter router = GoRouter(
    initialLocation: RouteNames.libraryPath,
    refreshListenable: _refreshListenable,
    redirect: (context, state) async {
      final hasToken = await _secureStorageService.hasToken();
      final isAuthRoute = state.matchedLocation == RouteNames.loginPath ||
          state.matchedLocation == RouteNames.registerPath ||
          state.matchedLocation == RouteNames.forgotPasswordPath;

      // Si no hay token y no está en ruta de autenticación, redirige al login
      if (!hasToken && !isAuthRoute) {
        return RouteNames.loginPath;
      }

      // Si ya hay token e intenta ir al login o registro, redirige a la biblioteca
      if (hasToken && (state.matchedLocation == RouteNames.loginPath || state.matchedLocation == RouteNames.registerPath)) {
        return RouteNames.libraryPath;
      }

      // Confinamiento en Modo Niño (Fase 6)
      final isChildMode = _preferencesService.isChildModeActive;
      if (isChildMode) {
        final savedRoute = _preferencesService.childModeRouteContext;
        final targetFallback = (savedRoute != null && savedRoute.isNotEmpty)
            ? savedRoute
            : RouteNames.storiesPath;

        // En Modo Niño solo se autoriza consumir el recurso protegido o desbloquear con PIN
        final allowedInChildMode = state.matchedLocation.startsWith('/stories') ||
            state.matchedLocation.startsWith('/story') ||
            state.matchedLocation.startsWith('/media/image') ||
            state.matchedLocation.startsWith('/music/player') ||
            state.matchedLocation == RouteNames.pinUnlockPath;

        // Cualquier intento de acceder a perfil, biblioteca o autenticación es interceptado
        if (!allowedInChildMode) {
          return targetFallback;
        }
      }

      return null;
    },
    routes: [
      // -----------------------------------------------------------------------
      // Rutas de Autenticación (Sin barra inferior)
      // -----------------------------------------------------------------------
      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.registerPath,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPasswordPath,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // -----------------------------------------------------------------------
      // Navegación Principal con Shell y Barra Inferior (5 Pestañas Oficiales)
      // -----------------------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final isChildMode = _preferencesService.isChildModeActive;
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: isChildMode
                ? const SizedBox.shrink()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PersistentMiniPlayer(),
                      TsBottomNav(
                        currentIndex: navigationShell.currentIndex,
                        onTap: (index) {
                          navigationShell.goBranch(
                            index,
                            initialLocation: index == navigationShell.currentIndex,
                          );
                        },
                      ),
                    ],
                  ),
          );
        },
        branches: [
          // Pestaña 1: Imágenes
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.imagesPath,
                name: RouteNames.images,
                builder: (context, state) => const ImagesScreen(),
              ),
            ],
          ),

          // Pestaña 2: Cuentos
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.storiesPath,
                name: RouteNames.stories,
                builder: (context, state) => const StoriesTabScreen(),
              ),
            ],
          ),

          // Pestaña 3: Música
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.musicPath,
                name: RouteNames.music,
                builder: (context, state) => const MusicTabScreen(),
              ),
            ],
          ),

          // Pestaña 4: Biblioteca
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.libraryPath,
                name: RouteNames.library,
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),

          // Pestaña 5: Perfil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.profilePath,
                name: RouteNames.profile,
                builder: (context, state) => const ProfileTabScreen(),
              ),
            ],
          ),
        ],
      ),

      // -----------------------------------------------------------------------
      // Rutas de Detalle (Fuera de ShellRoute)
      // -----------------------------------------------------------------------
      GoRoute(
        path: RouteNames.readerPath,
        name: RouteNames.reader,
        builder: (context, state) {
          final storyId = state.pathParameters['storyId'] ?? '';
          return StoryReaderScreen(storyId: storyId);
        },
      ),
      GoRoute(
        path: RouteNames.arReaderPath,
        name: RouteNames.arReader,
        builder: (context, state) {
          final storyId = state.pathParameters['storyId'] ?? '';
          final pageIndex = (state.extra as int?) ?? 0;
          return BlocProvider<ArCubit>(
            create: (_) => sl<ArCubit>(),
            child: ArSurfaceScannerScreen(
              storyId: storyId,
              initialPageIndex: pageIndex,
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.imageViewerPath,
        name: RouteNames.imageViewer,
        builder: (context, state) {
          final imageId = state.pathParameters['id'] ?? '';
          final item = state.extra as LibraryItemEntity?;
          return ImageViewerScreen(imageId: imageId, initialItem: item);
        },
      ),
      GoRoute(
        path: RouteNames.musicPlayerPath,
        name: RouteNames.musicPlayer,
        builder: (context, state) => const MusicPlayerScreen(),
      ),
      GoRoute(
        path: RouteNames.pinSetupPath,
        name: RouteNames.pinSetup,
        builder: (context, state) => const PinSetupScreen(),
      ),
      GoRoute(
        path: RouteNames.pinUnlockPath,
        name: RouteNames.pinUnlock,
        builder: (context, state) => Scaffold(
          appBar: const TsAppBar(title: 'Desbloqueo con PIN Parental'),
          body: Center(
            child: PinValidationDialog(cubit: sl<ChildModeCubit>()),
          ),
        ),
      ),
    ],
  );
}

/// Adaptador para escuchar múltiples streams reactivos (Auth y ChildMode) en GoRouter.
class GoRouterRefreshStream extends ChangeNotifier {
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  GoRouterRefreshStream(Stream<dynamic> stream, [Stream<dynamic>? additionalStream]) {
    notifyListeners();
    _subscriptions.add(stream.asBroadcastStream().listen((_) => notifyListeners()));
    if (additionalStream != null) {
      _subscriptions.add(additionalStream.asBroadcastStream().listen((_) => notifyListeners()));
    }
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }
}
