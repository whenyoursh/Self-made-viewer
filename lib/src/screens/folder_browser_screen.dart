import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../providers/history_provider.dart';
import '../providers/storage_provider.dart';
import '../services/file_service.dart';
import 'viewer_screen.dart';

/// Screen for browsing internal folder contents (subfolders and comic files)
class FolderBrowserScreen extends ConsumerStatefulWidget {
  final String folderPath;

  const FolderBrowserScreen({super.key, required this.folderPath});

  @override
  ConsumerState<FolderBrowserScreen> createState() => _FolderBrowserScreenState();
}

class _FolderBrowserScreenState extends ConsumerState<FolderBrowserScreen> {
  late String _currentPath;
  List<FileItemInfo> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.folderPath;
    _loadContents();
  }

  Future<void> _loadContents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fileService = ref.read(fileServiceProvider);
      final items = await fileService.listFolderContents(_currentPath);
      // Record this folder access in history
      ref.read(historyProvider.notifier).recordFolderAccessed(_currentPath);

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '폴더를 열 수 없습니다: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSubfolder(String path) {
    setState(() {
      _currentPath = path;
    });
    _loadContents();
  }

  void _openInViewer(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewerScreen(comicPath: path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final folderName = p.basename(_currentPath);

    return Scaffold(
      backgroundColor: const Color(0xFF12121E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              folderName.isEmpty ? '내장 폴더' : folderName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _currentPath,
              style: const TextStyle(fontSize: 11, color: Colors.white54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // If this directory is an image folder itself, allow opening directly as a comic
          IconButton(
            tooltip: '이 폴더를 만화로 바로 열기',
            icon: const Icon(Icons.auto_stories, color: Colors.blueAccent),
            onPressed: () => _openInViewer(_currentPath),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.folder_open, size: 64, color: Colors.white24),
                          const SizedBox(height: 16),
                          const Text('폴더 내에 만화 파일(ZIP, CBZ)이나 하위 폴더가 없습니다.',
                              style: TextStyle(color: Colors.white54)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _openInViewer(_currentPath),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('현재 폴더의 이미지들을 만화로 보기'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        if (item.isDirectory) {
                          return ListTile(
                            leading: const Icon(Icons.folder, color: Colors.amber, size: 32),
                            title: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            subtitle: Text(item.path, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                            onTap: () => _navigateToSubfolder(item.path),
                          );
                        } else {
                          return ListTile(
                            leading: const Icon(Icons.archive, color: Colors.blueAccent, size: 32),
                            title: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            subtitle: const Text('압축 만화 파일', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                            trailing: const Icon(Icons.play_arrow, color: Colors.blueAccent),
                            onTap: () => _openInViewer(item.path),
                          );
                        }
                      },
                    ),
    );
  }
}
