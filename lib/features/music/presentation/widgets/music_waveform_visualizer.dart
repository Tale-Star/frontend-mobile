import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';

/// Visualizador estilizado de onda sonora y disco vinilo para Tale Star.
class MusicWaveformVisualizer extends StatefulWidget {
  final bool isPlaying;
  final double size;

  const MusicWaveformVisualizer({
    super.key,
    required this.isPlaying,
    this.size = 240,
  });

  @override
  State<MusicWaveformVisualizer> createState() => _MusicWaveformVisualizerState();
}

class _MusicWaveformVisualizerState extends State<MusicWaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MusicWaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary900,
                AppColors.primary700,
                Color(0xFF352096),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary700.withValues(alpha: widget.isPlaying ? 0.35 : 0.15),
                blurRadius: widget.isPlaying ? 28 : 14,
                spreadRadius: widget.isPlaying ? 4 : 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Surcos concéntricos del disco vinilo
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _VinylGroovesPainter(),
              ),

              // Círculo central iluminado
              Container(
                width: widget.size * 0.44,
                height: widget.size * 0.44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceLight,
                ),
                child: Center(
                  child: Container(
                    width: widget.size * 0.38,
                    height: widget.size * 0.38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary100.withValues(alpha: 0.6),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.music_note_rounded,
                        size: widget.size * 0.2,
                        color: AppColors.primary900,
                      ),
                    ),
                  ),
                ),
              ),

              // Barras de ecualizador flotantes en la parte inferior del disco
              Positioned(
                bottom: widget.size * 0.16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final progress = _controller.value;
                    final phase = index * (math.pi / 2.5);
                    final factor = widget.isPlaying
                        ? 0.35 + 0.65 * math.sin(progress * 2 * math.pi + phase).abs()
                        : 0.25;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: 4,
                      height: 22 * factor,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadii.pill,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VinylGroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final baseRadius = size.width / 2;
    for (double r = baseRadius * 0.55; r < baseRadius * 0.92; r += 10.0) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

