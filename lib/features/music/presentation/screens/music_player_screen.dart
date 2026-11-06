import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../injection.dart';
import '../../../../shared/widgets/ts_snackbar.dart';
import '../../../child_mode/domain/entities/child_mode_content.dart';
import '../../../child_mode/presentation/cubit/child_mode_cubit.dart';
import '../../../child_mode/presentation/cubit/child_mode_state.dart';
import '../../../child_mode/presentation/screens/pin_validation_dialog.dart';
import '../../../child_mode/presentation/widgets/activate_child_mode_sheet.dart';
import '../../../child_mode/presentation/widgets/child_mode_active_badge.dart';
import '../cubit/music_player_cubit.dart';
import '../cubit/music_player_state.dart';
import '../widgets/music_waveform_visualizer.dart';

/// Pantalla completa de reproducción musical en alta fidelidad FLAC (Fase 4).
class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  double? _dragValue;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  ChildModeCubit? _resolveChildModeCubit(BuildContext context) {
    try {
      return context.read<ChildModeCubit>();
    } catch (_) {
      if (sl.isRegistered<ChildModeCubit>()) {
        return sl<ChildModeCubit>();
      }
      return null;
    }
  }

  Future<void> _handleExit(BuildContext context) async {
    final childModeCubit = _resolveChildModeCubit(context);
    if (childModeCubit != null && childModeCubit.state is ChildModeActive) {
      final unlocked = await PinValidationDialog.show(context, cubit: childModeCubit);
      if (unlocked && context.mounted) {
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ChildModeCubit? childModeCubit;
    try {
      childModeCubit = context.watch<ChildModeCubit>();
    } catch (_) {
      if (sl.isRegistered<ChildModeCubit>()) {
        childModeCubit = sl<ChildModeCubit>();
      }
    }
    final isChildMode = childModeCubit?.state is ChildModeActive;

    return PopScope(
      canPop: !isChildMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleExit(context);
        }
      },
      child: BlocConsumer<MusicPlayerCubit, MusicPlayerState>(
        listener: (context, state) {
          if (state.hasError && state.errorMessage != null) {
            TsSnackBar.showError(context, state.errorMessage!);
          }
        },
        builder: (context, state) {
          final track = state.currentTrack;

          if (track == null) {
            return Scaffold(
              backgroundColor: context.scaffoldBg,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  key: const Key('player_back_button_empty'),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                  color: context.textPrimaryColor,
                  onPressed: () => _handleExit(context),
                ),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.music_off_rounded, size: 64, color: AppColors.textTertiaryLight),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No hay música seleccionada',
                      style: AppTypography.titleMedium(color: context.textPrimaryColor),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Selecciona una melodía desde la biblioteca para comenzar.',
                      style: AppTypography.bodySmall(color: context.textSecondaryColor),
                    ),
                  ],
                ),
              ),
            );
          }

          final isDark = context.isDarkMode;
          final position = state.position;
          final duration = state.duration;
          final double maxDurationMs = duration.inMilliseconds > 0
              ? duration.inMilliseconds.toDouble()
              : 1.0;
          final double currentPositionMs = _dragValue ??
              position.inMilliseconds.toDouble().clamp(0.0, maxDurationMs);

          return Scaffold(
            backgroundColor: context.scaffoldBg,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                key: const Key('player_back_button'),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 34),
                color: context.textPrimaryColor,
                onPressed: () => _handleExit(context),
              ),
              title: Text(
                'Reproduciendo',
                style: AppTypography.titleMedium(color: context.textPrimaryColor),
              ),
              centerTitle: true,
              actions: [
                if (isChildMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Center(
                      child: ChildModeActiveBadge(
                        onTap: () => _handleExit(context),
                      ),
                    ),
                  )
                else ...[
                  IconButton(
                    key: const Key('player_child_mode_button'),
                    tooltip: 'Activar Modo Niño',
                    icon: const Icon(Icons.child_care_rounded, size: 24),
                    color: AppColors.primary700,
                    onPressed: () {
                      final cubit = _resolveChildModeCubit(context);
                      if (cubit != null) {
                        ActivateChildModeSheet.requestActivation(
                          context,
                          contentType: ChildModeContentType.music,
                          contentId: track.id,
                          contentTitle: track.name,
                          routeContext: '/music/player',
                          childModeCubit: cubit,
                        );
                      }
                    },
                  ),
                  IconButton(
                    key: const Key('player_favorite_button'),
                    icon: Icon(
                      track.favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: track.favorite ? AppColors.danger : AppColors.textSecondaryLight,
                      size: 26,
                    ),
                    onPressed: () {
                      context.read<MusicPlayerCubit>().toggleFavorite();
                    },
                  ),
                ],
              ],
            ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Visualizador de onda / Disco Vinilo animado
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: MusicWaveformVisualizer(
                      isPlaying: state.isPlaying,
                      size: 230,
                    ),
                  ),

                  // Insignia de Calidad y Formato de Audio
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: track.isFlac
                          ? AppColors.primary100
                          : AppColors.surface3Light,
                      borderRadius: AppRadii.pill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          track.isFlac ? Icons.auto_awesome_rounded : Icons.audiotrack_rounded,
                          size: 16,
                          color: track.isFlac ? AppColors.primary900 : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          track.isFlac ? 'FLAC 24-bit Lossless' : track.audioFormatLabel,
                          key: const Key('player_format_badge'),
                          style: AppTypography.caption(
                            color: track.isFlac ? AppColors.primary900 : AppColors.textPrimaryLight,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // Metadatos: Título y Descripción de la Pista
                  Column(
                    children: [
                      Text(
                        track.name,
                        key: const Key('player_track_title'),
                        style: AppTypography.titleLarge(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        track.description.isNotEmpty
                            ? track.description
                            : 'Música ambiental para concentración y lectura.',
                        key: const Key('player_track_description'),
                        style: AppTypography.bodyMedium(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  // Barra de progreso y tiempos
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4.0,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                          activeTrackColor: AppColors.primary900,
                          inactiveTrackColor: AppColors.surface3Light,
                          thumbColor: AppColors.primary900,
                          overlayColor: AppColors.primary700.withValues(alpha: 0.15),
                        ),
                        child: Slider(
                          key: const Key('player_seek_slider'),
                          value: currentPositionMs,
                          min: 0.0,
                          max: maxDurationMs,
                          onChanged: (val) {
                            setState(() {
                              _dragValue = val;
                            });
                          },
                          onChangeEnd: (val) {
                            final target = Duration(milliseconds: val.round());
                            context.read<MusicPlayerCubit>().seek(target);
                            setState(() {
                              _dragValue = null;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(Duration(milliseconds: currentPositionMs.round())),
                              key: const Key('player_current_position'),
                              style: AppTypography.caption(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              key: const Key('player_total_duration'),
                              style: AppTypography.caption(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Controles de Reproducción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Rebobinar 10 segundos
                      IconButton(
                        key: const Key('player_rewind_button'),
                        tooltip: 'Retroceder 10 segundos',
                        icon: const Icon(Icons.replay_10_rounded),
                        iconSize: 38,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        onPressed: () {
                          context.read<MusicPlayerCubit>().seekRelative(const Duration(seconds: -10));
                        },
                      ),
                      const SizedBox(width: AppSpacing.lg),

                      // Botón Principal Play / Pause / Loading
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary900,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary900.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: (state.isLoading || state.isBuffering)
                              ? const SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3.0,
                                    color: Colors.white,
                                  ),
                                )
                              : IconButton(
                                  key: const Key('player_play_pause_button'),
                                  tooltip: state.isPlaying ? 'Pausar música' : 'Reproducir música',
                                  icon: Icon(
                                    state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    context.read<MusicPlayerCubit>().togglePlayPause();
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),

                      // Adelantar 10 segundos
                      IconButton(
                        key: const Key('player_forward_button'),
                        tooltip: 'Adelantar 10 segundos',
                        icon: const Icon(Icons.forward_10_rounded),
                        iconSize: 38,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        onPressed: () {
                          context.read<MusicPlayerCubit>().seekRelative(const Duration(seconds: 10));
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        );
      },
    ),
    );
  }
}

