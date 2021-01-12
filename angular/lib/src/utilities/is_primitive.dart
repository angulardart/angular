extension IsPrimitive on Object? {
  /// Returns whether this object is considered a "primitive" (in JavaScript).
  ///
  /// In short, this is true for [num], [bool], [String], and [Null].
  bool get isPrimitive {
    return this is num || this is bool || this == null || this is String;
  }
}
