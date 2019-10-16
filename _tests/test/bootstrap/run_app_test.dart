@JS()
@TestOn('browser')
library angular.test.bootstrap.run_app_test;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/security.dart';
import 'package:js/js.dart';
import 'package:test/test.dart';

import 'run_app_test.template.dart' as ng;

/// A set of functional tests for the bootstrapping process.
void main() {
  ng.initReflector();

  ComponentRef<HelloWorldComponent> component;
  Element rootDomContainer;

  runInApp(dynamic Function() fn) {
    ApplicationRef appRef = component.injector.get(ApplicationRef);
    return appRef.run(fn);
  }

  /// Verify that the DOM of the page represents the component.
  void verifyDomAndStyles({String innerText = 'Hello World!'}) {
    expect(rootDomContainer.text, innerText);
    final h1 = rootDomContainer.querySelector('h1');
    expect(h1.getComputedStyle().height, '100px');
  }

  /// Verify the `Testability` interface is working for this application.
  ///
  /// **NOTE**: We will use the JS API, since that is how users access it.
  void verifyTestability() {
    expect(component.injector.get(Testability), isNotNull);
    JsTestability jsTestability = getAngularTestability(
      rootDomContainer.children.first,
    );
    expect(getAllAngularTestabilities(), isNot(hasLength(0)));
    expect(jsTestability.isStable(), isTrue, reason: 'Expected stability');
    jsTestability.whenStable(allowInterop(expectAsync1((didWork) {
      expect(didWork, isTrue);

      // TODO(matanl): As part of documenting Testability, figure this out.
      Future(expectAsync0(() {
        verifyDomAndStyles(innerText: 'Hello Universe!');
      }));
    })));
    runInApp(() => HelloWorldComponent.doAsyncTaskAndThenRename('Universe'));
  }

  setUp(() {
    rootDomContainer = DivElement()..id = 'test-root-dom';
    rootDomContainer.append(Element.tag('hello-world'));
    document.body.append(rootDomContainer);
    HelloWorldComponent.name = 'World';
  });

  tearDown(() {
    rootDomContainer.remove();
    final ApplicationRef appRef = component.injector.get(ApplicationRef);
    return appRef.dispose;
  });

  test('runApp should bootstrap from a ComponentFactory', () async {
    component = runApp(ng.HelloWorldComponentNgFactory);
    verifyDomAndStyles();
    verifyTestability();
  });

  test('runApp should disallow different SanitizerService instances', () async {
    component = runApp(ng.HelloWorldComponentNgFactory);

    expect(
      () {
        return runApp(
          ng.HelloWorldComponentNgFactory,
          createInjector: ([parent]) {
            return Injector.map({
              SanitizationService: StubSanitizationService(),
            }, parent);
          },
        );
      },
      throwsA(predicate(
        (e) => e is AssertionError,
      )),
    );
  });

  test('runApp should allow overriding ExceptionHandler', () async {
    component = runApp(
      ng.HelloWorldComponentNgFactory,
      createInjector: ([parent]) {
        return Injector.map({
          ExceptionHandler: StubExceptionHandler(),
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
        return Future(() {
          HelloWorldComponent.name = 'Async World';
        });
      },
    );
    verifyDomAndStyles(innerText: 'Hello Async World!');
  });

  // i.e. "bootstrapStatic".
  test('runAppLegacy should bootstrap from a Type', () async {
    component = runAppLegacy<HelloWorldComponent>(HelloWorldComponent);
    verifyDomAndStyles();
    verifyTestability();
  });

  test('ApplicationRef should be injectable in a user-application', () async {
    component = runAppLegacy<HelloWorldComponent>(
      HelloWorldComponent,
      createInjectorFromProviders: [ServiceThatInjectsApplicationRef],
    );
    expect(component.injector.get(ServiceThatInjectsApplicationRef), isNotNull);
  });

  test('runApp should execute beforeComponentCreated in NgZone', () async {
    component = await runAppAsync<HelloWorldComponent>(
      ng.HelloWorldComponentNgFactory,
      beforeComponentCreated: (_) async {
        // Previously this would not trigger change detection, as this task
        // would not be scheduled inside of NgZone (the callback was not inside
        // of the zone).
        expect(NgZone.isInAngularZone(), isTrue);
        HelloWorldComponent.doAsyncTaskAndThenRename('Galaxy');
      },
    );
    await Future(() {});
    verifyDomAndStyles(innerText: 'Hello Galaxy!');
  });
}

@Component(
  selector: 'hello-world',
  template: '<h1>Hello {{name}}!</h1>',
  styles: [
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
      throw IntentionalError();
    });
  }
}

// This is semantically similar to the old AngularDart router.
@Injectable()
class ServiceThatInjectsApplicationRef {
  ServiceThatInjectsApplicationRef(ApplicationRef _);
}

class IntentionalError extends Error {}

final isIntentionalError = const TypeMatcher<IntentionalError>();

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

class StubSanitizationService implements SanitizationService {
  @override
  String sanitizeHtml(value) => '';

  @override
  String sanitizeStyle(value) => '';

  @override
  String sanitizeUrl(value) => '';

  @override
  String sanitizeResourceUrl(value) => '';
}

// TODO(matanl): Refactor testability, and re-use a JS interface.

@JS()
external JsTestability getAngularTestability(Element e);

@JS()
external List<JsTestability> getAllAngularTestabilities();

@JS()
abstract class JsTestability {
  external bool isStable();
  external void whenStable(void Function(bool didWork) fn);
}
