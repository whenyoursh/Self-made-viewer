import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/comic_session_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/page_view_widget.dart';
import '../widgets/touch_zone_overlay.dart';
import '../widgets/viewer_controls_overlay.dart';

/// Full screen comic reader optimized for Galaxy Fold
class ViewerScreen extends ConsumerStatefulWidget {
  final String comicPath;
  final int? initialPage;

  const ViewerScreen({
    super.key,
    required this.comicPath,
    this.initialPage,
  });

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(comicSessionProvider.notifier).openBook(
        widget.comicPath,
        initialPage: widget.initialPage,
      );
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(comicSessionProvider);
    final settings = ref.watch(settingsProvider);

    if (session.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.blueAccent),
              SizedBox(height: 16),
              Text(
                '만화책을 불러오는 중...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (session.errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
                const SizedBox(height: 16),
                Text(
                  session.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('돌아가기'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Pinch-to-zoom and Pan Container
          InteractiveViewer(
            transformationController: _transformController,
            minScale: 1.0,
            maxScale: 4.0,
            child: const Center(
              child: ComicPageViewWidget(),
            ),
          ),

          // Touch Zone Detector Overlay
          const TouchZoneOverlay(),

          // Minimal Floating Page Indicator (when controls are hidden)
          if (!session.areControlsVisible && settings.showPageNumber && session.hasBook)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 12,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  '${session.displayCurrentPage} / ${session.totalPages}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          // Animated Top & Bottom Controls Overlay
          if (session.areControlsVisible)
            const ViewerControlsOverlay(),
        ],
      ),
    );
  }
}
