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

    test('Correctly sorts hierarchical folder and file paths', () {
      final input = [
        'Chapter 10/01.jpg',
        'Chapter 1/02.jpg',
        'Chapter 2/01.jpg',
        'Chapter 1/01.jpg',
        'Chapter 2/10.jpg',
        'Chapter 1/10.jpg',
        'Chapter 2/02.jpg',
      ];

      final sorted = NaturalSort.sortPaths(input);

      expect(sorted, [
        'Chapter 1/01.jpg',
        'Chapter 1/02.jpg',
        'Chapter 1/10.jpg',
        'Chapter 2/01.jpg',
        'Chapter 2/02.jpg',
        'Chapter 2/10.jpg',
        'Chapter 10/01.jpg',
      ]);
    });

    test('Handles Windows backslashes and mixed slashes in hierarchical paths', () {
      final input = [
        r'Vol 2\01.jpg',
        r'Vol 1/02.jpg',
        r'Vol 10\01.jpg',
        r'Vol 1\01.jpg',
      ];

      final sorted = NaturalSort.sortPaths(input);

      expect(sorted, [
        r'Vol 1\01.jpg',
        r'Vol 1/02.jpg',
        r'Vol 2\01.jpg',
        r'Vol 10\01.jpg',
      ]);
    });
  });
}
