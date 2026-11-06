import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ts_app_bar.dart';
import '../../../../shared/widgets/ts_button.dart';
import '../../../../shared/widgets/ts_empty_state.dart';
import '../../../../shared/widgets/ts_loading_shimmer.dart';
import '../../../../shared/widgets/ts_snackbar.dart';
import '../../../music/domain/entities/music_track.dart';
import '../../../music/presentation/cubit/music_player_cubit.dart';
import '../../domain/entities/library_item_entity.dart';
import '../cubit/library_cubit.dart';
import '../cubit/library_state.dart';
import '../widgets/library_item_card.dart';

/// Pantalla principal unificada de la Biblioteca (Pestaña 4).
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<LibraryCubit>();
    if (cubit.state is LibraryInitial) {
      cubit.loadLibrary();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(BuildContext context, LibraryItemEntity item) {
    if (item.isImage) {
      context.pushNamed(
        RouteNames.imageViewer,
        pathParameters: {'id': item.id},
        extra: item,
      );
    } else if (item.isStory) {
      context.pushNamed(
        RouteNames.reader,
        pathParameters: {'storyId': item.resourceId},
      );
    } else if (item.isMusic) {
      final track = MusicTrack.fromLibraryItem(
        item,
        localAssetPath: AppConfig.instance.useMockData ? 'assets/demo/demo_song.wav' : null,
      );
      context.read<MusicPlayerCubit>().playTrack(track);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: const TsAppBar(
        title: 'Biblioteca',
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de búsqueda con debounce
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: TextField(
                key: const Key('library_search_field'),
                controller: _searchController,
                onChanged: (text) => context.read<LibraryCubit>().onSearchChanged(text),
                style: AppTypography.bodyMedium(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar creaciones por título o detalle...',
                  hintStyle: AppTypography.bodyMedium(
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                    size: 22,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Limpiar búsqueda',
                          icon: Icon(
                            Icons.clear,
                            size: 20,
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            context.read<LibraryCubit>().searchImmediate('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.pill,
                    borderSide: BorderSide(
                      color: isDark ? AppColors.surface3Dark : AppColors.surface3Light,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadii.pill,
                    borderSide: BorderSide(
                      color: isDark ? AppColors.surface3Dark : AppColors.surface3Light,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadii.pill,
                    borderSide: BorderSide(
                      color: isDark ? AppColors.primary500 : AppColors.primary900,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // Chips horizontales de filtrado oficial
            BlocBuilder<LibraryCubit, LibraryState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        key: const Key('filter_all'),
                        label: 'Todos',
                        isDark: isDark,
                        isSelected: state.activeFilter == null && !state.favoriteOnly,
                        onSelected: () {
                          if (state.favoriteOnly) {
                            context.read<LibraryCubit>().setFavoriteOnly(false);
                          }
                          context.read<LibraryCubit>().setTypeFilter(null);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        key: const Key('filter_images'),
                        label: 'Imágenes',
                        icon: Icons.image_rounded,
                        isDark: isDark,
                        isSelected: state.activeFilter == ContentType.image && !state.favoriteOnly,
                        onSelected: () {
                          if (state.favoriteOnly) {
                            context.read<LibraryCubit>().setFavoriteOnly(false);
                          }
                          context.read<LibraryCubit>().setTypeFilter(ContentType.image);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        key: const Key('filter_stories'),
                        label: 'Cuentos',
                        icon: Icons.menu_book_rounded,
                        isDark: isDark,
                        isSelected: state.activeFilter == ContentType.story && !state.favoriteOnly,
                        onSelected: () {
                          if (state.favoriteOnly) {
                            context.read<LibraryCubit>().setFavoriteOnly(false);
                          }
                          context.read<LibraryCubit>().setTypeFilter(ContentType.story);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        key: const Key('filter_music'),
                        label: 'Música',
                        icon: Icons.music_note_rounded,
                        isDark: isDark,
                        isSelected: state.activeFilter == ContentType.music && !state.favoriteOnly,
                        onSelected: () {
                          if (state.favoriteOnly) {
                            context.read<LibraryCubit>().setFavoriteOnly(false);
                          }
                          context.read<LibraryCubit>().setTypeFilter(ContentType.music);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        key: const Key('filter_favorites'),
                        label: 'Favoritos',
                        icon: Icons.favorite_rounded,
                        isDark: isDark,
                        isSelected: state.favoriteOnly,
                        onSelected: () {
                          context.read<LibraryCubit>().setFavoriteOnly(!state.favoriteOnly);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            // Vista principal reactiva con pull-to-refresh
            Expanded(
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

                  if (state is LibraryEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => context.read<LibraryCubit>().refresh(),
                      child: ListView(
                        children: [
                          const SizedBox(height: 60),
                          TsEmptyState(
                            icon: state.favoriteOnly
                                ? Icons.favorite_border_rounded
                                : (state.searchQuery.isNotEmpty
                                    ? Icons.search_off_rounded
                                    : Icons.auto_stories_outlined),
                            title: state.favoriteOnly
                                ? 'Sin favoritos aún'
                                : (state.searchQuery.isNotEmpty
                                    ? 'Sin coincidencias'
                                    : 'Tu biblioteca está vacía'),
                            description: state.favoriteOnly
                                ? 'Marca tus cuentos o ilustraciones con el corazón para verlos rápidamente aquí.'
                                : (state.searchQuery.isNotEmpty
                                    ? 'No encontramos contenidos para "${state.searchQuery}". Intenta con otra palabra.'
                                    : 'Aún no tienes contenidos guardados. Cuando guardes uno desde Tale Star Web, aparecerá aquí.'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is LibraryError && state.previousItems.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Problema de conexión',
                              style: AppTypography.titleLarge(),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TsButton(
                              width: 180,
                              label: 'Reintentar',
                              icon: Icons.refresh_rounded,
                              onPressed: () => context.read<LibraryCubit>().refresh(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final items = (state is LibraryLoaded)
                      ? state.items
                      : ((state is LibraryError) ? state.previousItems : <LibraryItemEntity>[]);

                  final togglingId = (state is LibraryLoaded) ? state.togglingFavoriteId : null;

                  return RefreshIndicator(
                    onRefresh: () => context.read<LibraryCubit>().refresh(),
                    child: ListView.separated(
                      key: const Key('library_items_list'),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return LibraryItemCard(
                          key: Key('card_${item.id}'),
                          item: item,
                          isTogglingFavorite: togglingId == item.id,
                          onTap: () => _onItemTapped(context, item),
                          onToggleFavorite: () =>
                              context.read<LibraryCubit>().toggleFavorite(item),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    Key? key,
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onSelected,
    required bool isDark,
  }) {
    return FilterChip(
      key: key,
      selected: isSelected,
      onSelected: (_) => onSelected(),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTypography.bodySmall(
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ).copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
          ),
        ],
      ),
      selectedColor: isDark ? AppColors.primary700 : AppColors.primary900,
      backgroundColor: isDark ? AppColors.surface2Dark : AppColors.surfaceLight,
      checkmarkColor: Colors.transparent,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.pill,
        side: BorderSide(
          color: isSelected
              ? (isDark ? AppColors.primary500 : AppColors.primary900)
              : (isDark ? AppColors.surface3Dark : AppColors.surface3Light),
        ),
      ),
    );
  }
}
