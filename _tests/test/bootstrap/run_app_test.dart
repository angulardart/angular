@JS()
@TestOn('browser')
library angular.test.bootstrap.run_app_test;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:js/js.dart';
import 'package:test/test.dart';

import 'run_app_test.template.dart' as ng;

/// A set of functional tests for the bootstrapping process.
void main() {
  ComponentRef<HelloWorldComponent> component;
  Element rootDomContainer;

  runInApp(dynamic Function() fn) {
    ApplicationRef appRef = component.injector.get(ApplicationRef);
    return appRef.run(fn);
  }

  /// Verify that the DOM of the page represents the component.
  void verifyDomAndStyles({String innerText: 'Hello World!'}) {
    expect(rootDomContainer.text, innerText);
    final h1 = rootDomContainer.querySelector('h1');
    expect(h1.getComputedStyle().height, '100px');
  }

  /// Verify the `Testability` interface is working for this application.
  ///
  /// **NOTE**: We will use the JS API, since that is how users access it.
  Future<void> verifyTestability() async {
    expect(component.injector.get(Testability), isNotNull);
    JsTestability jsTestability = getAngularTestability(
      rootDomContainer.children.first,
      false,
    );
    expect(getAllAngularTestabilities(), isNot(hasLength(0)));
    expect(jsTestability.isStable(), isTrue);
    jsTestability.whenStable(allowInterop(expectAsync1((didWork) {
      expect(didWork, isTrue);

      // TODO(matanl): As part of documenting Testability, figure this out.
      new Future(expectAsync0(() {
        verifyDomAndStyles(innerText: 'Hello Universe!');
      }));
    })));
    runInApp(() => HelloWorldComponent.doAsyncTaskAndThenRename('Universe'));
  }

  setUp(() {
    rootDomContainer = new DivElement()..id = 'test-root-dom';
    rootDomContainer.append(new Element.tag('hello-world'));
    document.body.append(rootDomContainer);
    HelloWorldComponent.name = 'World';
  });

  tearDown(() {
    rootDomContainer.remove();
    final ApplicationRef appRef = component.injector.get(ApplicationRef);
    return appRef.dispose;
  });

  test('runApp should bootstrap from a ComponentFactory', () async {
    component = await runApp(ng.HelloWorldComponentNgFactory);
    verifyDomAndStyles();
    await verifyTestability();
  });

  test('runApp should allow overriding ExceptionHandler', () async {
    component = await runApp(
      ng.HelloWorldComponentNgFactory,
      createInjector: ([parent]) {
        return new Injector.map({
          ExceptionHandler: new StubExceptionHandler(),
        }, parent);
      },
    );
    expect(StubExceptionHandler.instanceWasCreated, isTrue);
    await runInApp(() => HelloWorldComponent.doAsyncTaskThatThrows());
    expect(StubExceptionHandler.lastCaughtException, isIntentionalError);
  });

  test('runAppAsync should await a future before bootstrapping', () async {
    component = await runAppAsync(
      ng.HelloWorldComponentNgFactory,
      beforeComponentCreated: (_) {
        return new Future(() {
          HelloWorldComponent.name = 'Async World';
        });
      },
    );
    verifyDomAndStyles(innerText: 'Hello Async World!');
    await verifyTestability();
  });

  // i.e. "bootstrapStatic".
  test('runAppLegacy should bootstrap from a Type', () async {
    component = await runAppLegacy<HelloWorldComponent>(HelloWorldComponent);
    verifyDomAndStyles();
    await verifyTestability();
  });

  test('ApplicationRef should be injectable in a user-application', () async {
    component = await runAppLegacy<HelloWorldComponent>(
      HelloWorldComponent,
      createInjectorFromProviders: [ServiceThatInjectsApplicationRef],
    );
    expect(component.injector.get(ServiceThatInjectsApplicationRef), isNotNull);
  });
}

@Component(
  selector: 'hello-world',
  template: '<h1>Hello {{name}}!</h1>',
  styles: const [
    'h1 { height: 100px; }',
  ],
)
class HelloWorldComponent {
  static var name = 'World';

  static void doAsyncTaskAndThenRename(String name) {
    Timer.run(() {
      HelloWorldComponent.name = name;
    });
  }

  static void doAsyncTaskThatThrows() {
    scheduleMicrotask(() {
      throw new IntentionalError();
    });
  }
}

// This is semantically similar to the old AngularDart router.
@Injectable()
class ServiceThatInjectsApplicationRef {
  ServiceThatInjectsApplicationRef(ApplicationRef _);
}

class IntentionalError extends Error {}

final isIntentionalError = const isInstanceOf<IntentionalError>();

class StubExceptionHandler implements ExceptionHandler {
  static Object lastCaughtException;
  static bool instanceWasCreated = false;

  StubExceptionHandler() {
    instanceWasCreated = true;
  }

  @override
  void call(exception, [stackTrace, String reason]) {
    lastCaughtException = exception;
  }
}

// TODO(matanl): Refactor testability, and re-use a JS interface.

@JS()
external JsTestability getAngularTestability(Element e, bool findInAncestors);

@JS()
external List<JsTestability> getAllAngularTestabilities();

@JS()
abstract class JsTestability {
  external bool isStable();
  external void whenStable(void Function(bool didWork) fn);
}
