import "package:angular2/src/facade/base_wrapped_exception.dart"
    show BaseWrappedException;

class _ArrayLogger {
  List res = [];
  void log(dynamic s) {
    this.res.add(s);
  }

  void logError(dynamic s) {
    this.res.add(s);
  }

  void logGroup(dynamic s) {
    this.res.add(s);
  }

  logGroupEnd() {}
}

/**
 * Provides a hook for centralized exception handling.
 *
 * The default implementation of `ExceptionHandler` prints error messages to the `Console`. To
 * intercept error handling,
 * write a custom exception handler that replaces this default as appropriate for your app.
 *
 * ### Example
 *
 * ```javascript
 *
 * class MyExceptionHandler implements ExceptionHandler {
 *   call(error, stackTrace = null, reason = null) {
 *     // do something with the exception
 *   }
 * }
 *
 * bootstrap(MyApp, [provide(ExceptionHandler, {useClass: MyExceptionHandler})])
 *
 * ```
 */
class ExceptionHandler {
  dynamic _logger;
  bool _rethrowException;
  ExceptionHandler(this._logger, [this._rethrowException = true]) {}
  static String exceptionToString(dynamic exception,
      [dynamic stackTrace = null, String reason = null]) {
    var l = new _ArrayLogger();
    var e = new ExceptionHandler(l, false);
    e.call(exception, stackTrace, reason);
    return l.res.join("\n");
  }

  void call(dynamic exception,
      [dynamic stackTrace = null, String reason = null]) {
    var originalException = this._findOriginalException(exception);
    var originalStack = this._findOriginalStack(exception);
    var context = this._findContext(exception);
    this
        ._logger
        .logGroup('''EXCEPTION: ${ this . _extractMessage ( exception )}''');
    if (stackTrace != null && originalStack == null) {
      this._logger.logError("STACKTRACE:");
      this._logger.logError(this._longStackTrace(stackTrace));
    }
    if (reason != null) {
      this._logger.logError('''REASON: ${ reason}''');
    }
    if (originalException != null) {
      this._logger.logError(
          '''ORIGINAL EXCEPTION: ${ this . _extractMessage ( originalException )}''');
    }
    if (originalStack != null) {
      this._logger.logError("ORIGINAL STACKTRACE:");
      this._logger.logError(this._longStackTrace(originalStack));
    }
    if (context != null) {
      this._logger.logError("ERROR CONTEXT:");
      this._logger.logError(context);
    }
    this._logger.logGroupEnd();
    // We rethrow exceptions, so operations like 'bootstrap' will result in an error

    // when an exception happens. If we do not rethrow, bootstrap will always succeed.
    if (this._rethrowException) throw exception;
  }

  String _extractMessage(dynamic exception) {
    return exception is BaseWrappedException
        ? exception.wrapperMessage
        : exception.toString();
  }

  dynamic _longStackTrace(dynamic stackTrace) {
    return stackTrace is Iterable
        ? ((stackTrace as List<dynamic>)).join("\n\n-----async gap-----\n")
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
