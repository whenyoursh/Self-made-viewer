import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/archive_service.dart';
import '../services/file_service.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be initialized in main');
});

final archiveServiceProvider = Provider<ArchiveService>((ref) {
  final service = ArchiveService();
  ref.onDispose(() => service.clearCache());
  return service;
});

final fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
});
