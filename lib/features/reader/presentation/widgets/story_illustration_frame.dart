import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/story_detail.dart';
import '../../domain/entities/story_page_detail.dart';

/// Marco visual reutilizable para presentar la ilustración de una página del cuento.
///
/// Mitigación del Bloqueo StoryPage–Ilustración:
/// El backend oficial actualmente no posee una relación confirmada entre `StoryPage`
/// y su asset de `Generative Media`. Cuando no existe una imagen asociada (o en producción),
/// este componente presenta un marco temático oficial de Tale Star con bordes redondeados,
/// reservando el espacio visual de la ilustración y asegurando que el texto narrativo
/// permanezca 100% legible y accesible.
class StoryIllustrationFrame extends StatelessWidget {
  final StoryPageDetail page;
  final StoryDetail story;
  final double height;

  const StoryIllustrationFrame({
    super.key,
    required this.page,
    required this.story,
    this.height = 220.0,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = page.demoIllustrationAsset;

    // Si disponemos de un asset local (usado en Modo Demostración), lo mostramos
    if (assetPath != null && assetPath.isNotEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: AppRadii.lg,
          border: Border.all(color: AppColors.surface3Light),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadii.lg,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildThematicPlaceholder(),
              ),
              // Sutil viñeta degradada inferior para legibilidad del badge de página
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    'Página ${page.pageNumber}',
                    style: AppTypography.caption(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildThematicPlaceholder();
  }

  /// Placeholder temático oficial que reserva el espacio visual sin simular una imagen falsa.
  Widget _buildThematicPlaceholder() {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: AppRadii.lg,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary100.withValues(alpha: 0.6),
            AppColors.surface2Light,
            AppColors.primary100.withValues(alpha: 0.3),
          ],
        ),
        border: Border.all(
          color: AppColors.primary300.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary900.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Iconografía decorativa de lectura fantástica
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary700.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  size: 40,
                  color: AppColors.primary700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Ilustración en Desarrollo',
                style: AppTypography.titleSmall(color: AppColors.primary900),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'El cuento acompaña tu lectura mientras se vinculan los trazos visuales.',
                  style: AppTypography.caption(color: AppColors.textSecondaryLight),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),

          // Badge de número de página en la esquina superior derecha
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: AppRadii.sm,
                border: Border.all(color: AppColors.surface3Light),
              ),
              child: Text(
                'Página ${page.pageNumber}',
                style: AppTypography.caption(color: AppColors.primary900)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

