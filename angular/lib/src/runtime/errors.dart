/// **INTERNAL ONLY**.
library angular.src.runtime.errors;

/// Thrown by the framework when an event handler expects an incorrect type.
class InvalidHandlerError extends TypeError {
  final Type expected;
  final Type actual;
  final Object context;

  InvalidHandlerError(this.expected, this.actual, this.context);

  @override
  String toString() =>
      'Invalid event handler on $context: Expected an event of type $expected '
      'but got $actual. In previous versions of Dart it was possible to avoid '
      'some cast errors (such as List<dynamic> as List<String), but they are '
      'now runtime errors, and must be fixed.';
}
