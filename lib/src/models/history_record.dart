import 'dart:convert';

/// Record of a recently opened comic file
class RecentBookRecord {
  final String path;
  final String title;
  final int lastReadPage;
  final int totalPages;
  final DateTime lastReadAt;
  final String? coverBase64; // Cache of first page / cover thumbnail

  RecentBookRecord({
    required this.path,
    required this.title,
    required this.lastReadPage,
    required this.totalPages,
    required this.lastReadAt,
    this.coverBase64,
  });

  double get progressPercentage =>
      totalPages > 0 ? (lastReadPage / totalPages).clamp(0.0, 1.0) : 0.0;

  RecentBookRecord copyWith({
    String? path,
    String? title,
    int? lastReadPage,
    int? totalPages,
    DateTime? lastReadAt,
    String? coverBase64,
  }) {
    return RecentBookRecord(
      path: path ?? this.path,
      title: title ?? this.title,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      totalPages: totalPages ?? this.totalPages,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      coverBase64: coverBase64 ?? this.coverBase64,
    );
  }

  Map<String, dynamic> toMap() => {
    'path': path,
    'title': title,
    'lastReadPage': lastReadPage,
    'totalPages': totalPages,
    'lastReadAt': lastReadAt.toIso8601String(),
    'coverBase64': coverBase64,
  };

  factory RecentBookRecord.fromMap(Map<String, dynamic> map) => RecentBookRecord(
    path: map['path'] ?? '',
    title: map['title'] ?? '',
    lastReadPage: map['lastReadPage'] ?? 1,
    totalPages: map['totalPages'] ?? 1,
    lastReadAt: DateTime.tryParse(map['lastReadAt'] ?? '') ?? DateTime.now(),
    coverBase64: map['coverBase64'],
  );

  String toJson() => jsonEncode(toMap());
  factory RecentBookRecord.fromJson(String source) =>
      RecentBookRecord.fromMap(jsonDecode(source));
}

/// Record of a recently accessed internal folder
class RecentFolderRecord {
  final String folderPath;
  final String folderName;
  final DateTime lastAccessedAt;

  RecentFolderRecord({
    required this.folderPath,
    required this.folderName,
    required this.lastAccessedAt,
  });

  Map<String, dynamic> toMap() => {
    'folderPath': folderPath,
    'folderName': folderName,
    'lastAccessedAt': lastAccessedAt.toIso8601String(),
  };

  factory RecentFolderRecord.fromMap(Map<String, dynamic> map) => RecentFolderRecord(
    folderPath: map['folderPath'] ?? '',
    folderName: map['folderName'] ?? '',
    lastAccessedAt: DateTime.tryParse(map['lastAccessedAt'] ?? '') ?? DateTime.now(),
  );

  String toJson() => jsonEncode(toMap());
  factory RecentFolderRecord.fromJson(String source) =>
      RecentFolderRecord.fromMap(jsonDecode(source));
}
