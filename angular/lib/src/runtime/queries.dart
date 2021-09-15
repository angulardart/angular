/// Returns the first item of [items], or `null` if the list is empty.
T? firstOrNull<T>(List<T> items) => items.isNotEmpty ? items.first : null;
