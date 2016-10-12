class GenericTypeRequiredError<T> extends Error {
  GenericTypeRequiredError();

  @override
  String toString() {
    return 'Cannot create a new instance of ${T} without a generic type '
        'parameter. See documentation for proper use.';
  }
}
