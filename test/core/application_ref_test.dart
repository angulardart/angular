@TestOn('browser')
library angular2.test.core.application_ref_test;

import "dart:async";

import "package:angular2/core.dart"
    show
        Injector,
        Provider,
        APP_INITIALIZER,
        Component,
        ReflectiveInjector,
        coreLoadAndBootstrap,
        PlatformRef,
        createPlatform,
        disposePlatform,
        ComponentResolver,
        ChangeDetectorRef;
import "package:angular2/src/core/application_ref.dart"
    show
        ApplicationRef_,
        ApplicationRef,
        PlatformRef,
        PLATFORM_CORE_PROVIDERS,
        APPLICATION_CORE_PROVIDERS;
import "package:angular2/src/core/console.dart" show Console;
import "package:angular2/src/core/linker/component_factory.dart"
    show ComponentFactory, ComponentRef_, ComponentRef;
import "package:angular2/src/core/linker/injector_factory.dart"
    show CodegenInjectorFactory;
import "package:angular2/src/facade/async.dart"
    show PromiseWrapper, PromiseCompleter, TimerWrapper;
import "package:angular2/src/facade/exception_handler.dart"
    show ExceptionHandler;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/testing_internal.dart";
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import "core_mocks.dart";

main() {
  group("bootstrap", () {
    PlatformRef platform;
    _ArrayLogger errorLogger;
    ComponentFactory someCompFactory;
    setUp(() {
      errorLogger = new _ArrayLogger();
      disposePlatform();
    });
    tearDown(() {
      disposePlatform();
    });
    ApplicationRef_ createApplication(List<dynamic> providers) {
      platform = createPlatform(
          ReflectiveInjector.resolveAndCreate(PLATFORM_CORE_PROVIDERS));
      someCompFactory = new _MockComponentFactory(
          new _MockComponentRef(ReflectiveInjector.resolveAndCreate([])));
      var appInjector = ReflectiveInjector.resolveAndCreate([
        APPLICATION_CORE_PROVIDERS,
        new Provider(Console, useValue: new _MockConsole()),
        new Provider(ExceptionHandler,
            useValue: new ExceptionHandler(errorLogger, false)),
        new Provider(ComponentResolver,
            useValue: new _MockComponentResolver(someCompFactory)),
        providers
      ], platform.injector);
      return appInjector.get(ApplicationRef);
    }
    group("ApplicationRef", () {
      test("should throw when reentering tick", () async {
        return inject([], () {
          var cdRef = new MockChangeDetectorRef();
          var ref = createApplication([]);
          when(cdRef.detectChanges()).thenAnswer((_) {
            ref.tick();
          });
          ref.registerChangeDetector(cdRef);
          expect(() => ref.tick(),
              throwsWith("ApplicationRef.tick is called recursively"));
          ref.unregisterChangeDetector(cdRef);
        });
      });
      group("run", () {
        test(
            "should rethrow errors even if the exceptionHandler is not rethrowing",
            () async {
          return inject([], () {
            var ref = createApplication([]);
            expect(
                () => ref.run(() {
                      throw new BaseException("Test");
                    }),
                throwsWith("Test"));
          });
        });
        test(
            'should return a promise with rejected errors '
            'even if the exceptionHandler is not rethrowing', () async {
          return inject([AsyncTestCompleter, Injector],
              (AsyncTestCompleter completer, injector) {
            var ref = createApplication([]);
            var promise = ref.run(() => PromiseWrapper.reject("Test", null));
            PromiseWrapper.catchError(promise, (e) {
              expect(e, "Test");
              completer.done();
            });
          });
        });
      });
    });
    group("coreLoadAndBootstrap", () {
      test("should wait for asynchronous app initializers", () async {
        return inject([AsyncTestCompleter, Injector],
            (AsyncTestCompleter testCompleter, Injector injector) {
          PromiseCompleter<dynamic> completer = PromiseWrapper.completer();
          var initializerDone = false;
          TimerWrapper.setTimeout(() {
            completer.resolve(true);
            initializerDone = true;
          }, 1);
          var app = createApplication([
            new Provider(APP_INITIALIZER,
                useValue: () => completer.promise, multi: true)
          ]);
          completer.promise.then((_) {
            coreLoadAndBootstrap(app.injector, MyComp).then((compRef) {
              expect(initializerDone, isTrue);
              testCompleter.done();
            });
          });
        });
      });
    });
    group("coreBootstrap", () {
      test("should throw if an APP_INITIIALIZER is not yet resolved", () async {
        return inject([Injector], (injector) {
          var app = createApplication([
            new Provider(APP_INITIALIZER,
                useValue: () => PromiseWrapper.completer().promise, multi: true)
          ]);
          expect(
              () => app.bootstrap(someCompFactory),
              throwsWith('Cannot bootstrap as there are still '
                  'asynchronous initializers running. Wait for them using '
                  'waitForAsyncInitializers().'));
        });
      });
    });
  });
}

@Component(selector: "my-comp", template: "")
class MyComp {}

class _ArrayLogger {
  List<dynamic> res = [];
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

class _MockComponentFactory extends ComponentFactory {
  ComponentRef _compRef;
  _MockComponentFactory(this._compRef) : super(null, null, null);
  ComponentRef create(Injector injector,
      [List<List<dynamic>> projectableNodes = null,
      dynamic /* String | dynamic */ rootSelectorOrNode = null]) {
    return this._compRef;
  }
}

class _MockComponentResolver implements ComponentResolver {
  ComponentFactory _compFactory;
  _MockComponentResolver(this._compFactory) {}
  Future<ComponentFactory> resolveComponent(Type type) {
    return PromiseWrapper.resolve(this._compFactory);
  }

  CodegenInjectorFactory<dynamic> createInjectorFactory(Type injectorModule,
      [List<dynamic> extraProviders]) {
    throw new UnimplementedError();
  }

  clearCache() {}
}

class _MockComponentRef extends ComponentRef_ {
  Injector _injector;
  _MockComponentRef(this._injector) : super(null, null, null);

  Injector get injector {
    return this._injector;
  }

  ChangeDetectorRef get changeDetectorRef {
    return (new MockChangeDetectorRef());
  }

  onDestroy(Function cb) {}
}

class _MockConsole implements Console {
  log(message) {}
  warn(message) {}
}
