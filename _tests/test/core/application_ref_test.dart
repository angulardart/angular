@TestOn('browser')
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/src/core/application_ref.dart';
import 'package:angular/src/core/linker/app_view_utils.dart';
import 'package:angular/src/core/render/api.dart';
import 'package:angular/src/platform/browser/exceptions.dart';
import 'package:angular/src/platform/dom/shared_styles_host.dart';
import 'package:test/test.dart';

import 'application_ref_test.template.dart' as ng;

void main() {
  ApplicationRefImpl appRef;

  group('dispose should ', () {
    setUp(() {
      appRef = new ApplicationRefImpl(
        new PlatformRefImpl(),
        new NgZone(enableLongStackTrace: true),
        new Injector.map({
          ExceptionHandler: const BrowserExceptionHandler(),
        }),
      );

      // Setup global variables that need to exist before using bootstrap.
      // TODO: Move this to a common place. It's duplicated all over.
      appViewUtils = new AppViewUtils(
        'appId',
        null,
        null,
      );
      sharedStylesHost ??= new DomSharedStylesHost(document);
    });

    test('destroy bootstrapped components', () {
      final comp = appRef.bootstrap<NullComponent>(ng.NullComponentNgFactory);
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
      // TODO.
    });

    test('create a new element if missing from the DOM', () {
      // TODO.
    });
  });
}

@Component(
  selector: 'null-component',
  template: '',
)
class NullComponent {}
