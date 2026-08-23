import 'package:flutter_test/flutter_test.dart';
import 'package:fold_comic_viewer/src/models/viewer_settings.dart';

void main() {
  group('ViewerSettings Tests', () {
    test('Default settings are correctly configured for manga reading', () {
      const settings = ViewerSettings();

      expect(settings.viewMode, ViewMode.single);
      expect(settings.readingDirection, ReadingDirection.rightToLeft); // RTL default for manga
      expect(settings.leftTouchAction, TouchAction.prevPage);
      expect(settings.rightTouchAction, TouchAction.nextPage);
      expect(settings.marginCrop.hasCrop, isFalse);
    });

    test('MarginCrop hasCrop correctly detects active crop values', () {
      const emptyCrop = MarginCrop();
      expect(emptyCrop.hasCrop, isFalse);

      const topCrop = MarginCrop(top: 0.05);
      expect(topCrop.hasCrop, isTrue);

      const fullCrop = MarginCrop(top: 0.05, bottom: 0.05, left: 0.02, right: 0.02);
      expect(fullCrop.hasCrop, isTrue);
    });

    test('Serialization and deserialization preserve all properties', () {
      const original = ViewerSettings(
        viewMode: ViewMode.dual,
        readingDirection: ReadingDirection.leftToRight,
        leftTouchAction: TouchAction.nextPage,
        rightTouchAction: TouchAction.prevPage,
        marginCrop: MarginCrop(top: 0.1, bottom: 0.05, left: 0.03, right: 0.02),
        keepScreenOn: false,
        showPageNumber: true,
      );

      final json = original.toJson();
      final restored = ViewerSettings.fromJson(json);

      expect(restored.viewMode, ViewMode.dual);
      expect(restored.readingDirection, ReadingDirection.leftToRight);
      expect(restored.leftTouchAction, TouchAction.nextPage);
      expect(restored.rightTouchAction, TouchAction.prevPage);
      expect(restored.marginCrop.top, 0.1);
      expect(restored.marginCrop.bottom, 0.05);
      expect(restored.marginCrop.left, 0.03);
      expect(restored.marginCrop.right, 0.02);
      expect(restored.keepScreenOn, isFalse);
      expect(restored.showPageNumber, isTrue);
    });
  });
}
