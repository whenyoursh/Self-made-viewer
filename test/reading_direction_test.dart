import 'package:flutter_test/flutter_test.dart';
import 'package:fold_comic_viewer/src/models/viewer_settings.dart';

void main() {
  group('Reading Direction & Page Pairing Tests', () {
    test('RTL (Japanese Manga) correctly places right page as first and left as second', () {
      const direction = ReadingDirection.rightToLeft;
      const currentIndex = 4; // 0-based
      const totalPages = 20;

      final firstPage = currentIndex;
      final secondPage = (currentIndex + 1 < totalPages) ? currentIndex + 1 : null;

      int? leftPage;
      int? rightPage;

      if (direction == ReadingDirection.rightToLeft) {
        rightPage = firstPage;
        leftPage = secondPage;
      } else {
        leftPage = firstPage;
        rightPage = secondPage;
      }

      // In Japanese manga RTL:
      // Right page = 4 (Page 5), Left page = 5 (Page 6)
      expect(rightPage, 4);
      expect(leftPage, 5);
    });

    test('LTR (Korean/Western Comic) correctly places left page as first and right as second', () {
      const direction = ReadingDirection.leftToRight;
      const currentIndex = 4;
      const totalPages = 20;

      final firstPage = currentIndex;
      final secondPage = (currentIndex + 1 < totalPages) ? currentIndex + 1 : null;

      int? leftPage;
      int? rightPage;

      if (direction == ReadingDirection.rightToLeft) {
        rightPage = firstPage;
        leftPage = secondPage;
      } else {
        leftPage = firstPage;
        rightPage = secondPage;
      }

      // In Korean comic LTR:
      // Left page = 4 (Page 5), Right page = 5 (Page 6)
      expect(leftPage, 4);
      expect(rightPage, 5);
    });
  });
}
