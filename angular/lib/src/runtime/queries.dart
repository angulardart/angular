/// Function that implement parts of content and view queries at runtime.

/// Flattens a `List<List<?>>` into a `List<?>`.
List<T> flattenNodes<T>(List<List<T>> nodes) {
  final result = <T>[];
  for (var i = 0, l = nodes.length; i < l; i++) {
    final items = nodes[i];
    for (var j = 0, k = items.length; j < k; j++) {
      result.add(items[j]);
    }
  }
  return result;
}

/// Returns the first item of [items], or `null` if the list is empty.
T firstOrNull<T>(List<T> items) => items.isNotEmpty ? items.first : null;
