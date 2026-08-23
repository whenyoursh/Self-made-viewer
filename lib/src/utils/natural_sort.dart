/// Utility for natural sorting of file names (e.g. '1.jpg', '2.jpg', '10.jpg')
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

  /// Sorts a list of strings in-place naturally.
  static List<String> sortList(List<String> list) {
    final sorted = List<String>.from(list);
    sorted.sort(compare);
    return sorted;
  }
}
