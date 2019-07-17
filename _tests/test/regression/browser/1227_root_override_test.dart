@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular/experimental.dart';
import 'package:test/test.dart';

void main() {
  test('rootLegacyInjector should provide a working SlowComponentLoader', () {
    final appInjector = rootLegacyInjector(([parent]) {
      return Injector.empty(parent);
    });

    // Easiest way to tell is make sure its the same const instance.
    expect(
      appInjector.get(SlowComponentLoader), // ignore: deprecated_member_use
      // ignore: deprecated_member_use
      const SlowComponentLoader(ComponentLoader()),
    );
  });

  test('rootInjector should provide a throwing SlowComponentLoader', () {
    final appInjector = rootInjector(([parent]) {
      return Injector.empty(parent);
    });

    expect(
      () => appInjector
          // ignore: deprecated_member_use
          .provideType<SlowComponentLoader>(SlowComponentLoader)
          .load(ATypeThatShouldThrow, Injector.empty()),
      throwsA(isA<UnsupportedError>()),
    );
  });

  void _testOverrideExceptionHandler(Injector appInjector) {
    // Normally errors here are forwarded to the ExceptionHandler.
    //
    // In the case of #1227, we accidentally always used the default
    // ExceptionHandler (BrowserExceptionHandler), meaning the user-defined
    // handler was ignored.
    (appInjector.get(NgZone) as NgZone).runGuarded(() {
      throw _IntentionalError();
    });
    expect(
      _CustomExceptionHandler.lastCaught,
      const TypeMatcher<_IntentionalError>(),
    );
  }

  // This is relied on by internal clients until we introduce a sharding API.
  test('rootLegacyInjector should allow overriding ExceptionHandler', () {
    _testOverrideExceptionHandler(
      rootLegacyInjector(([parent]) {
        return Injector.map({
          ExceptionHandler: _CustomExceptionHandler(),
        }, parent);
      }),
    );
  });

  // This is relied on by internal clients until we introduce a sharding API.
  test('rootInjector should allow overriding ExceptionHandler', () {
    _testOverrideExceptionHandler(
      rootInjector(([parent]) {
        return Injector.map({
          ExceptionHandler: _CustomExceptionHandler(),
        }, parent);
      }),
    );
  });
}

class ATypeThatShouldThrow {}

class _IntentionalError extends Error {}

class _CustomExceptionHandler implements ExceptionHandler {
  static Object lastCaught;

  @override
  void call(exception, [stackTrace, String reason]) {
    lastCaught = exception;
  }
}
