import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/history_record.dart';
import '../providers/history_provider.dart';
import '../providers/storage_provider.dart';
import 'folder_browser_screen.dart';
import 'settings_screen.dart';
import 'viewer_screen.dart';

/// Main Home Screen featuring Recent 5 Books and Recent Folders
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _pickAndOpenFile(BuildContext context, WidgetRef ref) async {
    final fileService = ref.read(fileServiceProvider);

    if (!kIsWeb) {
      final hasPermission = await fileService.requestStoragePermission();
      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('저장소 접근 권한이 필요합니다.')),
          );
        }
        return;
      }
    }

    final result = await fileService.pickComic();
    if (result != null && context.mounted) {
      // Show loading spinner dialog while unpacking ZIP
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(
            child: Card(
              color: Color(0xFF1E1E2E),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.blueAccent),
                    SizedBox(height: 16),
                    Text('만화책을 분석하는 중...', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      try {
        if (result.path != null) {
          if (context.mounted) {
            Navigator.pop(context); // Close loading spinner
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ViewerScreen(comicPath: result.path!),
              ),
            );
          }
        } else if (result.bytes != null) {
          final archiveService = ref.read(archiveServiceProvider);
          final book = await archiveService.loadComicFromBytes(
            title: result.name,
            archiveBytes: result.bytes!,
            actualPath: result.path,
          );
          if (context.mounted) {
            Navigator.pop(context); // Close loading spinner
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ViewerScreen(comicBook: book),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading spinner
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('파일 열기 실패', style: TextStyle(color: Colors.white)),
                ],
              ),
              content: Text(
                '압축 파일 처리 중 오류가 발생했습니다:\n$e',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: const Text('확인', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _pickAndOpenFolder(BuildContext context, WidgetRef ref) async {
    final fileService = ref.read(fileServiceProvider);
    final hasPermission = await fileService.requestStoragePermission();
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장소 접근 권한이 필요합니다.')),
        );
      }
      return;
    }

    final folderPath = await fileService.pickComicDirectory();
    if (folderPath != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FolderBrowserScreen(folderPath: folderPath),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final recentBooks = history.recentBooks; // Max 5 items
    final recentFolders = history.recentFolders;

    return Scaffold(
      backgroundColor: const Color(0xFF12121E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.auto_stories, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text(
              'FoldComic',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '설정',
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(historyProvider.notifier).refresh(),
        color: Colors.blueAccent,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            // ==================== TOP SECTION: RECENT 5 BOOKS ====================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, size: 20, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text(
                        '최근 열람한 만화 (최대 5개)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${recentBooks.length}/5',
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (recentBooks.isEmpty)
              _buildEmptyRecentBooksCard(context, ref)
            else
              SizedBox(
                height: 230,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: recentBooks.length,
                  itemBuilder: (context, index) {
                    final book = recentBooks[index];
                    return _buildRecentBookCard(context, ref, book);
                  },
                ),
              ),

            const SizedBox(height: 24),

            // ==================== BOTTOM SECTION: RECENT FOLDERS ====================
            if (!kIsWeb) ...[
              const Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.folder_special, size: 20, color: Colors.amberAccent),
                    SizedBox(width: 8),
                    Text(
                      '최근 접근한 내장 폴더',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (recentFolders.isEmpty)
                _buildEmptyRecentFoldersCard(context, ref)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recentFolders.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (context, index) {
                    final folder = recentFolders[index];
                    return _buildRecentFolderTile(context, ref, folder);
                  },
                ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
      // Floating Action Buttons
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!kIsWeb) ...[
            FloatingActionButton.extended(
              heroTag: 'pickFolder',
              backgroundColor: const Color(0xFF2E2E3E),
              foregroundColor: Colors.amberAccent,
              onPressed: () => _pickAndOpenFolder(context, ref),
              icon: const Icon(Icons.create_new_folder),
              label: const Text('폴더 열기'),
            ),
            const SizedBox(width: 12),
          ],
          FloatingActionButton.extended(
            heroTag: 'pickFile',
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            onPressed: () => _pickAndOpenFile(context, ref),
            icon: const Icon(Icons.archive),
            label: const Text('파일 열기 (ZIP/CBZ)'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecentBooksCard(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.auto_stories_outlined, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            const Text(
              '최근 읽은 만화책이 없습니다.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () => _pickAndOpenFile(context, ref),
              icon: const Icon(Icons.file_open, size: 16),
              label: const Text('만화 파일 선택하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRecentFoldersCard(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.folder_open_outlined, size: 40, color: Colors.white24),
            const SizedBox(height: 8),
            const Text(
              '최근 접근한 폴더가 없습니다.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amberAccent,
                side: const BorderSide(color: Colors.amberAccent),
              ),
              onPressed: () => _pickAndOpenFolder(context, ref),
              icon: const Icon(Icons.folder, size: 16),
              label: const Text('내장 폴더 탐색'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookCard(BuildContext context, WidgetRef ref, RecentBookRecord book) {
    return Container(
      width: 145,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ViewerScreen(
                comicPath: book.path,
                initialPage: book.lastReadPage,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image Thumbnail
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (book.coverBase64 != null)
                    Image.memory(
                      base64Decode(book.coverBase64!),
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: const Color(0xFF2E2E3E),
                      child: const Center(
                        child: Icon(Icons.menu_book, color: Colors.white24, size: 40),
                      ),
                    ),
                  // Delete button overlay
                  Positioned(
                    top: 4,
                    right: 4,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close, size: 14, color: Colors.white70),
                        onPressed: () => ref.read(historyProvider.notifier).removeRecentBook(book.path),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Progress Bar
            LinearProgressIndicator(
              value: book.progressPercentage,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              minHeight: 4,
            ),
            // Metadata
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${book.lastReadPage} / ${book.totalPages}p',
                        style: const TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${(book.progressPercentage * 100).toInt()}%',
                        style: const TextStyle(fontSize: 10, color: Colors.white38),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFolderTile(BuildContext context, WidgetRef ref, RecentFolderRecord folder) {
    final formattedDate = DateFormat('MM.dd HH:mm').format(folder.lastAccessedAt);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: const Color(0xFF1E1E2E),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFF2E2E3E),
        child: Icon(Icons.folder, color: Colors.amberAccent),
      ),
      title: Text(
        folder.folderName,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        '${folder.folderPath}\n접근: $formattedDate',
        style: const TextStyle(color: Colors.white38, fontSize: 11),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.white38),
            onPressed: () => ref.read(historyProvider.notifier).removeRecentFolder(folder.folderPath),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FolderBrowserScreen(folderPath: folder.folderPath),
          ),
        );
      },
    );
  }
}
