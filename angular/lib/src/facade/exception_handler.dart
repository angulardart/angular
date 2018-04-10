import 'package:logging/logging.dart';

/// Provides a hook for centralized exception handling.
///
/// The default implementation of `ExceptionHandler` when use AngularDart is
/// actually `BrowserExceptionHandler`, which prints error message directly to
/// the console.
///
/// It's possible to instead write a _custom exception handler_:
/// ```
/// import 'package:angular/angular.dart';
///
/// @Injectable()
/// class MyExceptionHandler implements ExceptionHandler {
///   @override
///   void call(exception, [stackTrace, String reason]) {
///     // Do something with this exception, like send to an online service.
///   }
/// }
///
/// void main() {
///   bootstrap(MyApp, [
///     provide(ExceptionHandler, useClass: MyExceptionHandler),
///   ]);
/// }
/// ```
class ExceptionHandler {
  static String _longStackTrace(stackTrace) => stackTrace is Iterable
      ? stackTrace.join('\n\n-----async gap-----\n')
      : stackTrace.toString();

  /// Internal use only: Converts a caught angular exception into a string.
  static String exceptionToString(
    exception, [
    stackTrace,
    String reason,
  ]) {
    final buffer = new StringBuffer();
    buffer.writeln('EXCEPTION: $exception');
    if (stackTrace != null) {
      buffer.writeln('STACKTRACE: ');
      buffer.writeln(_longStackTrace(stackTrace));
    }
    if (reason != null) {
      buffer.writeln('REASON: $reason');
    }
    return buffer.toString();
  }

  final Logger _logger;

  const ExceptionHandler(this._logger);

  /// Handles an exception caught at runtime.
  ///
  /// Can be overridden by clients for different behavior other than printing to
  /// the console (such as backend reporting, other forms of logging, etc).
  void call(exception, [stackTrace, String reason]) {
    _logger.severe(exceptionToString(exception, stackTrace, reason));
  }
}
