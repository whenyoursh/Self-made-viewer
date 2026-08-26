import 'dart:typed_data';
import 'dart:ui' as ui;
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

  // In-memory cache for raw page bytes
  final Map<String, Uint8List> _pageCache = {};
  
  // In-memory LRU cache for pre-decoded ui.Image (Eliminates page turning flicker)
  final Map<int, ui.Image> _decodedImageCache = {};
  final List<int> _decodedLruKeys = [];
  static const int _maxDecodedCacheSize = 25;

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
    String? actualPath,
  }) async {
    _pageCache.clear();
    _clearDecodedCache();
    _cachedEntries.clear();

    final archive = ZipDecoder().decodeBytes(archiveBytes, verify: false);
    _cachedArchivePath = actualPath ?? title;

    final validEntries = <ArchiveFile>[];
    for (final f in archive.files) {
      if (!f.isFile) continue;
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

    // Sort hierarchically by folder path and filename naturally
    validEntries.sort((a, b) {
      return NaturalSort.comparePath(a.name, b.name);
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
      _pageCache['${actualPath ?? title}:0'] = coverBytes;
    }

    return ComicBook(
      path: actualPath ?? title,
      title: title,
      format: ComicFormat.zip,
      pages: pages,
      coverBytes: coverBytes,
    );
  }

  /// Loads comic metadata from a file or folder path (Native only)
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
      return loadComicFromBytes(
        title: p.basenameWithoutExtension(path),
        archiveBytes: bytes,
        actualPath: path,
      );
    }
  }

  /// Recursively scans directory for comic image files and sorts hierarchically
  Future<ComicBook> _loadFromDirectory(dynamic dir) async {
    final title = p.basename(dir.path);
    final imagePaths = <String>[];

    await _collectImagesRecursive(dir, imagePaths);

    if (imagePaths.isEmpty) {
      throw const FormatException('폴더 및 하위 폴더 내에 지원되는 이미지 파일이 없습니다.');
    }

    // Sort hierarchically relative to the root directory
    imagePaths.sort((a, b) {
      final relA = p.relative(a, from: dir.path);
      final relB = p.relative(b, from: dir.path);
      return NaturalSort.comparePath(relA, relB);
    });

    final pages = <ComicPageInfo>[];
    for (int i = 0; i < imagePaths.length; i++) {
      final fullPath = imagePaths[i];
      final fileName = p.basename(fullPath);
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

  Future<void> _collectImagesRecursive(dynamic dir, List<String> result) async {
    final entities = await dir.list().toList();
    for (final entity in entities) {
      final isDir = await io.FileSystemEntity.isDirectory(entity.path);
      if (isDir) {
        final name = p.basename(entity.path);
        if (name.startsWith('.') || name.contains('__MACOSX')) continue;
        await _collectImagesRecursive(entity, result);
      } else {
        final ext = p.extension(entity.path).toLowerCase();
        if (_validExtensions.contains(ext)) {
          result.add(entity.path);
        }
      }
    }
  }

  /// Loads the raw image bytes for a specific page with O(1) index lookup
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
      if (pageInfo.index >= 0 && pageInfo.index < _cachedEntries.length) {
        final entry = _cachedEntries[pageInfo.index];
        final bytes = _extractBytes(entry);
        if (_pageCache.length > 35) {
          _pageCache.remove(_pageCache.keys.first);
        }
        _pageCache[cacheKey] = bytes;
        return bytes;
      } else {
        throw FormatException('압축 내 페이지를 찾을 수 없습니다: index ${pageInfo.index}');
      }
    }
  }

  /// Loads or retrieves a pre-decoded ui.Image for seamless 60fps page display
  Future<ui.Image> loadDecodedImage({
    required String comicPath,
    required ComicPageInfo pageInfo,
    required bool isFolder,
  }) async {
    final index = pageInfo.index;
    if (_decodedImageCache.containsKey(index)) {
      _touchDecodedLru(index);
      return _decodedImageCache[index]!;
    }

    final bytes = await loadPageBytes(
      comicPath: comicPath,
      pageInfo: pageInfo,
      isFolder: isFolder,
    );

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    _storeDecodedImage(index, image);
    return image;
  }

  /// Returns already cached decoded image synchronously if available (0ms delay)
  ui.Image? getCachedDecodedImage(int index) {
    if (_decodedImageCache.containsKey(index)) {
      _touchDecodedLru(index);
      return _decodedImageCache[index];
    }
    return null;
  }

  /// Preloads upcoming and previous pages in the background to eliminate all page flip delay
  void preloadPages({
    required int centerIndex,
    required String comicPath,
    required List<ComicPageInfo> pages,
    required bool isFolder,
    int window = 4,
  }) {
    final start = (centerIndex - 2).clamp(0, pages.length - 1);
    final end = (centerIndex + window).clamp(0, pages.length - 1);

    for (int i = start; i <= end; i++) {
      if (!_decodedImageCache.containsKey(i)) {
        // Asynchronously decode in background
        loadDecodedImage(
          comicPath: comicPath,
          pageInfo: pages[i],
          isFolder: isFolder,
        ).catchError((_) {});
      }
    }
  }

  void _touchDecodedLru(int index) {
    _decodedLruKeys.remove(index);
    _decodedLruKeys.add(index);
  }

  void _storeDecodedImage(int index, ui.Image image) {
    if (_decodedImageCache.length >= _maxDecodedCacheSize) {
      if (_decodedLruKeys.isNotEmpty) {
        final oldestIndex = _decodedLruKeys.removeAt(0);
        final oldImage = _decodedImageCache.remove(oldestIndex);
        oldImage?.dispose();
      }
    }
    _decodedImageCache[index] = image;
    _touchDecodedLru(index);
  }

  void _clearDecodedCache() {
    for (final img in _decodedImageCache.values) {
      img.dispose();
    }
    _decodedImageCache.clear();
    _decodedLruKeys.clear();
  }

  void clearCache() {
    _pageCache.clear();
    _clearDecodedCache();
    _cachedEntries.clear();
    _cachedArchivePath = null;
  }
}
