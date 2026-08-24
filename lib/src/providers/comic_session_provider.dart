import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comic_book.dart';
import '../models/viewer_settings.dart';
import 'history_provider.dart';
import 'settings_provider.dart';
import 'storage_provider.dart';

class ComicSessionState {
  final ComicBook? book;
  final int currentPageIndex; // 0-based index
  final bool isLoading;
  final String? errorMessage;
  final bool areControlsVisible;

  const ComicSessionState({
    this.book,
    this.currentPageIndex = 0,
    this.isLoading = false,
    this.errorMessage,
    this.areControlsVisible = false,
  });

  int get totalPages => book?.totalPages ?? 0;
  int get displayCurrentPage => (currentPageIndex + 1).clamp(1, totalPages > 0 ? totalPages : 1);
  bool get hasBook => book != null && book!.pages.isNotEmpty;

  ComicSessionState copyWith({
    ComicBook? book,
    int? currentPageIndex,
    bool? isLoading,
    String? errorMessage,
    bool? areControlsVisible,
  }) {
    return ComicSessionState(
      book: book ?? this.book,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      areControlsVisible: areControlsVisible ?? this.areControlsVisible,
    );
  }
}

class ComicSessionNotifier extends StateNotifier<ComicSessionState> {
  final Ref _ref;

  ComicSessionNotifier(this._ref) : super(const ComicSessionState());

  Future<void> openBookDirect(ComicBook book, {int? initialPage}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    int targetPage = 0;
    if (initialPage != null && initialPage > 0 && initialPage <= book.totalPages) {
      targetPage = initialPage - 1;
    }

    state = ComicSessionState(
      book: book,
      currentPageIndex: targetPage,
      isLoading: false,
      areControlsVisible: false,
    );

    _ref.read(historyProvider.notifier).recordBookOpened(
      book: book,
      currentPage: targetPage + 1,
    );

    _triggerPreload(targetPage);
  }

  Future<void> openBook(String path, {int? initialPage}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final archiveService = _ref.read(archiveServiceProvider);
      final book = await archiveService.loadComicBook(path);

      int targetPage = 0;
      if (initialPage != null && initialPage > 0 && initialPage <= book.totalPages) {
        targetPage = initialPage - 1;
      }

      state = ComicSessionState(
        book: book,
        currentPageIndex: targetPage,
        isLoading: false,
        areControlsVisible: false,
      );

      // Record to history
      _ref.read(historyProvider.notifier).recordBookOpened(
        book: book,
        currentPage: targetPage + 1,
      );

      _triggerPreload(targetPage);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '만화책을 여는 중 오류가 발생했습니다: $e',
      );
    }
  }

  void toggleControls() {
    state = state.copyWith(areControlsVisible: !state.areControlsVisible);
  }

  void hideControls() {
    if (state.areControlsVisible) {
      state = state.copyWith(areControlsVisible: false);
    }
  }

  void nextPage() {
    if (!state.hasBook) return;
    final settings = _ref.read(settingsProvider);
    final step = settings.viewMode == ViewMode.dual ? 2 : 1;

    final nextIndex = state.currentPageIndex + step;
    if (nextIndex < state.totalPages) {
      _setCurrentPageIndex(nextIndex);
    }
  }

  void prevPage() {
    if (!state.hasBook) return;
    final settings = _ref.read(settingsProvider);
    final step = settings.viewMode == ViewMode.dual ? 2 : 1;

    final prevIndex = state.currentPageIndex - step;
    if (prevIndex >= 0) {
      _setCurrentPageIndex(prevIndex);
    } else if (state.currentPageIndex > 0) {
      _setCurrentPageIndex(0);
    }
  }

  void jumpToPage(int pageIndex) {
    if (!state.hasBook) return;
    final clamped = pageIndex.clamp(0, state.totalPages - 1);
    _setCurrentPageIndex(clamped);
  }

  void handleTouchZone({required bool isLeft}) {
    final settings = _ref.read(settingsProvider);
    final action = isLeft ? settings.leftTouchAction : settings.rightTouchAction;

    switch (action) {
      case TouchAction.nextPage:
        nextPage();
        break;
      case TouchAction.prevPage:
        prevPage();
        break;
      case TouchAction.toggleControls:
        toggleControls();
        break;
      case TouchAction.none:
        break;
    }
  }

  void _setCurrentPageIndex(int index) {
    state = state.copyWith(currentPageIndex: index);

    if (state.book != null) {
      _ref.read(historyProvider.notifier).recordBookOpened(
        book: state.book!,
        currentPage: index + 1,
      );
      _triggerPreload(index);
    }
  }

  void _triggerPreload(int centerIndex) {
    if (!state.hasBook) return;
    final archiveService = _ref.read(archiveServiceProvider);
    final book = state.book!;
    archiveService.preloadPages(
      centerIndex: centerIndex,
      comicPath: book.path,
      pages: book.pages,
      isFolder: book.format == ComicFormat.folder,
    );
  }

  ui.Image? getCachedDecodedImage(int index) {
    final archiveService = _ref.read(archiveServiceProvider);
    return archiveService.getCachedDecodedImage(index);
  }

  Future<ui.Image> loadPageImage(int index) async {
    if (!state.hasBook || index < 0 || index >= state.totalPages) {
      throw RangeError('Page index out of range: $index');
    }

    final book = state.book!;
    try {
      final dynamic dynBook = book;
      if (dynBook.pageByteMap != null) {
        final map = dynBook.pageByteMap as Map<int, Uint8List>;
        if (map.containsKey(index)) {
          final codec = await ui.instantiateImageCodec(map[index]!);
          final frame = await codec.getNextFrame();
          return frame.image;
        }
      }
    } catch (_) {}

    final archiveService = _ref.read(archiveServiceProvider);
    final pageInfo = book.pages[index];
    final isFolder = book.format == ComicFormat.folder;

    return archiveService.loadDecodedImage(
      comicPath: book.path,
      pageInfo: pageInfo,
      isFolder: isFolder,
    );
  }

  Future<Uint8List> loadPageBytes(int index) async {
    if (!state.hasBook || index < 0 || index >= state.totalPages) {
      throw RangeError('Page index out of range: $index');
    }

    final book = state.book!;
    try {
      final dynamic dynBook = book;
      if (dynBook.pageByteMap != null) {
        final map = dynBook.pageByteMap as Map<int, Uint8List>;
        if (map.containsKey(index)) {
          return map[index]!;
        }
      }
    } catch (_) {}

    final archiveService = _ref.read(archiveServiceProvider);
    final pageInfo = book.pages[index];
    final isFolder = book.format == ComicFormat.folder;

    return archiveService.loadPageBytes(
      comicPath: book.path,
      pageInfo: pageInfo,
      isFolder: isFolder,
    );
  }
}

final comicSessionProvider = StateNotifierProvider<ComicSessionNotifier, ComicSessionState>((ref) {
  return ComicSessionNotifier(ref);
});
