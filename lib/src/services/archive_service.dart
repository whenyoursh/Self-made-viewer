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
  
  // List of sorted archive entries for O(1) direct index access
  List<ArchiveFile> _cachedEntries = [];
  String? _cachedArchivePath;

  /// Helper to safely extract byte content from ArchiveFile across Web and Native
  static Uint8List _extractBytes(ArchiveFile file) {
    try {
      final content = file.content;
      if (content is Uint8List) {
        return content;
      } else if (content is List<int>) {
        return Uint8List.fromList(content);
      } else if (content is InputStream) {
        return Uint8List.fromList(content.toUint8List());
      } else if (file.rawContent != null) {
        return Uint8List.fromList(file.rawContent!.toUint8List());
      }
    } catch (e) {
      debugPrint('Error extracting archive file bytes: $e');
    }
    return Uint8List(0);
  }

  /// Loads comic directly from in-memory archive bytes (Ideal for Web & Mobile)
  Future<ComicBook> loadComicFromBytes({
    required String title,
    required Uint8List archiveBytes,
  }) async {
    _pageCache.clear();
    _cachedEntries.clear();

    final archive = ZipDecoder().decodeBytes(archiveBytes, verify: false);
    _cachedArchivePath = title;

    final validEntries = <ArchiveFile>[];
    for (final f in archive.files) {
      if (!f.isFile) continue;
      // Normalize slashes
      final normalizedName = f.name.replaceAll('\\', '/');
      if (normalizedName.contains('__MACOSX') ||
          p.basename(normalizedName).startsWith('.') ||
          normalizedName.contains('/.')) {
        continue;
      }
      final ext = p.extension(normalizedName).toLowerCase();
      if (_validExtensions.contains(ext)) {
        validEntries.add(f);
      }
    }

    if (validEntries.isEmpty) {
      throw const FormatException('압축 파일 내에 지원되는 이미지(JPG, PNG, WEBP 등)가 없습니다.\n(하위 폴더 내부 이미지도 지원합니다)');
    }

    // Sort naturally by filename
    validEntries.sort((a, b) {
      final aName = a.name.replaceAll('\\', '/');
      final bName = b.name.replaceAll('\\', '/');
      return NaturalSort.compare(p.basename(aName), p.basename(bName));
    });

    _cachedEntries = validEntries;

    final pages = <ComicPageInfo>[];
    for (int i = 0; i < validEntries.length; i++) {
      final entry = validEntries[i];
      final normalizedName = entry.name.replaceAll('\\', '/');
      pages.add(ComicPageInfo(
        index: i,
        name: p.basename(normalizedName),
        internalPath: normalizedName,
      ));
    }

    // Extract cover image (Page 1)
    Uint8List? coverBytes;
    if (validEntries.isNotEmpty) {
      coverBytes = _extractBytes(validEntries.first);
      _pageCache['$title:0'] = coverBytes;
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
      final file = io.File(path);
      final bytes = Uint8List.fromList(await file.readAsBytes());
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
        coverBytes = Uint8List.fromList(await io.File(pages.first.internalPath!).readAsBytes());
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

  /// Loads the image bytes for a specific page with O(1) index lookup
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
      final bytes = Uint8List.fromList(await file.readAsBytes());
      _pageCache[cacheKey] = bytes;
      return bytes;
    } else {
      // Direct O(1) index access from cached entries
      if (pageInfo.index >= 0 && pageInfo.index < _cachedEntries.length) {
        final entry = _cachedEntries[pageInfo.index];
        final bytes = _extractBytes(entry);
        if (_pageCache.length > 25) {
          _pageCache.remove(_pageCache.keys.first);
        }
        _pageCache[cacheKey] = bytes;
        return bytes;
      } else {
        throw FormatException('압축 내 페이지를 찾을 수 없습니다: index ${pageInfo.index}');
      }
    }
  }

  void clearCache() {
    _pageCache.clear();
    _cachedEntries.clear();
    _cachedArchivePath = null;
  }
}
