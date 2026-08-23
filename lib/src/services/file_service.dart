import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../utils/natural_sort.dart';

// Conditional import for non-web file IO
import 'dart:io' if (dart.library.html) 'archive_service_web_stub.dart' as io;

class FileItemInfo {
  final String path;
  final String name;
  final bool isDirectory;
  final int? fileCount;

  FileItemInfo({
    required this.path,
    required this.name,
    required this.isDirectory,
    this.fileCount,
  });
}

class PickedComicResult {
  final String name;
  final String? path;
  final Uint8List? bytes;

  PickedComicResult({
    required this.name,
    this.path,
    this.bytes,
  });
}

class FileService {
  static const Set<String> comicExtensions = {'.zip', '.cbz'};
  static const Set<String> imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.bmp', '.gif'};

  /// Requests storage permissions on Android/devices (Skipped on Web)
  Future<bool> requestStoragePermission() async {
    if (kIsWeb) return true;

    if (io.Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;

      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) return true;

      final photosStatus = await Permission.photos.request();
      return photosStatus.isGranted;
    }
    return true;
  }

  /// Picks a comic archive file (.zip, .cbz) supporting both Web & Native with stream fallback
  Future<PickedComicResult?> pickComic() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: kIsWeb ? FileType.any : FileType.custom,
        allowedExtensions: kIsWeb ? null : ['zip', 'cbz'],
        withData: true,
        withReadStream: kIsWeb,
        dialogTitle: '만화 압축 파일 선택 (ZIP, CBZ)',
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        Uint8List? bytes = file.bytes;

        // If bytes is null on Web for large files, consume readStream
        if (bytes == null && file.readStream != null) {
          final builder = BytesBuilder();
          await for (final chunk in file.readStream!) {
            builder.add(chunk);
          }
          bytes = builder.toBytes();
        }

        return PickedComicResult(
          name: file.name,
          path: file.path,
          bytes: bytes,
        );
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
    return null;
  }

  /// Picks a comic folder (Native only)
  Future<String?> pickComicDirectory() async {
    if (kIsWeb) return null;
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '만화 이미지 폴더 선택',
      );
      return selectedDirectory;
    } catch (e) {
      debugPrint('Directory picker error: $e');
    }
    return null;
  }

  /// Lists comic archives and image folders within a directory
  Future<List<FileItemInfo>> listFolderContents(String folderPath) async {
    if (kIsWeb) return [];
    final dir = io.Directory(folderPath);
    if (!await io.FileSystemEntity.isDirectory(folderPath)) return [];

    final entities = await dir.list().toList();
    final items = <FileItemInfo>[];

    for (final entity in entities) {
      final name = p.basename(entity.path);
      if (name.startsWith('.') || name.contains('__MACOSX')) continue;

      final isDir = await io.FileSystemEntity.isDirectory(entity.path);
      if (isDir) {
        items.add(FileItemInfo(
          path: entity.path,
          name: name,
          isDirectory: true,
        ));
      } else {
        final ext = p.extension(entity.path).toLowerCase();
        if (comicExtensions.contains(ext)) {
          items.add(FileItemInfo(
            path: entity.path,
            name: name,
            isDirectory: false,
          ));
        }
      }
    }

    items.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return NaturalSort.compare(a.name, b.name);
    });

    return items;
  }
}
