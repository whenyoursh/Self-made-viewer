/// Utility for natural sorting of file names and hierarchical paths (e.g. '1.jpg', '2.jpg', '10.jpg', 'Vol 1/01.jpg')
class NaturalSort {
  static final RegExp _regex = RegExp(r'(\d+)|(\D+)');

  /// Compares two strings using natural numerical ordering.
  static int compare(String a, String b) {
    final aMatches = _regex.allMatches(a.toLowerCase()).map((m) => m.group(0)!).toList();
    final bMatches = _regex.allMatches(b.toLowerCase()).map((m) => m.group(0)!).toList();

    final minLength = aMatches.length < bMatches.length ? aMatches.length : bMatches.length;

    for (int i = 0; i < minLength; i++) {
      final aPart = aMatches[i];
      final bPart = bMatches[i];

      final aNum = int.tryParse(aPart);
      final bNum = int.tryParse(bPart);

      if (aNum != null && bNum != null) {
        final diff = aNum.compareTo(bNum);
        if (diff != 0) return diff;
      } else {
        final diff = aPart.compareTo(bPart);
        if (diff != 0) return diff;
      }
    }

    return aMatches.length.compareTo(bMatches.length);
  }

  /// Compares two hierarchical file paths segment by segment using natural numerical ordering.
  /// Example: 'Chapter 1/01.jpg' < 'Chapter 1/02.jpg' < 'Chapter 2/01.jpg' < 'Chapter 10/01.jpg'
  static int comparePath(String pathA, String pathB) {
    final normA = pathA.replaceAll('\\', '/');
    final normB = pathB.replaceAll('\\', '/');

    final segA = normA.split('/').where((s) => s.isNotEmpty).toList();
    final segB = normB.split('/').where((s) => s.isNotEmpty).toList();

    final minLength = segA.length < segB.length ? segA.length : segB.length;
    for (int i = 0; i < minLength; i++) {
      final cmp = compare(segA[i], segB[i]);
      if (cmp != 0) return cmp;
    }

    return segA.length.compareTo(segB.length);
  }

  /// Sorts a list of strings in-place naturally.
  static List<String> sortList(List<String> list) {
    final sorted = List<String>.from(list);
    sorted.sort(compare);
    return sorted;
  }

  /// Sorts a list of hierarchical paths in-place naturally.
  static List<String> sortPaths(List<String> paths) {
    final sorted = List<String>.from(paths);
    sorted.sort(comparePath);
    return sorted;
  }
}
