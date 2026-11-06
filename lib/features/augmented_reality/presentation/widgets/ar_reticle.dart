import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

/// Retícula espacial inteligente de colocación AR (Fase 5).
///
/// Cambia de forma, color y animación según el estado real de detección y hit-testing:
/// 1. **Buscando superficies:** Anillo punteado con pulso y rotación suave.
/// 2. **Superficie cercana detectada:** Expansión visual indicando proximidad.
/// 3. **Punto válido fijado:** Retícula bloqueada en color verde esmeralda / morado Tale Star,
///    anillo en perspectiva 3D simulando el plano de la mesa y aviso "¡Listo para colocar!".
class ArReticle extends StatefulWidget {
  final bool hasValidPlacement;
  final bool hasHitAtReticle;
  final bool isTracking;
  final String placementType;
  final double hitDistanceMeters;
  final VoidCallback? onTap;

  const ArReticle({
    super.key,
    required this.hasValidPlacement,
    required this.hasHitAtReticle,
    required this.isTracking,
    this.placementType = 'NONE',
    this.hitDistanceMeters = 0.0,
    this.onTap,
  });

  @override
  State<ArReticle> createState() => _ArReticleState();
}

class _ArReticleState extends State<ArReticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.hasHitAtReticle || widget.hasValidPlacement;

    return Center(
      child: GestureDetector(
        key: const Key('ar_reticle_tap_target'),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final t = _animController.value;
            final pulse = math.sin(t * math.pi * 2) * 0.15 + 1.0;

            final activeColor = isLocked
                ? const Color(0xFF00E676) // Verde esmeralda neón
                : (widget.isTracking
                    ? AppColors.primary300
                    : AppColors.warning);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Anillo de perspectiva sobre la superficie (proyección en el suelo)
                    if (isLocked)
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.002)
                          ..rotateX(1.1)
                          ..scaleByDouble(1.2 * pulse, 1.2 * pulse, 1.0, 1.0),
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: activeColor.withValues(alpha: 0.7),
                              width: 2.2,
                            ),
                            color: activeColor.withValues(alpha: 0.12),
                            boxShadow: [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.35),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Círculo exterior con animación
                    Transform.rotate(
                      angle: isLocked ? 0 : t * math.pi * 2,
                      child: Container(
                        width: 74 * (isLocked ? 1.0 : pulse),
                        height: 74 * (isLocked ? 1.0 : pulse),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: activeColor.withValues(alpha: isLocked ? 0.9 : 0.6),
                            width: isLocked ? 2.5 : 1.5,
                          ),
                        ),
                      ),
                    ),

                    // Diana central
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLocked
                            ? activeColor.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.5),
                        border: Border.all(
                          color: activeColor,
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.4),
                            blurRadius: isLocked ? 14 : 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isLocked
                              ? Icons.place_rounded
                              : Icons.filter_center_focus_rounded,
                          color: activeColor,
                          size: isLocked ? 24 : 22,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Pastilla indicadora inferior
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: AppRadii.pill,
                    border: Border.all(
                      color: activeColor.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: activeColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isLocked
                            ? 'Superficie lista · Toca para colocar'
                            : (widget.isTracking
                                ? 'Buscando mesa o suelo...'
                                : 'Mueve el teléfono suavemente'),
                        style: AppTypography.caption(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
