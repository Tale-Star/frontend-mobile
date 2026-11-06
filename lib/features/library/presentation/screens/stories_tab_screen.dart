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

/// Pestaña 2 oficial: Colección de Cuentos Educativos.
class StoriesTabScreen extends StatefulWidget {
  const StoriesTabScreen({super.key});

  @override
  State<StoriesTabScreen> createState() => _StoriesTabScreenState();
}

class _StoriesTabScreenState extends State<StoriesTabScreen> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<LibraryCubit>();
    if (cubit.state is LibraryInitial) {
      cubit.loadLibrary(type: ContentType.story);
    }
  }

  void _onStoryTapped(BuildContext context, LibraryItemEntity story) {
    context.pushNamed(
      RouteNames.reader,
      pathParameters: {'storyId': story.resourceId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: const TsAppBar(
        title: 'Cuentos',
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

            // Filtrar cuentos
            final stories = allItems.where((i) => i.isStory).toList();

            if (stories.isEmpty && state is! LibraryLoading) {
              return RefreshIndicator(
                onRefresh: () => context.read<LibraryCubit>().loadLibrary(type: ContentType.story),
                child: ListView(
                  children: const [
                    SizedBox(height: 80),
                    TsEmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'Sin cuentos guardados',
                      description: 'Aún no tienes cuentos guardados. Cuando crees uno desde Tale Star Web, aparecerá aquí.',
                    ),
                  ],
                ),
              );
            }

            final togglingId = (state is LibraryLoaded) ? state.togglingFavoriteId : null;

            return RefreshIndicator(
              onRefresh: () => context.read<LibraryCubit>().loadLibrary(type: ContentType.story),
              child: ListView.separated(
                key: const Key('stories_list'),
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: stories.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final item = stories[index];
                  return LibraryItemCard(
                    key: Key('story_card_${item.id}'),
                    item: item,
                    isTogglingFavorite: togglingId == item.id,
                    onTap: () => _onStoryTapped(context, item),
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
