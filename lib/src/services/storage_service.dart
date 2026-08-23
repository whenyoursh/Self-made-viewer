import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_record.dart';
import '../models/viewer_settings.dart';

/// Service for persistent storage of recent files, recent folders, and viewer settings
class StorageService {
  static const String _keyRecentBooks = 'recent_books_v1';
  static const String _keyRecentFolders = 'recent_folders_v1';
  static const String _keyViewerSettings = 'viewer_settings_v1';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // ==================== Recent Books (Top 5) ====================

  List<RecentBookRecord> getRecentBooks() {
    final rawList = _prefs.getStringList(_keyRecentBooks) ?? [];
    return rawList
        .map((json) {
          try {
            return RecentBookRecord.fromJson(json);
          } catch (_) {
            return null;
          }
        })
        .whereType<RecentBookRecord>()
        .take(5)
        .toList();
  }

  Future<void> saveRecentBook(RecentBookRecord record) async {
    final currentList = getRecentBooks();
    // Remove if already exists to move to top
    currentList.removeWhere((item) => item.path == record.path);
    // Insert at front
    currentList.insert(0, record);

    // Strictly keep top 5
    final trimmedList = currentList.take(5).toList();
    final stringList = trimmedList.map((r) => r.toJson()).toList();
    await _prefs.setStringList(_keyRecentBooks, stringList);
  }

  Future<void> removeRecentBook(String path) async {
    final currentList = getRecentBooks();
    currentList.removeWhere((item) => item.path == path);
    final stringList = currentList.map((r) => r.toJson()).toList();
    await _prefs.setStringList(_keyRecentBooks, stringList);
  }

  // ==================== Recent Folders ====================

  List<RecentFolderRecord> getRecentFolders() {
    final rawList = _prefs.getStringList(_keyRecentFolders) ?? [];
    return rawList
        .map((json) {
          try {
            return RecentFolderRecord.fromJson(json);
          } catch (_) {
            return null;
          }
        })
        .whereType<RecentFolderRecord>()
        .take(10)
        .toList();
  }

  Future<void> saveRecentFolder(RecentFolderRecord record) async {
    final currentList = getRecentFolders();
    currentList.removeWhere((item) => item.folderPath == record.folderPath);
    currentList.insert(0, record);

    final trimmedList = currentList.take(10).toList();
    final stringList = trimmedList.map((r) => r.toJson()).toList();
    await _prefs.setStringList(_keyRecentFolders, stringList);
  }

  Future<void> removeRecentFolder(String folderPath) async {
    final currentList = getRecentFolders();
    currentList.removeWhere((item) => item.folderPath == folderPath);
    final stringList = currentList.map((r) => r.toJson()).toList();
    await _prefs.setStringList(_keyRecentFolders, stringList);
  }

  // ==================== Viewer Settings ====================

  ViewerSettings getSettings() {
    final raw = _prefs.getString(_keyViewerSettings);
    if (raw == null) {
      return const ViewerSettings();
    }
    try {
      return ViewerSettings.fromJson(raw);
    } catch (_) {
      return const ViewerSettings();
    }
  }

  Future<void> saveSettings(ViewerSettings settings) async {
    await _prefs.setString(_keyViewerSettings, settings.toJson());
  }
}
