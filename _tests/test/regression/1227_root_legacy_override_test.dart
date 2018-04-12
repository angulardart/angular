@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular/experimental.dart';
import 'package:test/test.dart';

void main() {
  // This is relied on by internal clients until we introduce a sharding API.
  test('rootLegacyInjector should allow overriding ExceptionHandler', () {
    final appInjector = rootLegacyInjector(([parent]) {
      return new Injector.map({
        ExceptionHandler: new _CustomExceptionHandler(),
      }, parent);
    });

    // Normally errors here are forwarded to the ExceptionHandler.
    //
    // In the case of #1227, we accidentally always used the default
    // ExceptionHandler (BrowserExceptionHandler), meaning the user-defined
    // handler was ignored.
    (appInjector.get(NgZone) as NgZone).runGuarded(() {
      throw new _IntentionalError();
    });
    expect(
      _CustomExceptionHandler.lastCaught,
      const isInstanceOf<_IntentionalError>(),
    );
  });
}

class _IntentionalError extends Error {}

class _CustomExceptionHandler implements ExceptionHandler {
  static Object lastCaught;

  @override
  void call(exception, [stackTrace, String reason]) {
    lastCaught = exception;
  }
}
