import 'dart:async';
import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/core/application_ref.dart';
import 'package:angular/src/core/linker/app_view_utils.dart';
import 'package:angular/src/runtime/dom_events.dart';

import 'application_ref_test.template.dart' as ng;

void main() {
  late ApplicationRef appRef;

  setUp(() {
    final ngZone = NgZone();

    appRef = internalCreateApplicationRef(
      ngZone,
      Injector.map({ExceptionHandler: _NullExceptionHandler()}),
    );

    // Setup global variables that need to exist before using bootstrap.
    // TODO: Move this to a common place. It's duplicated all over.
    appViewUtils = AppViewUtils(
      'appId',
      EventManager(ngZone),
    );
  });

  group('dispose should ', () {
    test('destroy bootstrapped components', () {
      final comp =
          appRef.bootstrap<HelloComponent>(ng.createHelloComponentFactory());
      final view = comp.hostView;
      expect(view.destroyed, isFalse);

      appRef.dispose();
      expect(view.destroyed, isTrue);
    });

    test('invoke dispose listeners', () {
      appRef.registerDisposeListener(expectAsync0(() {}));
      appRef.dispose();
    });

    test('cancel stream subscriptions to NgZone', () {
      // TODO: Implement once this is testable.
    });

    test('tell the platform the application was destroyed', () {
      // TODO: Implement once this is testable.
    });
  });

  group('bootstrap should', () {
    test('replace an existing element if in the DOM', () {
      final existing = Element.tag('hello-component')..text = 'Loading...';
      document.body!.append(existing);
      final comp = appRef.bootstrap(ng.createHelloComponentFactory());
      expect(comp.location.text, 'Hello World');
      expect(
        document.body!.querySelector('hello-component'),
        same(comp.location),
      );
    });

    test('create a new element if missing from the DOM', () {
      final comp = appRef.bootstrap(ng.createHelloComponentFactory());
      expect(comp.location.text, 'Hello World');
      expect(
        document.body!.querySelector('hello-component'),
        same(comp.location),
      );
    });
  });

  group('run should', () {
    test('return a synchronous value', () {
      final result = appRef.run(() => 'Hello');
      expect(result, 'Hello');
    });

    test('return an asynchronous value', () async {
      final result = appRef.run(() async => 'Hello');
      expect(await result, 'Hello');
    });

    test('return a synchronous null', () {
      final result = appRef.run(() => null);
      expect(result, isNull);
    });

    test('return a synchronous nullable value', () {
      final result = appRef.run<String?>(() => null);
      expect(result, isNull);
    });

    test('return an asynchronous null', () {
      final result = appRef.run(() async => null);
      expect(result, isInstanceOf<Future<void>>());
    });

    test('return an asynchronous nullable value', () {
      final result = appRef.run<String?>(() async => null);
      expect(result, isInstanceOf<Future<String?>>());
    });

    test('never return (threw synchronously)', () {
      FutureOr<String?> result = 'Not Initialized';
      try {
        result = appRef.run(() => throw 'Hello');
        fail('Should have thrown');
      } catch (_) {}
      expect(result, 'Not Initialized');
    });
  });
}

@Component(
  selector: 'hello-component',
  template: 'Hello World',
)
class HelloComponent {}

class _NullExceptionHandler implements ExceptionHandler {
  @override
  void call(exception, [stackTrace, String? reason]) => throw exception;
}
