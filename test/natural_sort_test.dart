import 'package:flutter_test/flutter_test.dart';
import 'package:fold_comic_viewer/src/utils/natural_sort.dart';

void main() {
  group('NaturalSort Tests', () {
    test('Correctly sorts numbered page files in natural ascending order', () {
      final input = [
        'page_10.jpg',
        'page_1.jpg',
        'page_2.jpg',
        'page_20.jpg',
        'page_3.jpg',
        'page_100.jpg',
      ];

      final sorted = NaturalSort.sortList(input);

      expect(sorted, [
        'page_1.jpg',
        'page_2.jpg',
        'page_3.jpg',
        'page_10.jpg',
        'page_20.jpg',
        'page_100.jpg',
      ]);
    });

    test('Correctly handles mixed alphanumeric filenames', () {
      final input = ['img002.png', 'img001.png', 'img010.png', 'img003.png'];
      final sorted = NaturalSort.sortList(input);

      expect(sorted, ['img001.png', 'img002.png', 'img003.png', 'img010.png']);
    });
  });
}
