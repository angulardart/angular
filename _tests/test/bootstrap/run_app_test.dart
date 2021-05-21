@JS()

library angular.test.bootstrap.run_app_test;

import 'dart:async';
import 'dart:html';

import 'package:js/js.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'run_app_test.template.dart' as ng;

/// A set of functional tests for the bootstrapping process.
void main() {
  ng.initReflector();

  late ComponentRef<HelloWorldComponent> component;
  late Element rootDomContainer;

  FutureOr<T> runInApp<T>(T Function() fn) {
    final appRef = component.injector.provideType<ApplicationRef>(
      ApplicationRef,
    );
    return appRef.run(fn);
  }

  /// Verify that the DOM of the page represents the component.
  void verifyDomAndStyles({String innerText = 'Hello World!'}) {
    expect(rootDomContainer.text, innerText);
    final h1 = rootDomContainer.querySelector('h1');
    expect(h1!.getComputedStyle().height, '100px');
  }

  /// Verify the `Testability` interface is working for this application.
  ///
  /// **NOTE**: We will use the JS API, since that is how users access it.
  void verifyTestability() {
    expect(component.injector.get(Testability), isNotNull);
    var jsTestability = getAngularTestability(
      rootDomContainer.children.first,
    );
    expect(getAllAngularTestabilities(), isNot(hasLength(0)));
    expect(jsTestability.isStable(), isTrue, reason: 'Expected stability');
    jsTestability.whenStable(allowInterop(expectAsync1((didWork) {
      expect(didWork, isFalse, reason: 'Immediate invocation (no work)');

      Future(expectAsync0(() {
        verifyDomAndStyles(innerText: 'Hello Universe!');
      }));
    })));
    runInApp(() => HelloWorldComponent.doAsyncTaskAndThenRename('Universe'));
  }

  setUp(() {
    rootDomContainer = DivElement()..id = 'test-root-dom';
    rootDomContainer.append(Element.tag('hello-world'));
    document.body!.append(rootDomContainer);
    HelloWorldComponent.name = 'World';
  });

  tearDown(() {
    rootDomContainer.remove();
    final appRef = component.injector.provideType<ApplicationRef>(
      ApplicationRef,
    );
    return appRef.dispose;
  });

  test('runApp should bootstrap from a ComponentFactory', () async {
    component = runApp(ng.createHelloWorldComponentFactory());
    verifyDomAndStyles();
    verifyTestability();
  });

  test('runApp should allow overriding ExceptionHandler', () async {
    component = runApp(
      ng.createHelloWorldComponentFactory(),
      createInjector: (parent) {
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
      ng.createHelloWorldComponentFactory(),
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

  test('runAppLegacyAsync should bootstrap from a Type', () async {
    component = await runAppLegacyAsync<HelloWorldComponent>(
      HelloWorldComponent,
      beforeComponentCreated: (_) {
        return Future(() {
          HelloWorldComponent.name = 'Async World';
        });
      },
    );
    verifyDomAndStyles(innerText: 'Hello Async World!');
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
      ng.createHelloWorldComponentFactory(),
      beforeComponentCreated: (injector) async {
        // Previously this would not trigger change detection, as this task
        // would not be scheduled inside of NgZone (the callback was not inside
        // of the zone).
        final ngZone = injector.provideType<NgZone>(NgZone);
        expect(ngZone.inInnerZone, isTrue);
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
  static Object? lastCaughtException;
  static bool instanceWasCreated = false;

  StubExceptionHandler() {
    instanceWasCreated = true;
  }

  @override
  void call(exception, [stackTrace, String? reason]) {
    lastCaughtException = exception;
  }
}

@JS()
external JsTestability getAngularTestability(Element e);

@JS()
external List<JsTestability> getAllAngularTestabilities();

@JS()
abstract class JsTestability {
  external bool isStable();
  external void whenStable(void Function(bool didWork) fn);
}
