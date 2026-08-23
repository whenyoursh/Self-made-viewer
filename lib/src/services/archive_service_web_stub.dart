// Web stub for dart:io File and Directory and Platform classes
class FileSystemEntity {
  static Future<bool> isDirectory(String path) async => false;
}

class File {
  final String path;
  File(this.path);
  Future<List<int>> readAsBytes() async => [];
}

class Directory {
  final String path;
  Directory(this.path);
  Stream<dynamic> list() => const Stream.empty();
}

class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isWindows => false;
}
