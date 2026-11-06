import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubit/ar_state.dart';

/// Panel de diagnóstico en tiempo real visible **exclusivamente** en modo debug (`kDebugMode`).
///
/// Expone el estado interno de ARCore, tracking SLAM, planos, retícula y el motivo exacto
/// de habilitación o bloqueo de la colocación espacial, con mecanismo de copia al portapapeles.
class ArDiagnosticPanel extends StatefulWidget {
  final ArState state;

  const ArDiagnosticPanel({
    super.key,
    required this.state,
  });

  @override
  State<ArDiagnosticPanel> createState() => _ArDiagnosticPanelState();
}

class _ArDiagnosticPanelState extends State<ArDiagnosticPanel> {
  bool _isExpanded = false;
  bool _copiedRecently = false;

  String _buildDisableReason(ArState state) {
    if (!state.isCameraTracking) {
      return 'Cámara sin tracking activo: ${state.trackingFailureReason}';
    }
    if (!state.hasValidPlacementPoint) {
      if (state.validPlanesCount == 0) {
        return 'Sin plano ni punto instantáneo bajo la retícula (mueve el teléfono hacia mesa o suelo)';
      }
      return 'Superficie detectada en el entorno pero la retícula no apunta a ella';
    }
    return 'NINGUNO (Superficie lista para colocar cuento)';
  }

  String _formatDiagnosticReport(ArState state, String disableReason) {
    return '''
=== TALE STAR ARCORE DIAGNOSTICS ===
Timestamp: ${DateTime.now().toIso8601String()}
Session: ACTIVA (${state.status.name})
Camera Tracking State: ${state.cameraTrackingState}
Tracking Failure Reason: ${state.trackingFailureReason}
Frame Timestamp: ${state.frameTimestampNs} ns
Planos Conocidos: ${state.knownPlanesCount}
Planos Horizontales Válidos: ${state.validPlanesCount}
Planos No Horizontales / Verticales: ${state.nonHorizontalPlanesCount}
Planos Pausados: ${state.pausedPlanesCount}
Planos Subsumidos: ${state.subsumedPlanesCount}
Causa Descarte Planos: ${state.planeDiscardReason}
Eventos Emitidos (Kotlin): ${state.eventsSentCount}
Eventos Recibidos (Flutter): ${state.eventsReceivedCount}
Estado ArCubit: ${state.status.name} (canPlaceStory: ${state.canPlaceStory})
Hit-Test Retícula: ${state.hasHitAtReticle ? state.placementPointType : 'SIN IMPACTO'}
Punto de Colocación Válido: ${state.hasValidPlacementPoint}
Distancia Estimada: ${state.hitDistanceMeters.toStringAsFixed(2)} m
Viewport Nativo: ${state.viewportWidth.toInt()} x ${state.viewportHeight.toInt()}
Motivo de Bloqueo: $disableReason
====================================
''';
  }

  Future<void> _copyDiagnosticToClipboard(String report) async {
    await Clipboard.setData(ClipboardData(text: report));
    if (mounted) {
      setState(() => _copiedRecently = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diagnóstico ARCore copiado al portapapeles.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copiedRecently = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final state = widget.state;
    final isTracking = state.isCameraTracking;
    final hasPlacement = state.hasValidPlacementPoint;
    final disableReason = _buildDisableReason(state);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: const Color(0xEE0B0C12),
            borderRadius: AppRadii.md,
            border: Border.all(
              color: hasPlacement
                  ? AppColors.success.withValues(alpha: 0.6)
                  : Colors.white24,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de título con toggle
              InkWell(
                key: const Key('ar_diagnostic_toggle_button'),
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: AppRadii.md,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isTracking ? AppColors.success : AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ARCore Diag',
                        style: AppTypography.caption(color: Colors.white).copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${state.eventsReceivedCount} ev | ${state.validPlanesCount} pl',
                          style: AppTypography.caption(color: Colors.white70).copyWith(
                            fontSize: 9.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              if (_isExpanded) ...[
                const Divider(color: Colors.white12, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRow('ARCore Session', 'ACTIVA (${state.status.name})', Colors.white),
                      _buildRow(
                        'Tracking State',
                        state.cameraTrackingState,
                        isTracking ? AppColors.success : AppColors.warning,
                      ),
                      if (state.trackingFailureReason != 'NONE')
                        _buildRow('Tracking Failure', state.trackingFailureReason, AppColors.danger),

                      _buildRow(
                        'Frame Timestamp',
                        state.frameTimestampNs > 0 ? '${state.frameTimestampNs} ns' : 'Esperando...',
                        Colors.white70,
                      ),

                      _buildRow(
                        'Planos (Conocidos / Válidos)',
                        '${state.knownPlanesCount} conocidos / ${state.validPlanesCount} válidos',
                        state.validPlanesCount > 0 ? AppColors.success : Colors.white,
                      ),

                      if (state.knownPlanesCount > 0)
                        _buildRow(
                          'Desglose Planos',
                          'V:${state.validPlanesCount} | NV:${state.nonHorizontalPlanesCount} | P:${state.pausedPlanesCount} | S:${state.subsumedPlanesCount}',
                          Colors.white60,
                        ),

                      _buildRow(
                        'Descarte Planos',
                        state.planeDiscardReason,
                        state.validPlanesCount > 0 ? AppColors.success : Colors.amberAccent,
                      ),

                      _buildRow(
                        'Eventos (Kotlin -> Flutter)',
                        '${state.eventsSentCount} env / ${state.eventsReceivedCount} rec',
                        AppColors.info,
                      ),

                      _buildRow(
                        'Estado ArCubit',
                        '${state.status.name} (canPlace: ${state.canPlaceStory})',
                        state.canPlaceStory ? AppColors.success : Colors.white70,
                      ),

                      _buildRow(
                        'Hit-Test Retícula',
                        state.hasHitAtReticle
                            ? 'IMPACTO (${state.placementPointType})'
                            : 'SIN IMPACTO',
                        state.hasHitAtReticle ? AppColors.success : Colors.white60,
                      ),

                      if (state.hitDistanceMeters > 0)
                        _buildRow(
                          'Distancia Estimada',
                          '${state.hitDistanceMeters.toStringAsFixed(2)} m',
                          Colors.white,
                        ),

                      _buildRow(
                        'Viewport Nativo',
                        '${state.viewportWidth.toInt()} x ${state.viewportHeight.toInt()}',
                        Colors.white60,
                      ),

                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasPlacement
                              ? AppColors.success.withValues(alpha: 0.15)
                              : AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Motivo: $disableReason',
                          style: AppTypography.caption(
                            color: hasPlacement ? AppColors.success : AppColors.warning,
                          ).copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),

                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _copyDiagnosticToClipboard(
                            _formatDiagnosticReport(state, disableReason),
                          ),
                          icon: Icon(
                            _copiedRecently ? Icons.check_rounded : Icons.copy_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          label: Text(
                            _copiedRecently ? '¡Copiado!' : 'Copiar Diagnóstico',
                            style: AppTypography.caption(color: Colors.white).copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: AppTypography.caption(color: Colors.white70).copyWith(fontSize: 9.5),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: AppTypography.caption(color: valueColor).copyWith(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
