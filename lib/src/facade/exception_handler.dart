import 'package:logging/logging.dart';
import 'package:angular2/src/facade/base_wrapped_exception.dart'
    show BaseWrappedException;

/// Provides a hook for centralized exception handling.
///
/// The default implementation of `ExceptionHandler` prints error messages to the `Console`. To
/// intercept error handling,
/// write a custom exception handler that replaces this default as appropriate for your app.
///
/// ### Example
///
/// ```javascript
///
/// class MyExceptionHandler implements ExceptionHandler {
///   call(error, stackTrace = null, reason = null) {
///     // do something with the exception
///   }
/// }
///
/// bootstrap(MyApp, [provide(ExceptionHandler, {useClass: MyExceptionHandler})])
///
/// ```
class ExceptionHandler {
  Logger _logger;
  bool _rethrowException;

  ExceptionHandler(this._logger, [this._rethrowException = true]);

  static String exceptionToString(dynamic exception,
      [dynamic stackTrace = null, String reason = null]) {
    var l = <String>[];
    var logger = new Logger('');
    logger.onRecord.listen((LogRecord rec) {
      l.add(rec.toString());
    });
    var e = new ExceptionHandler(logger, false);
    e.call(exception, stackTrace, reason);
    return l.join('\n');
  }

  void call(dynamic exception,
      [dynamic stackTrace = null, String reason = null]) {
    var originalException = this._findOriginalException(exception);
    var originalStack = this._findOriginalStack(exception);
    var context = this._findContext(exception);
    _logger.info('EXCEPTION: ${ this . _extractMessage ( exception )}');
    if (stackTrace != null && originalStack == null) {
      _logger.severe('STACKTRACE:');
      _logger.severe(this._longStackTrace(stackTrace));
    }
    if (reason != null) {
      _logger.severe('''REASON: ${ reason}''');
    }
    if (originalException != null) {
      _logger
          .severe('ORIGINAL EXCEPTION: ${_extractMessage(originalException)}');
    }
    if (originalStack != null) {
      _logger.severe('ORIGINAL STACKTRACE:');
      _logger.severe(this._longStackTrace(originalStack));
    }
    if (context != null) {
      _logger.severe('ERROR CONTEXT:');
      _logger.severe(context);
    }
    // We rethrow exceptions, so operations like 'bootstrap' will result in
    // an error when an exception happens. If we do not rethrow, bootstrap will
    // always succeed.
    if (_rethrowException) throw exception;
  }

  String _extractMessage(dynamic exception) {
    return exception is BaseWrappedException
        ? exception.wrapperMessage
        : exception.toString();
  }

  dynamic _longStackTrace(dynamic stackTrace) {
    return stackTrace is Iterable
        ? ((stackTrace as List<dynamic>)).join('\n\n-----async gap-----\n')
        : stackTrace.toString();
  }

  dynamic _findContext(dynamic exception) {
    try {
      if (!(exception is BaseWrappedException)) return null;
      return exception.context ??
          this._findContext(exception.originalException);
    } catch (e) {
      // exception.context can throw an exception. if it happens, we ignore the context.
      return null;
    }
  }

  dynamic _findOriginalException(dynamic exception) {
    if (!(exception is BaseWrappedException)) return null;
    var e = exception.originalException;
    while (e is BaseWrappedException && e.originalException != null) {
      e = e.originalException;
    }
    return e;
  }

  dynamic _findOriginalStack(dynamic exception) {
    if (!(exception is BaseWrappedException)) return null;
    var e = exception;
    var stack = exception.originalStack;
    while (e is BaseWrappedException && e.originalException != null) {
      e = e.originalException;
      if (e is BaseWrappedException && e.originalException != null) {
        stack = e.originalStack;
      }
    }
    return stack;
  }
}
