import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubit/ar_cubit.dart';
import '../cubit/ar_state.dart';
import '../widgets/ar_floating_controls.dart';
import '../widgets/ar_story_card_3d.dart';
import '../widgets/ar_top_bar.dart';

/// Visor inmersivo del cuento colocado en el entorno real mediante Realidad Aumentada (Fase 5).
///
/// Refinado con base en la referencia visual "Mobile AR Story Reader":
/// - El cuento se visualiza como una tarjeta/libro 3D ligero colocado en el espacio.
/// - La cámara real permanece visible y dominante en todo el entorno.
/// - La barra superior y los controles flotantes poseen prioridad de interacción absoluta
///   (z-order frontal), solucionando definitivamente la respuesta del botón de cierre (X).
class ArStoryViewerScreen extends StatelessWidget {
  final String storyId;
  final VoidCallback onExit;

  const ArStoryViewerScreen({
    super.key,
    required this.storyId,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArCubit, ArState>(
      builder: (context, state) {
        final cubit = context.read<ArCubit>();
        final currentPage = state.currentPage;
        final totalPages = state.pages.length;
        final pageNum = state.currentPageIndex + 1;

        // Cálculo de proyección reactiva de anclaje físico AR
        final screenSize = MediaQuery.of(context).size;
        final hasAnchor = state.isAnchorTracking &&
            state.anchorNormX > 0 &&
            state.anchorNormY > 0;

        // Proyección exacta: posición normalizada (0.0 a 1.0) mapeada al tamaño de pantalla lógico
        final anchorLogicalX = state.anchorNormX * screenSize.width;
        final anchorLogicalY = state.anchorNormY * screenSize.height;

        final offsetX = hasAnchor
            ? (anchorLogicalX - (screenSize.width / 2))
                .clamp(-screenSize.width * 0.45, screenSize.width * 0.45)
            : 0.0;
        final offsetY = hasAnchor
            ? (anchorLogicalY - (screenSize.height / 2))
                .clamp(-screenSize.height * 0.38, screenSize.height * 0.38)
            : 0.0;

        // Escala en función de la distancia física real al objeto colocado (distancia de referencia: 0.85m)
        final distanceScale = hasAnchor && state.anchorDistance > 0.15
            ? (0.85 / state.anchorDistance).clamp(0.55, 1.85)
            : 1.0;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // ---------------------------------------------------------------
              // CAPA 1: Tarjeta 3D del cuento anclada en el espacio de la cámara
              // ---------------------------------------------------------------
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 75, bottom: 120),
                  child: ArStoryCard3d(
                    page: currentPage,
                    pageNumber: pageNum,
                    totalPages: totalPages,
                    scale: state.cardScale,
                    rotationY: state.cardRotationY,
                    rotationX: state.cardRotationX,
                    spatialOffsetX: offsetX,
                    spatialOffsetY: offsetY,
                    spatialScaleMultiplier: distanceScale,
                    spatialYaw: state.anchorYaw,
                    spatialPitch: state.anchorPitch,
                    isAnchorTracking: state.isAnchorTracking,
                    isAnchorInView: state.isAnchorInView,
                    onScaleChanged: (scale) => cubit.setCardScale(scale),
                    onRotationChanged: (rotY, rotX) =>
                        cubit.setCardRotation(rotationY: rotY, rotationX: rotX),
                    onResetTransform: () => cubit.resetCardTransform(),
                  ),
                ),
              ),

              // ---------------------------------------------------------------
              // CAPA 2: Degradados de legibilidad superiores e inferiores (no táctiles)
              // ---------------------------------------------------------------
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 100,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 140,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ---------------------------------------------------------------
              // CAPA 3: Controles flotantes inferiores (<  3/6  > y Salir de AR)
              // ---------------------------------------------------------------
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ArFloatingControls(
                  currentPage: pageNum,
                  totalPages: totalPages,
                  hasPrevious: state.hasPreviousPage,
                  hasNext: state.hasNextPage,
                  onPrevious: state.hasPreviousPage ? () => cubit.previousPage() : null,
                  onNext: state.hasNextPage ? () => cubit.nextPage() : null,
                  onExit: onExit,
                ),
              ),

              // ---------------------------------------------------------------
              // CAPA 4 (SUPERIOR): Barra superior flotante con botón (X) y menú (...)
              // Ubicada intencionalmente en la cima del Stack para asegurar hit-testing inmediato.
              // ---------------------------------------------------------------
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ArTopBar(
                  exitButtonKey: const Key('ar_viewer_exit_button'),
                  onExit: onExit,
                  title: state.story?.title ?? 'AR Story',
                  subtitle: 'Página $pageNum de $totalPages',
                  onOptions: () => _showOptionsBottomSheet(context, cubit),
                  showOptions: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Menú modal de opciones espaciales AR (Recolocar, Ajustar Escala, Restablecer)
  void _showOptionsBottomSheet(BuildContext context, ArCubit cubit) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: const Color(0xFF181724),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: AppRadii.pill,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Opciones del Cuento AR',
                  style: AppTypography.titleMedium(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Ajusta la posición y escala del cuento en tu entorno físico.',
                  style: AppTypography.caption(color: Colors.white70),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 1. Recolocar Cuento
                ListTile(
                  key: const Key('ar_options_reposition_tile'),
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary900.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.place_rounded,
                      color: AppColors.primary300,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Recolocar cuento en otra superficie',
                    style: AppTypography.bodyMedium(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Vuelve a escanear para elegir una nueva mesa o suelo',
                    style: AppTypography.caption(color: Colors.white54),
                  ),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    cubit.repositionStory();
                  },
                ),

                const Divider(color: Colors.white10),

                // 2. Restablecer Escala y Rotación
                ListTile(
                  key: const Key('ar_options_reset_tile'),
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restore_rounded,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Restablecer tamaño y orientación',
                    style: AppTypography.bodyMedium(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Regresa el panel al tamaño y perspectiva iniciales',
                    style: AppTypography.caption(color: Colors.white54),
                  ),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    cubit.resetCardTransform();
                  },
                ),

                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}
