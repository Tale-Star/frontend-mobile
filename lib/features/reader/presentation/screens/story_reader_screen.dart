import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../injection.dart';
import '../../../../shared/widgets/ts_empty_state.dart';
import '../../../../shared/widgets/ts_loading_shimmer.dart';
import '../../../child_mode/domain/entities/child_mode_content.dart';
import '../../../child_mode/presentation/cubit/child_mode_cubit.dart';
import '../../../child_mode/presentation/cubit/child_mode_state.dart';
import '../../../child_mode/presentation/screens/pin_validation_dialog.dart';
import '../../../child_mode/presentation/widgets/activate_child_mode_sheet.dart';
import '../../../child_mode/presentation/widgets/child_mode_active_badge.dart';
import '../cubit/reader_cubit.dart';
import '../cubit/reader_state.dart';
import '../widgets/page_indicator_dots.dart';
import '../widgets/reader_control_bar.dart';
import '../widgets/story_illustration_frame.dart';

/// Pantalla oficial del Lector de Cuentos Tradicional 2D (Fase 3).
///
/// Gestiona la lectura guiada de historias infantiles con soporte para navegación
/// secuencial por botones accesibles, gestos de deslizamiento horizontal y
/// adaptación ante narrativas breves o extensas sin desbordamiento.
class StoryReaderScreen extends StatelessWidget {
  final String storyId;

  const StoryReaderScreen({
    super.key,
    required this.storyId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReaderCubit>(
      create: (context) => sl<ReaderCubit>()..loadStory(storyId),
      child: _StoryReaderView(storyId: storyId),
    );
  }
}

class _StoryReaderView extends StatelessWidget {
  final String storyId;

