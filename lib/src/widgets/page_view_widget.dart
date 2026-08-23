import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/viewer_settings.dart';
import '../providers/comic_session_provider.dart';
import '../providers/settings_provider.dart';
import 'cropped_image_widget.dart';

/// Handles rendering single page or dual pages (accounting for LTR/RTL reading direction)
class ComicPageViewWidget extends ConsumerWidget {
  const ComicPageViewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(comicSessionProvider);
    final settings = ref.watch(settingsProvider);

    if (!session.hasBook) {
      return const Center(child: Text('만화책이 열려있지 않습니다.'));
    }

    final currentIndex = session.currentPageIndex;
    final total = session.totalPages;
    final isDual = settings.viewMode == ViewMode.dual;
    final isRTL = settings.readingDirection == ReadingDirection.rightToLeft;

    if (!isDual) {
      // ==================== Single Page Mode ====================
      return _buildSinglePage(ref, currentIndex, settings.marginCrop);
    } else {
      // ==================== Dual Page Mode ====================
      // Page 1 is currentIndex, Page 2 is currentIndex + 1
      final int firstPageIndex = currentIndex;
      final int? secondPageIndex = (currentIndex + 1 < total) ? currentIndex + 1 : null;

      // Determine which page goes to Left vs Right based on Reading Direction
      int? leftPageIndex;
      int? rightPageIndex;

      if (isRTL) {
        // 일본 만화 (RTL): 오른쪽 페이지가 앞(1st), 왼쪽 페이지가 뒤(2nd)
        rightPageIndex = firstPageIndex;
        leftPageIndex = secondPageIndex;
      } else {
        // 한국/서구 만화 (LTR): 왼쪽 페이지가 앞(1st), 오른쪽 페이지가 뒤(2nd)
        leftPageIndex = firstPageIndex;
        rightPageIndex = secondPageIndex;
      }

      return Row(
        children: [
          Expanded(
            child: leftPageIndex != null
                ? _buildSinglePage(ref, leftPageIndex, settings.marginCrop)
                : const SizedBox.shrink(),
          ),
          Container(width: 1, color: Colors.black54), // Subtle seam between dual pages
          Expanded(
            child: rightPageIndex != null
                ? _buildSinglePage(ref, rightPageIndex, settings.marginCrop)
                : const SizedBox.shrink(),
          ),
        ],
      );
    }
  }

  Widget _buildSinglePage(WidgetRef ref, int pageIndex, MarginCrop crop) {
    return FutureBuilder<Uint8List>(
      key: ValueKey('page_$pageIndex'),
      future: ref.read(comicSessionProvider.notifier).loadPageBytes(pageIndex),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              '${pageIndex + 1} 페이지 로드 실패',
              style: const TextStyle(color: Colors.white54),
            ),
          );
        }

        return CroppedImageWidget(
          imageBytes: snapshot.data!,
          marginCrop: crop,
        );
      },
    );
  }
}
