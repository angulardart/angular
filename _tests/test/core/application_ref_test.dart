@TestOn('browser')
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/src/core/application_ref.dart';
import 'package:angular/src/core/linker/app_view_utils.dart';
import 'package:angular/src/platform/browser/exceptions.dart';
import 'package:test/test.dart';

import 'application_ref_test.template.dart' as ng;

void main() {
  ApplicationRef appRef;

  group('dispose should ', () {
    setUp(() {
      appRef = internalCreateApplicationRef(
        NgZone(),
        Injector.map({
          ExceptionHandler: const BrowserExceptionHandler(),
        }),
      );

      // Setup global variables that need to exist before using bootstrap.
      // TODO: Move this to a common place. It's duplicated all over.
      appViewUtils = AppViewUtils(
        'appId',
        null,
        null,
      );
    });

    test('destroy bootstrapped components', () {
      final comp = appRef.bootstrap<HelloComponent>(ng.HelloComponentNgFactory);
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
      document.body.append(existing);
      final comp = appRef.bootstrap<HelloComponent>(ng.HelloComponentNgFactory);
      expect(comp.location.text, 'Hello World');
      expect(
        document.body.querySelector('hello-component'),
        same(comp.location),
      );
    });

    test('create a new element if missing from the DOM', () {
      final comp = appRef.bootstrap<HelloComponent>(ng.HelloComponentNgFactory);
      expect(comp.location.text, 'Hello World');
      expect(
        document.body.querySelector('hello-component'),
        same(comp.location),
      );
    });
  });
}

@Component(
  selector: 'hello-component',
  template: 'Hello World',
)
class HelloComponent {}
