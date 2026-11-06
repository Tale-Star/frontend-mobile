import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ts_button.dart';
import '../../../../shared/widgets/ts_snackbar.dart';
import '../cubit/ar_cubit.dart';
import '../cubit/ar_state.dart';
import '../widgets/ar_camera_feed_view.dart';
import '../widgets/ar_diagnostic_panel.dart';
import '../widgets/ar_plane_visualizer.dart';
import '../widgets/ar_reticle.dart';
import '../widgets/ar_top_bar.dart';
import '../widgets/ar_unsupported_dialog.dart';
import 'ar_story_viewer_screen.dart';

/// Pantalla de escaneo y detección de superficies planas en el entorno físico (Fase 5).
///
/// Refinada con retícula espacial central, diagnóstico en tiempo real, hit-testing
/// interactivo de ARCore y feedback dinámico de tracking y colocación.
class ArSurfaceScannerScreen extends StatefulWidget {
  final String storyId;
  final int initialPageIndex;

  const ArSurfaceScannerScreen({
    super.key,
    required this.storyId,
    this.initialPageIndex = 0,
  });

  @override
  State<ArSurfaceScannerScreen> createState() => _ArSurfaceScannerScreenState();
}

class _ArSurfaceScannerScreenState extends State<ArSurfaceScannerScreen> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<ArCubit>();
      if (cubit.state.isError &&
          cubit.state.compatibilityInfo != null &&
          !cubit.state.compatibilityInfo!.isSupported) {
        _handleUnsupported(context, cubit.state);
      } else {
        cubit.startArExperience(
          storyId: widget.storyId,
          initialPageIndex: widget.initialPageIndex,
        );
      }
    });
  }

  void _handleUnsupported(BuildContext context, ArState state) {
    if (_dialogShown) return;
    _dialogShown = true;

    ArUnsupportedDialog.show(
      context,
      deviceModel: state.compatibilityInfo?.deviceModel,
      reasonMessage: state.errorMessage,
      onDismiss: () {
        if (mounted) {
          _handleExit(context);
        }
      },
    );
  }

  Future<void> _handleExit(BuildContext context) async {
    final cubit = context.read<ArCubit>();
    await cubit.exitAr();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  String _buildBannerInstruction(ArState state) {
    if (state.hasValidPlacementPoint) {
      return '¡Superficie lista! Coloca tu cuento.';
    }
    if (state.validPlanesCount > 0 || state.detectedPlanes.isNotEmpty || state.isSurfaceDetected) {
      return 'Superficie detectada. Hemos encontrado una superficie: apunta la retícula hacia ella.';
    }
    if (state.cameraTrackingState == 'TRACKING') {
      return 'Apunta hacia una mesa o el suelo con buena iluminación.';
    }
    return switch (state.trackingFailureReason) {
      'EXCESSIVE_MOTION' => 'Mueve el teléfono más despacio para enfocar.',
      'INSUFFICIENT_LIGHT' => 'Poca luz: enciende la luz o apunta a una zona más iluminada.',
      'INSUFFICIENT_FEATURES' => 'Apunta a una zona con más textura o detalles visuales.',
      _ => 'Mueve el teléfono lentamente apuntando hacia una mesa o el suelo.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ArCubit, ArState>(
      listener: (context, state) {
        if (state.isError) {
          if (state.compatibilityInfo != null && !state.compatibilityInfo!.isSupported) {
            _handleUnsupported(context, state);
          } else if (state.errorMessage != null) {
            TsSnackBar.showError(context, state.errorMessage!);
          }
        }
      },
      builder: (context, state) {
        final cubit = context.read<ArCubit>();
        final canPlace = state.canPlaceStory;

        return Scaffold(
          backgroundColor: const Color(0xFF101016),
          body: Stack(
            children: [
              // ---------------------------------------------------------------
              // CAPA 0: Fondo de cámara nativo con tap-to-place interactivo
              // ---------------------------------------------------------------
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    if (state.isScanningSurface || state.isSurfaceDetected) {
                      final size = MediaQuery.of(context).size;
                      final normX = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
                      final normY = (details.localPosition.dy / size.height).clamp(0.0, 1.0);
                      cubit.placeStoryAtCoordinates(normX, normY);
                    }
                  },
                  child: const ArCameraFeedView(),
                ),
              ),

              // ---------------------------------------------------------------
              // CAPA 1: Experiencia de lectura si el cuento ya fue colocado
              // ---------------------------------------------------------------
              if (state.isStoryPlaced)
                Positioned.fill(
                  child: ArStoryViewerScreen(
                    storyId: widget.storyId,
                    onExit: () => _handleExit(context),
                  ),
                )
              else if (!state.isError) ...[
                // Área central: visualizador de plano si fue detectado
                if (state.isSurfaceDetected && state.selectedPlane != null)
                  Center(
                    child: ArPlaneVisualizer(
                      key: const Key('ar_detected_plane_visualizer'),
                      plane: state.selectedPlane!,
                      isSelected: true,
                      onTap: () => cubit.placeStory(),
                    ),
                  ),

                // Retícula central interactiva de tracking y colocación espacial
                Center(
                  child: ArReticle(
                    key: const Key('ar_central_reticle'),
                    hasValidPlacement: state.hasValidPlacementPoint,
                    hasHitAtReticle: state.hasHitAtReticle,
                    isTracking: state.isCameraTracking,
                    placementType: state.placementPointType,
                    hitDistanceMeters: state.hitDistanceMeters,
                    onTap: canPlace ? () => cubit.placeStory() : null,
                  ),
                ),

                // Banner de instrucción didáctica justo debajo de la barra superior
                Positioned(
                  top: 72,
                  left: 20,
                  right: 20,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: AppRadii.pill,
                        border: Border.all(
                          color: canPlace
                              ? AppColors.success.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.2),
                          width: canPlace ? 1.4 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            canPlace
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                            color: canPlace ? AppColors.success : AppColors.primary300,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              _buildBannerInstruction(state),
                              key: const Key('ar_instruction_banner'),
                              style: AppTypography.caption(color: Colors.white).copyWith(
                                fontSize: 11.5,
                                fontWeight: canPlace ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Estado de escaneo de compatibilidad / permisos en la parte media superior
                Positioned(
                  top: 126,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: AppRadii.pill,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        state.isCheckingCompatibility
                            ? 'Comprobando compatibilidad...'
                            : state.isRequestingPermission
                                ? 'Solicitando permiso de cámara...'
                                : 'Escaneando entorno...',
                        key: const Key('ar_scanning_status_text'),
                        style: AppTypography.caption(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),

                // Panel de diagnóstico en tiempo real (exclusivo para debug, posicionado sin solapar)
                Positioned(
                  top: 168,
                  right: 0,
                  child: ArDiagnosticPanel(state: state),
                ),

                // Barra inferior de escaneo: Botón Salir y Botón Colocar Cuento
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          // Botón Salir secundario
                          OutlinedButton(
                            key: const Key('ar_exit_button'),
                            onPressed: () => _handleExit(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                              minimumSize: const Size(80, 48),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadii.pill,
                              ),
                            ),
                            child: const Text('Salir'),
                          ),
                          const SizedBox(width: AppSpacing.md),

                          // Botón Colocar Cuento
                          Expanded(
                            child: TsButton(
                              key: const Key('ar_place_story_button'),
                              label: canPlace
                                  ? 'Colocar cuento'
                                  : (state.validPlanesCount > 0
                                      ? 'Apunta a la superficie'
                                      : 'Buscando plano...'),
                              icon: Icons.menu_book_rounded,
                              onPressed: canPlace ? () => cubit.placeStory() : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Barra superior flotante (X) — CAPA SUPERIOR ABSOLUTA
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ArTopBar(
                    onExit: () => _handleExit(context),
                    title: canPlace ? 'Superficie lista' : 'Buscando superficie',
                    showOptions: false,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
