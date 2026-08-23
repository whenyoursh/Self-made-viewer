import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../models/comic_book.dart';
import '../models/history_record.dart';
import 'storage_provider.dart';

class HistoryState {
  final List<RecentBookRecord> recentBooks; // Max 5 items
  final List<RecentFolderRecord> recentFolders; // Max 10 items

  HistoryState({
    required this.recentBooks,
    required this.recentFolders,
  });

  HistoryState copyWith({
    List<RecentBookRecord>? recentBooks,
    List<RecentFolderRecord>? recentFolders,
  }) {
    return HistoryState(
      recentBooks: recentBooks ?? this.recentBooks,
      recentFolders: recentFolders ?? this.recentFolders,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final Ref _ref;

  HistoryNotifier(this._ref)
      : super(HistoryState(
          recentBooks: _ref.read(storageServiceProvider).getRecentBooks(),
          recentFolders: _ref.read(storageServiceProvider).getRecentFolders(),
        ));

  void refresh() {
    state = HistoryState(
      recentBooks: _ref.read(storageServiceProvider).getRecentBooks(),
      recentFolders: _ref.read(storageServiceProvider).getRecentFolders(),
    );
  }

  Future<void> recordBookOpened({
    required ComicBook book,
    required int currentPage,
  }) async {
    final storage = _ref.read(storageServiceProvider);

    String? coverBase64;
    if (book.coverBytes != null && book.coverBytes!.isNotEmpty) {
      // Encode cover thumbnail to base64 for quick display
      coverBase64 = base64Encode(book.coverBytes!);
    }

    final record = RecentBookRecord(
      path: book.path,
      title: book.title,
      lastReadPage: currentPage,
      totalPages: book.totalPages,
      lastReadAt: DateTime.now(),
      coverBase64: coverBase64,
    );

    await storage.saveRecentBook(record);
    refresh();
  }

  Future<void> recordFolderAccessed(String folderPath) async {
    final storage = _ref.read(storageServiceProvider);
    final folderName = p.basename(folderPath);

    final record = RecentFolderRecord(
      folderPath: folderPath,
      folderName: folderName,
      lastAccessedAt: DateTime.now(),
    );

    await storage.saveRecentFolder(record);
    refresh();
  }

  Future<void> removeRecentBook(String path) async {
    await _ref.read(storageServiceProvider).removeRecentBook(path);
    refresh();
  }

  Future<void> removeRecentFolder(String folderPath) async {
    await _ref.read(storageServiceProvider).removeRecentFolder(folderPath);
    refresh();
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(ref);
});
