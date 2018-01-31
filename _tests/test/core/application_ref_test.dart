@Tags(const ['codegen'])
@TestOn('browser')
library angular2.test.core.application_ref_test;

import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:_tests/test_util.dart';
import 'package:angular/core.dart'
    show
        Injector,
        Provider,
        APP_INITIALIZER,
        Component,
        ReflectiveInjector,
        ChangeDetectorRef,
        Visibility;
import 'package:angular/experimental.dart';
import 'package:angular/src/core/application_ref.dart'
    show
        ApplicationRef,
        ApplicationRefImpl,
        PlatformRef,
        PlatformRefImpl,
        coreLoadAndBootstrap,
        createPlatform,
        disposePlatform;
import 'package:angular/src/core/linker/app_view_utils.dart' show AppViewUtils;
import 'package:angular/src/core/linker/component_factory.dart';
import 'package:angular/src/core/linker/component_resolver.dart';
import 'package:angular/src/facade/exception_handler.dart'
    show ExceptionHandler;
import 'package:angular/src/facade/exceptions.dart' show BaseException;

import 'application_ref_test.template.dart' as ng_generated;
import 'core_mocks.dart';

void main() {
  ng_generated.initReflector();

  group('bootstrap', () {
    PlatformRef platform;
    Logger errorLogger;
    List<String> errorLoggerList;
    ComponentFactory someCompFactory;
    setUp(() {
      errorLogger = new Logger('application_ref_test');
      errorLoggerList = [];
      errorLogger.onRecord
          .listen((LogRecord rec) => errorLoggerList.add('$rec'));
      disposePlatform();
    });
    tearDown(() {
      disposePlatform();
    });

    ApplicationRefImpl createApplication(List<dynamic> providers) {
      platform = createPlatform(ReflectiveInjector.resolveAndCreate([
        PlatformRefImpl,
        const Provider(PlatformRef, useExisting: PlatformRefImpl),
      ]));
      someCompFactory = new _MockComponentFactory(
          new _MockComponentRef(ReflectiveInjector.resolveAndCreate([])));
      var appInjector = ReflectiveInjector.resolveAndCreate([
        bootstrapLegacyModule,
        new Provider(ExceptionHandler,
            useValue: new ExceptionHandler(errorLogger)),
        // ignore: deprecated_member_use
        new Provider(ComponentResolver,
            useValue: new _MockComponentResolver(someCompFactory)),
        providers
      ], platform.injector);
      appInjector.get(AppViewUtils);
      return appInjector.get(ApplicationRef);
    }

    group('ApplicationRef', () {
      test('should throw when reentering tick', () async {
        var cdRef = new MockChangeDetectorRef();
        var ref = createApplication([]);
        when(cdRef.detectChanges()).thenAnswer((_) {
          ref.tick();
        });
        ref.registerChangeDetector(cdRef);
        expect(
          () => ref.tick(),
          throwsWith('ApplicationRef.tick is called recursively'),
        );
        ref.unregisterChangeDetector(cdRef);
      });
      test('should pass tick errors to exceptionHandler', () async {
        var ref = createApplication([]);
        await ref.waitForAsyncInitializers().whenComplete(expectAsync0(() {
          var cdRef = new MockChangeDetectorRef();
          when(cdRef.detectChanges()).thenThrow(new BaseException('Test'));
          ref.registerChangeDetector(cdRef);
          try {
            expect(errorLoggerList, isEmpty);
            try {
              ref.zone.run(() {});
            } catch (ex) {
              fail('Errors during tick should not be rethrown, '
                  'but caught the following: $ex');
            }
            expect(errorLoggerList, isNotEmpty);
          } finally {
            ref.unregisterChangeDetector(cdRef);
          }
        }));
      });
      group('run', () {
        test('should pass errors to exceptionHandler', () {
          var ref = createApplication([]);
          expect(errorLoggerList, isEmpty);
          try {
            ref.run(() {
              throw new BaseException('Test');
            });
          } catch (_) {}
          expect(errorLoggerList, isNotEmpty);
        });
        test(
            'should rethrow errors even if the exceptionHandler is not rethrowing',
            () async {
          var ref = createApplication([]);
          expect(
              () => ref.run(() {
                    throw new BaseException('Test');
                  }),
              throwsWith('Test'));
        });
      });
    });
    group('coreLoadAndBootstrap', () {
      test('should wait for asynchronous app initializers', () async {
        var completer = new Completer();
        var initializerDone = false;
        new Timer(const Duration(milliseconds: 1), () {
          completer.complete(true);
          initializerDone = true;
        });
        var app = createApplication([
          new Provider(APP_INITIALIZER,
              useValue: () => completer.future, multi: true)
        ]);
        await completer.future.then(expectAsync1((_) {
          coreLoadAndBootstrap(app.injector, MyComp).then((compRef) {
            expect(initializerDone, true);
          });
        }));
      });
    });
    group('coreBootstrap', () {
      test('should throw if an APP_INITIIALIZER is not yet resolved', () async {
        var app = createApplication([
          new Provider(APP_INITIALIZER,
              useValue: () => new Completer().future, multi: true)
        ]);
        expect(
            () => app.bootstrap(someCompFactory),
            throwsWith('Cannot bootstrap as there are still '
                'asynchronous initializers running. Wait for them using '
                'waitForAsyncInitializers().'));
      }, tags: 'known_pub_serve_failure');
    });
  });
}

@Component(
  selector: 'my-comp',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class MyComp {}

class _MockComponentFactory extends ComponentFactory {
  final ComponentRef _compRef;
  _MockComponentFactory(this._compRef) : super(null, null, null);
  ComponentRef create(Injector injector,
      [List<List<dynamic>> projectableNodes,
      dynamic /* String | dynamic */ rootSelectorOrNode]) {
    return this._compRef;
  }
}

// ignore: deprecated_member_use
class _MockComponentResolver implements ComponentResolver {
  final ComponentFactory _compFactory;
  _MockComponentResolver(this._compFactory);

  @override
  Future<ComponentFactory> resolveComponent(Type type) {
    return new Future.value(this._compFactory);
  }
}

class _MockComponentRef extends ComponentRef {
  final Injector _injector;
  _MockComponentRef(this._injector) : super(0, null, null, null);

  @override
  Element get location => new DivElement();

  @override
  Injector get injector => _injector;

  @override
  ChangeDetectorRef get changeDetectorRef => new MockChangeDetectorRef();

  @override
  void onDestroy(Function cb) {}
}
