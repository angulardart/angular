import 'dart:html';

import 'package:angular/core.dart';

@Injectable()
class BrowserExceptionHandler implements ExceptionHandler {
  const BrowserExceptionHandler();

  // Will be replaced by `handle`.
  @override
  void call(error, [stack, String reason]) => handle(error, stack, reason);

  void handle(exception, [stack, String reason]) {
    window.console.error(ExceptionHandler.exceptionToString(
      exception,
      stack,
      reason,
    ));
  }
}
