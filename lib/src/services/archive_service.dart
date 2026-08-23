import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import '../models/comic_book.dart';
import '../utils/natural_sort.dart';

// Conditional import for non-web file IO
import 'dart:io' if (dart.library.html) 'archive_service_web_stub.dart' as io;

/// Service for parsing archives (ZIP/CBZ) and folders to load comic pages
class ArchiveService {
  static const Set<String> _validExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.bmp',
    '.gif',
  };

  // In-memory cache for loaded page bytes
  final Map<String, Uint8List> _pageCache = {};
  Archive? _cachedArchive;
  String? _cachedArchivePath;

  /// Loads comic directly from in-memory archive bytes (Ideal for Web & Mobile)
  Future<ComicBook> loadComicFromBytes({
    required String title,
    required Uint8List archiveBytes,
  }) async {
    final archive = ZipDecoder().decodeBytes(archiveBytes);
    _cachedArchive = archive;
    _cachedArchivePath = title;
    _pageCache.clear();

    final validEntries = archive.files.where((f) {
      if (!f.isFile) return false;
      final name = f.name;
      if (name.contains('__MACOSX') || name.startsWith('.') || name.contains('/.')) {
        return false;
      }
      final ext = p.extension(name).toLowerCase();
      return _validExtensions.contains(ext);
    }).toList();

    if (validEntries.isEmpty) {
      throw const FormatException('압축 파일 내에 지원되는 이미지 파일이 없습니다.');
    }

    final sortedEntryNames = NaturalSort.sortList(validEntries.map((e) => e.name).toList());

    final pages = <ComicPageInfo>[];
    for (int i = 0; i < sortedEntryNames.length; i++) {
      final entryName = sortedEntryNames[i];
      pages.add(ComicPageInfo(
        index: i,
        name: p.basename(entryName),
        internalPath: entryName,
      ));
    }

    // Cache cover
    Uint8List? coverBytes;
    if (pages.isNotEmpty) {
      final firstEntry = archive.findFile(pages.first.internalPath!);
      if (firstEntry != null) {
        coverBytes = Uint8List.fromList(firstEntry.content as List<int>);
        _pageCache['$title:0'] = coverBytes;
      }
    }

    return ComicBook(
      path: title,
      title: title,
      format: ComicFormat.zip,
      pages: pages,
      coverBytes: coverBytes,
    );
  }

  /// Loads comic metadata (pages list and cover) from a file or folder path (Native only)
  Future<ComicBook> loadComicBook(String path) async {
    if (kIsWeb) {
      throw UnsupportedError('웹 환경에서는 메모리 바이트 방식으로 로드해야 합니다.');
    }

    final isDirectory = await io.FileSystemEntity.isDirectory(path);
    if (isDirectory) {
      return _loadFromDirectory(io.Directory(path));
    } else {
      final ext = p.extension(path).toLowerCase();
      final file = io.File(path);
      final bytes = await file.readAsBytes();
      return loadComicFromBytes(title: p.basenameWithoutExtension(path), archiveBytes: bytes);
    }
  }

  Future<ComicBook> _loadFromDirectory(dynamic dir) async {
    final title = p.basename(dir.path);
    final entities = await dir.list().toList();

    final imageFiles = entities.where((f) {
      final ext = p.extension(f.path).toLowerCase();
      return _validExtensions.contains(ext);
    }).toList();

    if (imageFiles.isEmpty) {
      throw const FormatException('폴더 내에 지원되는 이미지 파일이 없습니다.');
    }

    final sortedNames = NaturalSort.sortList(imageFiles.map((f) => p.basename(f.path)).toList().cast<String>());

    final pages = <ComicPageInfo>[];
    for (int i = 0; i < sortedNames.length; i++) {
      final fileName = sortedNames[i];
      final fullPath = p.join(dir.path, fileName);
      pages.add(ComicPageInfo(
        index: i,
        name: fileName,
        internalPath: fullPath,
      ));
    }

    Uint8List? coverBytes;
    if (pages.isNotEmpty) {
      try {
        coverBytes = await io.File(pages.first.internalPath!).readAsBytes();
      } catch (_) {}
    }

    return ComicBook(
      path: dir.path,
      title: title,
      format: ComicFormat.folder,
      pages: pages,
      coverBytes: coverBytes,
    );
  }

  /// Loads the image bytes for a specific page
  Future<Uint8List> loadPageBytes({
    required String comicPath,
    required ComicPageInfo pageInfo,
    required bool isFolder,
  }) async {
    final cacheKey = '$comicPath:${pageInfo.index}';
    if (_pageCache.containsKey(cacheKey)) {
      return _pageCache[cacheKey]!;
    }

    if (isFolder && !kIsWeb) {
      final file = io.File(pageInfo.internalPath!);
      final bytes = await file.readAsBytes();
      _pageCache[cacheKey] = bytes;
      return bytes;
    } else {
      if (_cachedArchive == null) {
        if (!kIsWeb) {
          final file = io.File(comicPath);
          final fileBytes = await file.readAsBytes();
          _cachedArchive = ZipDecoder().decodeBytes(fileBytes);
          _cachedArchivePath = comicPath;
        } else {
          throw const FormatException('웹 캐시에서 아카이브를 찾을 수 없습니다.');
        }
      }

      final entry = _cachedArchive!.findFile(pageInfo.internalPath!);
      if (entry == null) {
        throw FormatException('압축 내 페이지를 찾을 수 없습니다: ${pageInfo.internalPath}');
      }

      final bytes = Uint8List.fromList(entry.content as List<int>);
      if (_pageCache.length > 25) {
        _pageCache.remove(_pageCache.keys.first);
      }
      _pageCache[cacheKey] = bytes;
      return bytes;
    }
  }

  void clearCache() {
    _pageCache.clear();
    _cachedArchive = null;
    _cachedArchivePath = null;
  }
}