  const _StoryReaderView({required this.storyId});

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
        context.pop();
      }
    } else {
      context.pop();
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
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        body: SafeArea(
          child: BlocBuilder<ReaderCubit, ReaderState>(
            builder: (context, state) {
              final cubit = context.read<ReaderCubit>();

              return Column(
                children: [
                  // Encabezado con identidad Tale Star, título, modo niño y acceso AR
                  _buildHeader(context, state, isChildMode: isChildMode),

                  // Contenido dinámico según el estado del lector
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (state is ReaderLoading || state is ReaderInitial) {
                          return _buildLoadingState();
                        }

                        if (state is ReaderError) {
                          return _buildErrorState(context, state, cubit);
                        }

                        if (state is ReaderEmpty) {
                          return _buildEmptyState(context, state);
                        }

                        if (state is ReaderLoaded) {
                          return _buildLoadedReader(context, state, cubit);
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Encabezado oficial con título en Nunito, subtítulo en Inter, control de Modo Niño y AR.
  Widget _buildHeader(
    BuildContext context,
    ReaderState state, {
    required bool isChildMode,
  }) {
    final isDark = context.isDarkMode;
    String title = 'Cuento';
    if (state is ReaderLoaded) {
      title = state.story.title.isNotEmpty ? state.story.title : 'Cuento';
    } else if (state is ReaderEmpty) {
      title = state.story.title.isNotEmpty ? state.story.title : 'Cuento';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.surface3Dark : AppColors.surface3Light,
          ),
        ),
      ),
      child: Row(
        children: [
          // Botón de retorno a la Biblioteca / Desbloqueo si está en Modo Niño
          IconButton(
            key: const Key('reader_back_button'),
            tooltip: isChildMode ? 'Desbloquear Modo Niño' : 'Volver a cuentos',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            onPressed: () => _handleExit(context),
          ),

          const SizedBox(width: AppSpacing.xs),

          // Título del cuento y subtítulo de identidad
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cuento de Tale Star',
                  style: AppTypography.caption(
                    color: isDark ? AppColors.primary300 : AppColors.primary700,
                  ),
                ),
                Text(
                  title,
                  style: AppTypography.titleMedium(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Distintivo de Modo Niño Activo o Botón para Activar
          if (isChildMode)
            ChildModeActiveBadge(
              onTap: () => _handleExit(context),
            )
          else
            IconButton(
              key: const Key('reader_child_mode_button'),
              tooltip: 'Activar Modo Niño',
              icon: const Icon(Icons.child_care_rounded, size: 24),
              color: AppColors.primary700,
              onPressed: () {
                final cubit = _resolveChildModeCubit(context);
                if (cubit != null) {
                  ActivateChildModeSheet.requestActivation(
                    context,
                    contentType: ChildModeContentType.story,
                    contentId: storyId,
                    contentTitle: title,
                    routeContext: '/stories/$storyId/read',
                    childModeCubit: cubit,
                  );
                }
              },
            ),

          const SizedBox(width: AppSpacing.xs),

          // Punto de acceso visual a Realidad Aumentada (Fase 5)
          IconButton(
            key: const Key('reader_ar_button'),
            tooltip: 'Leer en realidad aumentada',
            icon: const Icon(Icons.view_in_ar_rounded, size: 24),
            color: AppColors.primary700,
            onPressed: () => _openArExperience(context, state),
          ),
        ],
      ),
    );
  }

  /// Estado de lectura cargado con gestos horizontales y scroll vertical sin colisiones.
  Widget _buildLoadedReader(
    BuildContext context,
    ReaderLoaded state,
    ReaderCubit cubit,
  ) {
    final isDark = context.isDarkMode;
    final page = state.currentPage;

    return GestureDetector(
      // Gestos de deslizamiento horizontal con umbral de velocidad
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -250) {
          // Deslizamiento hacia la izquierda -> avanzar
          cubit.nextPage();
        } else if (velocity > 250) {
          // Deslizamiento hacia la derecha -> retroceder
          cubit.previousPage();
        }
      },
      child: Column(
        children: [
          // Área scrollable vertical para narración e ilustración
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ilustración con mitigación de bloqueo StoryPage–Ilustración
                  StoryIllustrationFrame(
                    page: page,
                    story: state.story,
                    height: 220,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Badge de acción / momento narrativo si está presente en el backend
                  if (page.action.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primary900.withValues(alpha: 0.3)
                            : AppColors.primary100,
                        borderRadius: AppRadii.pill,
                      ),
                      child: Text(
                        page.action,
                        style: AppTypography.caption(
                          color: isDark ? AppColors.primary300 : AppColors.primary900,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  // Texto narrativo principal en Inter (altamente legible y accesible)
                  Text(
                    page.text,
                    style: AppTypography.bodyLarge(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ).copyWith(height: 1.6, fontSize: 17),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Indicador de puntos / progreso de página
                  Center(
                    child: PageIndicatorDots(
                      currentIndex: state.currentPageIndex,
                      totalPages: state.totalPages,
                      onDotTapped: cubit.goToPage,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barra inferior de control de navegación con touch targets >= 44x44
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ReaderControlBar(
              hasPrevious: state.hasPreviousPage,
              hasNext: state.hasNextPage,
              onPrevious: cubit.previousPage,
              onNext: cubit.nextPage,
              currentPage: state.currentPageIndex + 1,
              totalPages: state.totalPages,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        TsLoadingShimmer.card(height: 220),
        const SizedBox(height: AppSpacing.md),
        TsLoadingShimmer.card(height: 24),
        const SizedBox(height: AppSpacing.sm),
        TsLoadingShimmer.card(height: 100),
      ],
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ReaderError state,
    ReaderCubit cubit,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: TsEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'No pudimos abrir el cuento',
          description: state.message,
          actionLabel: 'Intentar de nuevo',
          onAction: () => cubit.retry(storyId),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ReaderEmpty state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: TsEmptyState(
          icon: Icons.menu_book_rounded,
          title: 'Cuento sin páginas',
          description: 'Este cuento aún no contiene páginas redactadas para la lectura.',
          actionLabel: 'Volver a cuentos',
          onAction: () => context.pop(),
        ),
      ),
    );
  }

  void _openArExperience(BuildContext context, ReaderState state) {
    int pageIndex = 0;
    if (state is ReaderLoaded) {
      pageIndex = state.currentPageIndex;
    }
    context.pushNamed(
      RouteNames.arReader,
      pathParameters: {'storyId': storyId},
      extra: pageIndex,
    );
  }
}

