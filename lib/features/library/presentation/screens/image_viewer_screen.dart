import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../injection.dart';
import '../../../child_mode/domain/entities/child_mode_content.dart';
import '../../../child_mode/presentation/cubit/child_mode_cubit.dart';
import '../../../child_mode/presentation/cubit/child_mode_state.dart';
import '../../../child_mode/presentation/screens/pin_validation_dialog.dart';
import '../../../child_mode/presentation/widgets/activate_child_mode_sheet.dart';
import '../../../child_mode/presentation/widgets/child_mode_active_badge.dart';
import '../../domain/entities/library_item_entity.dart';
import '../cubit/library_cubit.dart';
import '../cubit/library_state.dart';
import '../widgets/ts_cached_image.dart';

/// Visor de imágenes a pantalla completa con soporte para zoom, pan, favoritos y Modo Niño (Fase 2 / Fase 6).
class ImageViewerScreen extends StatelessWidget {
  final String imageId;
  final LibraryItemEntity? initialItem;

  const ImageViewerScreen({
    super.key,
    required this.imageId,
    this.initialItem,
  });

  ChildModeCubit? _resolveChildModeCubit(BuildContext context) {
    try {
      return context.read<ChildModeCubit>();
    } catch (_) {
      if (sl.isRegistered<ChildModeCubit>()) {
        return sl<ChildModeCubit>();
      }
      return null;
    }
  }

  Future<void> _handleExit(BuildContext context) async {
    final childModeCubit = _resolveChildModeCubit(context);
    if (childModeCubit != null && childModeCubit.state is ChildModeActive) {
      final unlocked = await PinValidationDialog.show(context, cubit: childModeCubit);
      if (unlocked && context.mounted) {
        context.pop();
      }
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ChildModeCubit? childModeCubit;
    try {
      childModeCubit = context.watch<ChildModeCubit>();
    } catch (_) {
      if (sl.isRegistered<ChildModeCubit>()) {
        childModeCubit = sl<ChildModeCubit>();
      }
    }
    final isChildMode = childModeCubit?.state is ChildModeActive;

    return PopScope(
      canPop: !isChildMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleExit(context);
        }
      },
      child: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, state) {
          // Buscar el ítem más reciente en el estado de la biblioteca o usar el initialItem
          LibraryItemEntity? item = initialItem;
          if (state is LibraryLoaded) {
            final found = state.items.where((i) => i.id == imageId);
            if (found.isNotEmpty) {
              item = found.first;
            }
          }

          final title = item?.name.isNotEmpty == true ? item!.name : 'Ilustración';
          final resourceUrl = item?.resourceUrl ?? '';
          final isFavorite = item?.favorite ?? false;

          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.6),
              elevation: 0,
              leading: IconButton(
                key: const Key('viewer_back_button'),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => _handleExit(context),
              ),
              title: Text(
                title,
                style: AppTypography.titleMedium(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                if (isChildMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Center(
                      child: ChildModeActiveBadge(
                        onTap: () => _handleExit(context),
                      ),
                    ),
                  )
                else ...[
                  IconButton(
                    key: const Key('viewer_child_mode_button'),
                    tooltip: 'Activar Modo Niño',
                    icon: const Icon(Icons.child_care_rounded, color: Colors.white, size: 24),
                    onPressed: () {
                      final cubit = _resolveChildModeCubit(context);
                      if (cubit != null) {
                        ActivateChildModeSheet.requestActivation(
                          context,
                          contentType: ChildModeContentType.image,
                          contentId: imageId,
                          contentTitle: title,
                          routeContext: '/media/image/$imageId',
                          childModeCubit: cubit,
                        );
                      }
                    },
                  ),
                  if (item != null)
                    IconButton(
                      key: const Key('viewer_favorite_button'),
                      tooltip: isFavorite ? 'Quitar de favoritos' : 'Marcar como favorito',
                      icon: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorite ? AppColors.danger : Colors.white,
                      ),
                      onPressed: () => context.read<LibraryCubit>().toggleFavorite(item!),
                    ),
                ],
              ],
            ),
            body: SafeArea(
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: TsCachedImage(
                      imageUrl: resourceUrl,
                      fit: BoxFit.contain,
                      placeholderIcon: Icons.image_outlined,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
