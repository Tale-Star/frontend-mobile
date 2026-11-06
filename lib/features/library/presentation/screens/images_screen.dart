import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/ts_app_bar.dart';
import '../../../../shared/widgets/ts_empty_state.dart';
import '../../../../shared/widgets/ts_loading_shimmer.dart';
import '../../../../shared/widgets/ts_snackbar.dart';
import '../../domain/entities/library_item_entity.dart';
import '../cubit/library_cubit.dart';
import '../cubit/library_state.dart';
import '../widgets/library_item_card.dart';

/// Pestaña 1 oficial: Galería de Ilustraciones generadas y guardadas.
class ImagesScreen extends StatefulWidget {
  const ImagesScreen({super.key});

  @override
  State<ImagesScreen> createState() => _ImagesScreenState();
}

class _ImagesScreenState extends State<ImagesScreen> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<LibraryCubit>();
    if (cubit.state is LibraryInitial) {
      cubit.loadLibrary(type: ContentType.image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: const TsAppBar(
        title: 'Imágenes',
      ),
      body: SafeArea(
        child: BlocConsumer<LibraryCubit, LibraryState>(
          listener: (context, state) {
            if (state is LibraryError) {
              TsSnackBar.showError(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is LibraryLoading && state is! LibraryLoaded) {
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: 4,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) => TsLoadingShimmer.card(height: 180),
              );
            }

            final allItems = (state is LibraryLoaded)
                ? state.items
                : ((state is LibraryError) ? state.previousItems : <LibraryItemEntity>[]);

            // Filtrar elementos de tipo imagen
            final images = allItems.where((i) => i.isImage).toList();

            if (images.isEmpty && state is! LibraryLoading) {
              return RefreshIndicator(
                onRefresh: () => context.read<LibraryCubit>().loadLibrary(type: ContentType.image),
                child: ListView(
                  children: const [
                    SizedBox(height: 80),
                    TsEmptyState(
                      icon: Icons.image_outlined,
                      title: 'Sin imágenes guardadas',
                      description: 'Aún no tienes imágenes guardadas. Cuando generes una desde Tale Star Web, aparecerá aquí.',
                    ),
                  ],
                ),
              );
            }

            final togglingId = (state is LibraryLoaded) ? state.togglingFavoriteId : null;

            return RefreshIndicator(
              onRefresh: () => context.read<LibraryCubit>().loadLibrary(type: ContentType.image),
              child: ListView.separated(
                key: const Key('images_list'),
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: images.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final item = images[index];
                  return LibraryItemCard(
                    key: Key('image_card_${item.id}'),
                    item: item,
                    isTogglingFavorite: togglingId == item.id,
                    onTap: () {
                      context.pushNamed(
                        RouteNames.imageViewer,
                        pathParameters: {'id': item.id},
                        extra: item,
                      );
                    },
                    onToggleFavorite: () =>
                        context.read<LibraryCubit>().toggleFavorite(item),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
