import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/ts_app_bar.dart';
import '../../../../shared/widgets/ts_empty_state.dart';
import '../../../../shared/widgets/ts_loading_shimmer.dart';
import '../../../../shared/widgets/ts_snackbar.dart';
import '../../../music/domain/entities/music_track.dart';
import '../../../music/presentation/cubit/music_player_cubit.dart';
import '../../domain/entities/library_item_entity.dart';
import '../cubit/library_cubit.dart';
import '../cubit/library_state.dart';
import '../widgets/library_item_card.dart';

/// Pestaña 3 oficial: Pistas Musicales Ambientales.
class MusicTabScreen extends StatefulWidget {
  const MusicTabScreen({super.key});

  @override
  State<MusicTabScreen> createState() => _MusicTabScreenState();
}

class _MusicTabScreenState extends State<MusicTabScreen> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<LibraryCubit>();
    if (cubit.state is LibraryInitial) {
      cubit.loadLibrary(type: ContentType.music);
    }
  }

  void _onMusicTapped(BuildContext context, LibraryItemEntity music) {
    final track = MusicTrack.fromLibraryItem(
      music,
      localAssetPath: AppConfig.instance.useMockData ? 'assets/demo/demo_song.wav' : null,
    );
    context.read<MusicPlayerCubit>().playTrack(track);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: const TsAppBar(
        title: 'Música',
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

            // Filtrar melodías
            final musicItems = allItems.where((i) => i.isMusic).toList();

            if (musicItems.isEmpty && state is! LibraryLoading) {
              return RefreshIndicator(
                onRefresh: () => context.read<LibraryCubit>().loadLibrary(type: ContentType.music),
                child: ListView(
                  children: const [
                    SizedBox(height: 80),
                    TsEmptyState(
                      icon: Icons.music_note_outlined,
                      title: 'Sin melodías guardadas',
                      description: 'Aún no tienes pistas musicales guardadas. Cuando generes música desde Tale Star Web, aparecerá aquí.',
                    ),
                  ],
                ),
              );
            }

            final togglingId = (state is LibraryLoaded) ? state.togglingFavoriteId : null;

            return RefreshIndicator(
              onRefresh: () => context.read<LibraryCubit>().loadLibrary(type: ContentType.music),
              child: ListView.separated(
                key: const Key('music_list'),
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: musicItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final item = musicItems[index];
                  return LibraryItemCard(
                    key: Key('music_card_${item.id}'),
                    item: item,
                    isTogglingFavorite: togglingId == item.id,
                    onTap: () => _onMusicTapped(context, item),
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
