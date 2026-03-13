
class SortUtils {
  /// Returns a list of parts for natural sorting (e.g., ["1", "2", "10"]).
  static List<dynamic> naturalSortKey(String s) {
    final regExp = RegExp(r'([0-9]+)');
    final parts = s.split(regExp);
    final matches = regExp.allMatches(s).toList();
    
    List<dynamic> result = [];
    int matchIdx = 0;
    
    for (var part in parts) {
      if (part.isNotEmpty) result.add(part.toLowerCase());
      if (matchIdx < matches.length) {
        result.add(int.parse(matches[matchIdx].group(0)!));
        matchIdx++;
      }
    }
    return result;
  }

  static int compareNatural(String a, String b) {
    if (a == b) return 0;
    final keyA = naturalSortKey(a);
    final keyB = naturalSortKey(b);
    
    final len = keyA.length < keyB.length ? keyA.length : keyB.length;
    for (int i = 0; i < len; i++) {
      final valA = keyA[i];
      final valB = keyB[i];
      
      if (valA.runtimeType != valB.runtimeType) {
        return valA.toString().compareTo(valB.toString());
      }
      
      final cmp = (valA as Comparable).compareTo(valB);
      if (cmp != 0) return cmp;
    }
    return keyA.length.compareTo(keyB.length);
  }
}
