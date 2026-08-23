import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import '../models/comic_book.dart';
import '../utils/natural_sort.dart';

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

  // In-memory cache for loaded page bytes to optimize memory on Fold devices
  final Map<String, Uint8List> _pageCache = {};
  Archive? _cachedArchive;
  String? _cachedArchivePath;

  /// Loads comic metadata (pages list and cover) from a file or folder path
  Future<ComicBook> loadComicBook(String path) async {
    final file = File(path);
    final isDirectory = await FileSystemEntity.isDirectory(path);

    if (isDirectory) {
      return _loadFromDirectory(Directory(path));
    } else {
      final ext = p.extension(path).toLowerCase();
      if (ext == '.zip' || ext == '.cbz') {
        return _loadFromArchive(file, ext == '.cbz' ? ComicFormat.cbz : ComicFormat.zip);
      } else {
        throw FormatException('지원하지 않는 파일 형식입니다: $ext');
      }
    }
  }

  Future<ComicBook> _loadFromDirectory(Directory dir) async {
    final title = p.basename(dir.path);
    final entities = await dir.list().toList();

    final imageFiles = entities.whereType<File>().where((f) {
      final ext = p.extension(f.path).toLowerCase();
      return _validExtensions.contains(ext);
    }).toList();

    if (imageFiles.isEmpty) {
      throw const FormatException('폴더 내에 지원되는 이미지 파일이 없습니다.');
    }

    final sortedNames = NaturalSort.sortList(imageFiles.map((f) => p.basename(f.path)).toList());

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
        coverBytes = await File(pages.first.internalPath!).readAsBytes();
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

  Future<ComicBook> _loadFromArchive(File file, ComicFormat format) async {
    final title = p.basenameWithoutExtension(file.path);
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    _cachedArchive = archive;
    _cachedArchivePath = file.path;
    _pageCache.clear();

    final validEntries = archive.files.where((f) {
      if (!f.isFile) return false;
      final name = f.name;
      // Skip MacOS and system junk
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

    Uint8List? coverBytes;
    if (pages.isNotEmpty) {
      coverBytes = await loadPageBytes(
        comicPath: file.path,
        pageInfo: pages.first,
        isFolder: false,
      );
    }

    return ComicBook(
      path: file.path,
      title: title,
      format: format,
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

    if (isFolder) {
      final file = File(pageInfo.internalPath!);
      final bytes = await file.readAsBytes();
      _pageCache[cacheKey] = bytes;
      return bytes;
    } else {
      if (_cachedArchive == null || _cachedArchivePath != comicPath) {
        final file = File(comicPath);
        final fileBytes = await file.readAsBytes();
        _cachedArchive = ZipDecoder().decodeBytes(fileBytes);
        _cachedArchivePath = comicPath;
      }

      final entry = _cachedArchive!.findFile(pageInfo.internalPath!);
      if (entry == null) {
        throw FormatException('압축 내 페이지를 찾을 수 없습니다: ${pageInfo.internalPath}');
      }

      final bytes = Uint8List.fromList(entry.content as List<int>);
      // Maintain maximum cache size of 20 pages in memory
      if (_pageCache.length > 20) {
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
