import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/text_helpers.dart';
import '../../domain/entities/library_item_entity.dart';
import 'ts_cached_image.dart';

/// Tarjeta visual reutilizable para representar cualquier creación de la biblioteca.
class LibraryItemCard extends StatelessWidget {
  final LibraryItemEntity item;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final bool isTogglingFavorite;

  const LibraryItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onToggleFavorite,
    this.isTogglingFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: AppRadii.md,
          border: Border.all(
            color: isDark ? AppColors.surface3Dark : AppColors.surface3Light,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: AppRadii.md,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado visual / Portada del ítem
              _buildThumbnail(context),

              // Contenido descriptivo
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila de metadatos: Badge de tipo y fecha relativa
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTypeBadge(),
                        Text(
                          TextHelpers.formatRelativeDate(item.createdAt),
                          style: AppTypography.caption(
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Título / Nombre
                    Text(
                      item.name.isNotEmpty ? item.name : 'Creación sin título',
                      style: AppTypography.titleSmall(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: AppTypography.bodySmall(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.sm),

                    // Botón accesible de favoritos (Touch target >= 48x48)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: isTogglingFavorite
                              ? const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.danger),
                                    ),
                                  ),
                                )
                              : IconButton(
                                  key: Key('fav_button_${item.id}'),
                                  tooltip: item.favorite
                                      ? 'Quitar de favoritos'
                                      : 'Marcar como favorito',
                                  icon: Icon(
                                    item.favorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: item.favorite
                                        ? AppColors.danger
                                        : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                                    size: 24,
                                  ),
                                  onPressed: onToggleFavorite,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    if (item.isImage) {
      return SizedBox(
        height: 150,
        child: TsCachedImage(
          imageUrl: item.resourceUrl,
          height: 150,
          fit: BoxFit.cover,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.mdValue)),
          placeholderIcon: Icons.image_outlined,
        ),
      );
    }

    if (item.isStory) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.primary100,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.mdValue)),
          gradient: LinearGradient(
            colors: [
              AppColors.primary100,
              AppColors.surface2Light,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  size: 32,
                  color: AppColors.primary700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cuento Educativo',
                style: AppTypography.caption(color: AppColors.primary900)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
    }

    // item.isMusic
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surface2Light,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.mdValue)),
        gradient: LinearGradient(
          colors: [
            AppColors.info.withValues(alpha: 0.12),
            AppColors.surface2Light,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.music_note_rounded,
                size: 32,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Melodía Ambiental FLAC',
              style: AppTypography.caption(color: AppColors.info)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    Color bg;
    Color text;
    IconData icon;

    switch (item.type) {
      case ContentType.image:
        bg = AppColors.primary100;
        text = AppColors.primary900;
        icon = Icons.image_rounded;
        break;
      case ContentType.story:
        bg = AppColors.warning.withValues(alpha: 0.15);
        text = const Color(0xFFB46E00);
        icon = Icons.menu_book_rounded;
        break;
      case ContentType.music:
        bg = AppColors.info.withValues(alpha: 0.15);
        text = AppColors.info;
        icon = Icons.music_note_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: text),
          const SizedBox(width: 4),
          Text(
            item.type.displayName,
            style: AppTypography.caption(color: text).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
