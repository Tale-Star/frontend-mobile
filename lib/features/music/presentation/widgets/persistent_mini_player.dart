import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubit/music_player_cubit.dart';
import '../cubit/music_player_state.dart';

/// Mini-reproductor musical persistente que flota sobre la barra de navegación inferior.
class PersistentMiniPlayer extends StatelessWidget {
  const PersistentMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return BlocBuilder<MusicPlayerCubit, MusicPlayerState>(
      builder: (context, state) {
        if (!state.isActive || state.currentTrack == null) {
          return const SizedBox.shrink();
        }

        final track = state.currentTrack!;

        return Material(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          elevation: 6,
          child: InkWell(
            key: const Key('mini_player_tap_area'),
            onTap: () {
              context.pushNamed(RouteNames.musicPlayer);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barra de progreso miniatura en el borde superior
                LinearProgressIndicator(
                  key: const Key('mini_player_progress'),
                  value: state.progressPercent,
                  minHeight: 2.5,
                  backgroundColor: isDark ? AppColors.surface3Dark : AppColors.surface3Light,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.primary500 : AppColors.primary900,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      // Carátula miniatura con icono temático
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: AppRadii.sm,
                          gradient: const LinearGradient(
                            colors: [AppColors.primary900, AppColors.primary700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Título y formato
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              track.name,
                              key: const Key('mini_player_title'),
                              style: AppTypography.titleSmall(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (track.isFlac) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.primary900.withValues(alpha: 0.3)
                                          : AppColors.primary100,
                                      borderRadius: AppRadii.sm,
                                    ),
                                    child: Text(
                                      'FLAC',
                                      style: AppTypography.caption(
                                        color: isDark ? AppColors.primary300 : AppColors.primary900,
                                      ).copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    _getStatusLabel(state),
                                    style: AppTypography.caption(
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Controles: Botón Reproducir/Pausar y Cerrar
                      if (state.isLoading || state.isBuffering)
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: isDark ? AppColors.primary500 : AppColors.primary900,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          key: const Key('mini_player_play_pause_button'),
                          tooltip: state.isPlaying ? 'Pausar música' : 'Reproducir música',
                          icon: Icon(
                            state.isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: isDark ? AppColors.primary500 : AppColors.primary900,
                            size: 34,
                          ),
                          onPressed: () {
                            context.read<MusicPlayerCubit>().togglePlayPause();
                          },
                        ),

                      IconButton(
                        key: const Key('mini_player_close_button'),
                        tooltip: 'Detener y cerrar reproductor',
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                          size: 20,
                        ),
                        onPressed: () {
                          context.read<MusicPlayerCubit>().stop();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getStatusLabel(MusicPlayerState state) {
    if (state.isLoading) return 'Cargando pista...';
    if (state.isBuffering) return 'Almacenando búfer...';
    if (state.isPlaying) return 'Reproduciendo';
    if (state.isPaused) return 'En pausa';
    if (state.isCompleted) return 'Finalizado';
    if (state.hasError) return 'Error de reproducción';
    return state.currentTrack?.audioFormatLabel ?? '';
  }
}

