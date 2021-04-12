/// An error thrown by developer tools.
class DevToolsError extends Error {
  DevToolsError(this.message);

  /// A description of the error that occurred.
  final String message;

  @override
  String toString() => message;
}
