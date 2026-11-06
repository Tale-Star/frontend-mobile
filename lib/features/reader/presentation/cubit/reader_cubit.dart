import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/reader_repository.dart';
import 'reader_state.dart';

/// Cubit que administra el ciclo de lectura tradicional 2D, ordenamiento y navegación de páginas.
class ReaderCubit extends Cubit<ReaderState> {
  final ReaderRepository readerRepository;
  String? _currentStoryId;

  ReaderCubit({required this.readerRepository}) : super(const ReaderInitial());

  /// Carga el cuento y su listado de páginas por su identificador único.
  Future<void> loadStory(String storyId) async {
    _currentStoryId = storyId;
    emit(const ReaderLoading());

    try {
      final story = await readerRepository.getStory(storyId);
      final pages = await readerRepository.getStoryPages(storyId);

      if (pages.isEmpty) {
        emit(ReaderEmpty(story: story));
      } else {
        emit(ReaderLoaded(
          story: story,
          pages: pages,
          currentPageIndex: 0,
        ));
      }
    } on Failure catch (failure) {
      emit(ReaderError(
        message: failure.message,
        statusCode: (failure is ServerFailure) ? failure.statusCode : null,
      ));
    } catch (e) {
      emit(ReaderError(
        message: 'No pudimos abrir el cuento en este momento: $e',
      ));
    }
  }

  /// Avanza a la siguiente página secuencial. No permite avanzar más allá de la última.
  void nextPage() {
    final currentState = state;
    if (currentState is ReaderLoaded && currentState.hasNextPage) {
      emit(currentState.copyWith(currentPageIndex: currentState.currentPageIndex + 1));
    }
  }

  /// Retrocede a la página anterior. No permite retroceder antes de la primera.
  void previousPage() {
    final currentState = state;
    if (currentState is ReaderLoaded && currentState.hasPreviousPage) {
      emit(currentState.copyWith(currentPageIndex: currentState.currentPageIndex - 1));
    }
  }

  /// Salta directamente a un índice de página específico si es válido.
  void goToPage(int index) {
    final currentState = state;
    if (currentState is ReaderLoaded) {
      if (index >= 0 && index < currentState.totalPages && index != currentState.currentPageIndex) {
        emit(currentState.copyWith(currentPageIndex: index));
      }
    }
  }

  /// Reintenta la carga en caso de error.
  Future<void> retry([String? storyId]) async {
    final targetId = storyId ?? _currentStoryId;
    if (targetId != null && targetId.isNotEmpty) {
      await loadStory(targetId);
    }
  }
}

