import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../domain/entities/ar_plane.dart';

/// Visualizador estilizado de superficies planas detectadas en el espacio tridimensional de AR.
class ArPlaneVisualizer extends StatefulWidget {
  final ArPlane plane;
  final bool isSelected;
  final VoidCallback? onTap;

  const ArPlaneVisualizer({
    super.key,
    required this.plane,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<ArPlaneVisualizer> createState() => _ArPlaneVisualizerState();
}

class _ArPlaneVisualizerState extends State<ArPlaneVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = _pulseController.value;
        final glowColor = widget.isSelected
            ? AppColors.primary700.withValues(alpha: 0.35 + 0.25 * pulse)
            : AppColors.info.withValues(alpha: 0.25 + 0.15 * pulse);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002) // Perspectiva 3D inclinada
            ..rotateX(0.9), // Inclinación simulando el plano de la mesa/suelo
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: AppRadii.lg,
                border: Border.all(
                  color: widget.isSelected ? AppColors.primary900 : AppColors.info,
                  width: widget.isSelected ? 2.5 : 1.5,
                ),
                color: glowColor,
                boxShadow: [
                  BoxShadow(
                    color: glowColor,
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Malla de puntos de referencia AR (Tracking feature points)
                  CustomPaint(
                    size: const Size(260, 180),
                    painter: _PlaneDotGridPainter(
                      color: widget.isSelected ? Colors.white : AppColors.primary100,
                    ),
                  ),

                  // Diana central de colocación
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2.0,
                      ),
                      color: AppColors.primary900.withValues(alpha: 0.8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.touch_app_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlaneDotGridPainter extends CustomPainter {
  final Color color;

  _PlaneDotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    const step = 24.0;
    for (double x = 16.0; x < size.width; x += step) {
      for (double y = 16.0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 2.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

