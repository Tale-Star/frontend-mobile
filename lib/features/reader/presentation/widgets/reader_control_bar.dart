import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Barra inferior de control de navegación entre páginas del cuento.
///
/// Ofrece botones accesibles (touch target >= 44x44 px) con estados activos/deshabilitados
/// en los extremos de la historia (primera y última página).
class ReaderControlBar extends StatelessWidget {
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final int currentPage;
  final int totalPages;

  const ReaderControlBar({
    super.key,
    required this.hasPrevious,
    required this.hasNext,
    this.onPrevious,
    this.onNext,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: AppRadii.lg,
        border: Border.all(
          color: isDark ? AppColors.surface3Dark : AppColors.surface3Light,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón Página Anterior
          SizedBox(
            width: 48,
            height: 48,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                key: const Key('reader_prev_button'),
                tooltip: 'Página anterior',
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: isDark ? AppColors.primary300 : AppColors.primary900,
                disabledColor: (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)
                    .withValues(alpha: 0.4),
                onPressed: hasPrevious ? onPrevious : null,
              ),
            ),
          ),

          // Indicador de Página Central
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Página $currentPage de $totalPages',
                style: AppTypography.titleSmall(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                totalPages == 1
                    ? 'Cuento completo'
                    : (currentPage == totalPages ? 'Fin del cuento' : 'Desliza para leer'),
                style: AppTypography.caption(
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),

          // Botón Página Siguiente
          SizedBox(
            width: 48,
            height: 48,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                key: const Key('reader_next_button'),
                tooltip: 'Página siguiente',
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
                color: isDark ? AppColors.primary300 : AppColors.primary900,
                disabledColor: (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)
                    .withValues(alpha: 0.4),
                onPressed: hasNext ? onNext : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

