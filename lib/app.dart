import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/authentication/presentation/cubit/auth_cubit.dart';
import 'features/child_mode/presentation/cubit/child_mode_cubit.dart';
import 'features/library/presentation/cubit/library_cubit.dart';
import 'features/music/presentation/cubit/music_player_cubit.dart';
import 'injection.dart';

/// Raíz de la aplicación Tale Star.
class TaleStarApp extends StatelessWidget {
  const TaleStarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = sl<AppRouter>();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => sl<AuthCubit>()..checkAuthStatus(),
        ),
        BlocProvider<ChildModeCubit>(
          create: (_) => sl<ChildModeCubit>()..restoreSession(),
        ),
        BlocProvider<LibraryCubit>(
          create: (_) => sl<LibraryCubit>(),
        ),
        BlocProvider<MusicPlayerCubit>(
          create: (_) => sl<MusicPlayerCubit>(),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => sl<ThemeCubit>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, AppThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Tale Star',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode.toThemeMode,
            routerConfig: appRouter.router,
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: mediaQuery.textScaler.clamp(
                    minScaleFactor: 0.85,
                    maxScaleFactor: 1.35,
                  ),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
