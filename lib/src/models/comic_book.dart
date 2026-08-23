import 'dart:typed_data';

enum ComicFormat {
  zip,
  cbz,
  folder,
}

class ComicPageInfo {
  final int index;
  final String name;
  final String? internalPath; // Path inside archive or directory

  ComicPageInfo({
    required this.index,
    required this.name,
    this.internalPath,
  });
}

class ComicBook {
  final String path;
  final String title;
  final ComicFormat format;
  final List<ComicPageInfo> pages;
  final Uint8List? coverBytes;

  ComicBook({
    required this.path,
    required this.title,
    required this.format,
    required this.pages,
    this.coverBytes,
  });

  int get totalPages => pages.length;

  ComicBook copyWith({
    String? path,
    String? title,
    ComicFormat? format,
    List<ComicPageInfo>? pages,
    Uint8List? coverBytes,
  }) {
    return ComicBook(
      path: path ?? this.path,
      title: title ?? this.title,
      format: format ?? this.format,
      pages: pages ?? this.pages,
      coverBytes: coverBytes ?? this.coverBytes,
    );
  }
}
