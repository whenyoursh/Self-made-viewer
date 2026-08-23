import 'dart:typed_data';

// Web stub for dart:io File and Directory and Platform classes
class FileSystemEntity {
  static Future<bool> isDirectory(String path) async => false;
}

class File {
  final String path;
  File(this.path);
  Future<Uint8List> readAsBytes() async => Uint8List(0);
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
