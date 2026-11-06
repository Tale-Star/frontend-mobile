import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Indicador visual de progreso y páginas del cuento.
class PageIndicatorDots extends StatelessWidget {
  final int currentIndex;
  final int totalPages;
  final ValueChanged<int>? onDotTapped;

  const PageIndicatorDots({
    super.key,
    required this.currentIndex,
    required this.totalPages,
    this.onDotTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    // Para cuentos con hasta 10 páginas, mostramos puntos animados táctiles
    if (totalPages <= 10) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (index) {
          final isSelected = index == currentIndex;
          return GestureDetector(
            onTap: onDotTapped != null ? () => onDotTapped!(index) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              width: isSelected ? 22.0 : 8.0,
              height: 8.0,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary700 : AppColors.surface3Light,
                borderRadius: AppRadii.pill,
              ),
            ),
          );
        }),
      );
    }

    // Para cuentos extensos (> 10 páginas), mostramos barra de progreso lineal continua
    final progress = (currentIndex + 1) / totalPages;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: AppRadii.pill,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surface3Light,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary700),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Progreso: ${(progress * 100).toInt()}%',
            style: AppTypography.caption(color: AppColors.textTertiaryLight),
          ),
        ],
      ),
    );
  }
}

