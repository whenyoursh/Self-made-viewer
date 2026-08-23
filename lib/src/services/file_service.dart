import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../utils/natural_sort.dart';

class FileItemInfo {
  final String path;
  final String name;
  final bool isDirectory;
  final int? fileCount; // If directory

  FileItemInfo({
    required this.path,
    required this.name,
    required this.isDirectory,
    this.fileCount,
  });
}

class FileService {
  static const Set<String> comicExtensions = {'.zip', '.cbz'};
  static const Set<String> imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.bmp', '.gif'};

  /// Requests storage permissions on Android/devices
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 11+ (API 30+)
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;

      // Fallback for Android 10 and below
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) return true;

      // Check media images for Android 13+
      final photosStatus = await Permission.photos.request();
      return photosStatus.isGranted;
    }
    return true;
  }

  /// Picks a comic archive file (.zip, .cbz)
  Future<String?> pickComicFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'cbz'],
      dialogTitle: '만화 압축 파일 선택 (ZIP, CBZ)',
    );

    if (result != null && result.files.single.path != null) {
      return result.files.single.path;
    }
    return null;
  }

  /// Picks a comic folder
  Future<String?> pickComicDirectory() async {
    final selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '만화 이미지 폴더 선택',
    );
    return selectedDirectory;
  }

  /// Lists comic archives and image folders within a directory
  Future<List<FileItemInfo>> listFolderContents(String folderPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return [];

    final entities = await dir.list().toList();
    final items = <FileItemInfo>[];

    for (final entity in entities) {
      final name = p.basename(entity.path);
      if (name.startsWith('.') || name.contains('__MACOSX')) continue;

      if (entity is Directory) {
        items.add(FileItemInfo(
          path: entity.path,
          name: name,
          isDirectory: true,
        ));
      } else if (entity is File) {
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

    // Sort folders first, then files with natural sort
    items.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return NaturalSort.compare(a.name, b.name);
    });

    return items;
  }
}
