/// This operation is not allowed without specifying a generic type parameter.
class GenericTypeMissingError extends Error {
  final String? message;

  GenericTypeMissingError([this.message]);

  @override
  String toString() {
    if (message == null) {
      return 'Generic type required';
    }
    return 'Generic type required: $message';
  }
}
