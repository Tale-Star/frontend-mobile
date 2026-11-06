import 'package:equatable/equatable.dart';
import '../../domain/entities/story_detail.dart';
import '../../domain/entities/story_page_detail.dart';

/// Estados del ciclo de vida del lector de cuentos tradicional 2D (Fase 3).
abstract class ReaderState extends Equatable {
  const ReaderState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de cargar cualquier cuento.
class ReaderInitial extends ReaderState {
  const ReaderInitial();
}

/// Estado de carga mientras se recuperan el cuento y sus páginas.
class ReaderLoading extends ReaderState {
  const ReaderLoading();
}

/// Estado exitoso: el cuento contiene una o más páginas ordenadas y legibles.
class ReaderLoaded extends ReaderState {
  final StoryDetail story;
  final List<StoryPageDetail> pages;
  final int currentPageIndex;

  const ReaderLoaded({
    required this.story,
    required this.pages,
    this.currentPageIndex = 0,
  }) : assert(pages.length > 0, 'ReaderLoaded requiere al menos una página');

  int get totalPages => pages.length;
  int get currentPageNumber => pages[currentPageIndex].pageNumber;
  StoryPageDetail get currentPage => pages[currentPageIndex];
  bool get hasPreviousPage => currentPageIndex > 0;
  bool get hasNextPage => currentPageIndex < pages.length - 1;
  bool get isFirstPage => currentPageIndex == 0;
  bool get isLastPage => currentPageIndex == pages.length - 1;

  ReaderLoaded copyWith({
    StoryDetail? story,
    List<StoryPageDetail>? pages,
    int? currentPageIndex,
  }) {
    return ReaderLoaded(
      story: story ?? this.story,
      pages: pages ?? this.pages,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
    );
  }

  @override
  List<Object?> get props => [story, pages, currentPageIndex];
}

/// Estado para cuentos válidos que aún no poseen páginas redactadas.
class ReaderEmpty extends ReaderState {
  final StoryDetail story;

  const ReaderEmpty({required this.story});

  @override
  List<Object?> get props => [story];
}

/// Estado de error cuando falla la recuperación del cuento o de las páginas.
class ReaderError extends ReaderState {
  final String message;
  final int? statusCode;

  const ReaderError({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

