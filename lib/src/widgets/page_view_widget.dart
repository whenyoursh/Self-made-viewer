import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/viewer_settings.dart';
import '../providers/comic_session_provider.dart';
import '../providers/settings_provider.dart';
import 'cropped_image_widget.dart';

/// Handles rendering single page or dual pages (accounting for LTR/RTL reading direction with 0 gap & zero flicker)
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
      return _buildSinglePage(
        ref: ref,
        pageIndex: currentIndex,
        crop: settings.marginCrop,
        alignment: Alignment.center,
      );
    } else {
      // ==================== Dual Page Mode (Seamless 0 Gap) ====================
      final int firstPageIndex = currentIndex;
      final int? secondPageIndex = (currentIndex + 1 < total) ? currentIndex + 1 : null;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left page: flush against center right edge
          Expanded(
            child: leftPageIndex != null
                ? _buildSinglePage(
                    ref: ref,
                    pageIndex: leftPageIndex,
                    crop: settings.marginCrop,
                    alignment: Alignment.centerRight,
                  )
                : const SizedBox.shrink(),
          ),
          // Right page: flush against center left edge (0 gap between them)
          Expanded(
            child: rightPageIndex != null
                ? _buildSinglePage(
                    ref: ref,
                    pageIndex: rightPageIndex,
                    crop: settings.marginCrop,
                    alignment: Alignment.centerLeft,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    }
  }

  Widget _buildSinglePage({
    required WidgetRef ref,
    required int pageIndex,
    required MarginCrop crop,
    required Alignment alignment,
  }) {
    final notifier = ref.read(comicSessionProvider.notifier);
    final cachedImage = notifier.getCachedDecodedImage(pageIndex);
    final imageFuture = cachedImage == null ? notifier.loadPageImage(pageIndex) : null;

    return CroppedImageWidget(
      key: ValueKey('page_$pageIndex'),
      initialImage: cachedImage,
      imageFuture: imageFuture,
      marginCrop: crop,
      alignment: alignment,
    );
  }
}
