import 'dart:async';

import 'package:angular2/src/core/change_detection/change_detector_ref.dart';
import 'package:angular2/src/core/di.dart';
import 'package:angular2/src/core/linker/app_view_utils.dart';
import 'package:angular2/src/core/linker/component_factory.dart'
    show ComponentRef, ComponentFactory;
import 'package:angular2/src/core/linker/component_resolver.dart';
import 'package:angular2/src/core/testability/testability.dart'
    show TestabilityRegistry, Testability;
import 'package:angular2/src/core/zone/ng_zone.dart' show NgZone, NgZoneError;
import 'package:angular2/src/facade/exceptions.dart'
    show BaseException, ExceptionHandler;
import 'package:angular2/src/facade/lang.dart' show assertionsEnabled;

import 'application_tokens.dart' show PLATFORM_INITIALIZER, APP_INITIALIZER;
import 'profile/profile.dart' show wtfLeave, wtfCreateScope, WtfScopeFn;

/// Create an Angular zone.
NgZone createNgZone() => new NgZone(enableLongStackTrace: assertionsEnabled());

PlatformRefImpl _platform;
bool _inPlatformCreate = false;

/// Creates a platform.
/// Platforms have to be eagerly created via this function.
PlatformRefImpl createPlatform(Injector injector) {
  assert(() {
    if (_inPlatformCreate) {
      throw new BaseException('Already creating a platform...');
    }
    if (_platform != null && !_platform.disposed) {
      throw new BaseException('There can be only one platform. Destroy the '
          'previous one to create a new one.');
    }
    return true;
  });
  _inPlatformCreate = true;
  try {
    _platform = injector.get(PlatformRef);
    _platform.init(injector);
  } finally {
    _inPlatformCreate = false;
  }
  return _platform;
}

/// Dispose the existing platform.
void disposePlatform() {
  if (_platform != null && !_platform.disposed) {
    _platform.dispose();
  }
}

/// Returns the current platform.
PlatformRef getPlatform() =>
    _platform != null && !_platform.disposed ? _platform : null;

/// Shortcut for ApplicationRef.bootstrap.
///
/// Requires a platform the be created first.
ComponentRef coreBootstrap(
    Injector injector, ComponentFactory componentFactory) {
  appViewUtils = injector.get(AppViewUtils);
  ApplicationRef appRef = injector.get(ApplicationRef);
  return appRef.bootstrap(componentFactory);
}

/// Resolves the componentFactory for the given component,
/// waits for asynchronous initializers and bootstraps the component.
///
/// Requires a platform the be created first.
Future<ComponentRef> coreLoadAndBootstrap(
    Injector injector, Type componentType) async {
  appViewUtils = injector.get(AppViewUtils);
  ApplicationRef appRef = injector.get(ApplicationRef);
  return await appRef.run(() async {
    ComponentResolver componentResolver = injector.get(ComponentResolver);
    ComponentFactory factory =
        await componentResolver.resolveComponent(componentType);
    await appRef.waitForAsyncInitializers();
    return appRef.bootstrap(factory);
  });
}

/// The Angular platform is the entry point for Angular on a web page. Each page
/// has exactly one platform, and services (such as reflection) which are common
/// to every Angular application running on the page are bound in its scope.
///
/// A page's platform is initialized implicitly when `bootstrap()` is called, or
/// explicitly by calling `createPlatform()`.
abstract class PlatformRef {
  /// Register a listener to be called when the platform is disposed.
  void registerDisposeListener(void dispose());

  /// Retrieve the platform [Injector], which is the parent injector for
  /// every Angular application on the page and provides singleton providers.
  Injector get injector;

  /// Destroy the Angular platform and all Angular applications on the page.
  void dispose();

  bool get disposed;
}

@Injectable()
class PlatformRefImpl extends PlatformRef {
  final List<ApplicationRef> _applications = [];
  final List<Function> _disposeListeners = [];
  bool _disposed = false;
  Injector _injector;

  /// Given an injector, gets platform initializers to initialize at bootstrap.
  void init(Injector injector) {
    assert(() {
      if (!_inPlatformCreate) {
        throw new BaseException(
            'Platforms have to be initialized via `createPlatform`!');
      }
      return true;
    });
    _injector = injector;

    List<Function> initializers =
        (injector.get(PLATFORM_INITIALIZER, null) as List<Function>);
    initializers?.forEach((init) => init());
  }

  void registerDisposeListener(void dispose()) {
    _disposeListeners.add(dispose);
  }

  Injector get injector => _injector;

  bool get disposed => _disposed;

  void addApplication(ApplicationRef appRef) {
    _applications.add(appRef);
  }

  void dispose() {
    _applications.forEach((app) => app.dispose());
    _applications.clear();
    _disposeListeners.forEach((dispose) => dispose());
    _disposeListeners.clear();
    _disposed = true;
  }

  void _applicationDisposed(ApplicationRef app) {
    _applications.remove(app);
  }
}

/// A reference to an Angular application running on a page.
///
/// For more about Angular applications, see the documentation for [bootstrap].
abstract class ApplicationRef {
  /// Register a listener to be called each time `bootstrap()` is called to bootstrap
  /// a new root component.
  void registerBootstrapListener(void listener(ComponentRef ref));

  /// Register a listener to be called when the application is disposed.
  void registerDisposeListener(void dispose());

  /// Returns a promise that resolves when all asynchronous application
  /// initializers are done.
  Future<dynamic> waitForAsyncInitializers();

  /// Runs the given [callback] in the zone and returns the result of the call.
  ///
  /// Exceptions will be forwarded to the ExceptionHandler and rethrown.
  run(callback());

  /// Bootstrap a new component at the root level of the application.
  ///
  /// ### Bootstrap process
  ///
  /// When bootstrapping a new root component into an application, Angular mounts the
  /// specified application component onto DOM elements identified by the [componentType]'s
  /// selector and kicks off automatic change detection to finish initializing the component.
  ///
  /// ### Example
  ///     {@example core/ts/platform/platform.ts region='longform'}
  ///
  ComponentRef bootstrap(ComponentFactory componentFactory);

  /// Retrieve the application [Injector].
  Injector get injector;

  /// Retrieve the application [NgZone].
  NgZone get zone;

  /// Dispose of this application and all of its components.
  void dispose();

  /// Invoke this method to explicitly process change detection and its
  /// side-effects.
  ///
  /// In development mode, `tick()` also performs a second change detection
  /// cycle to ensure that no further changes are detected. If additional
  /// changes are picked up during this second cycle, bindings in the app have
  /// side-effects that cannot be resolved in a single change detection pass.
  /// In this case, Angular throws an error, since an Angular application can
  /// only have one change detection pass during which all change detection
  /// must complete.
  void tick();

  /// Get a list of component types registered to this application.
  List<Type> get componentTypes;

  /// Get a list of component factories registered to this application.
  List<ComponentFactory> get componentFactories;
}

@Injectable()
class ApplicationRefImpl extends ApplicationRef {
  final PlatformRefImpl _platform;
  final NgZone _zone;
  final Injector _injector;
  static WtfScopeFn _tickScope = wtfCreateScope('ApplicationRef#tick()');
  final List<Function> _bootstrapListeners = [];
  final List<Function> _disposeListeners = [];
  final List<ComponentRef> _rootComponents = [];
  final List<ComponentFactory> _rootComponentFactories = [];
  final List<ChangeDetectorRef> _changeDetectorRefs = [];
  bool _runningTick = false;
  bool _enforceNoNewChanges = false;
  ExceptionHandler _exceptionHandler;
  Future<dynamic> _asyncInitDonePromise;
  bool _asyncInitDone;

  ApplicationRefImpl(this._platform, this._zone, this._injector) {
    NgZone zone = _injector.get(NgZone);
    _enforceNoNewChanges = assertionsEnabled();
    zone.run(() {
      _exceptionHandler = _injector.get(ExceptionHandler);
    });
    _asyncInitDonePromise = this.run(() {
      List<Function> initializers =
          _injector.get(APP_INITIALIZER, null) as List<Function>;
      var asyncInitResults = <Future>[];
      var asyncInitDonePromise;
      if (initializers != null) {
        int initializerCount = initializers.length;
        for (var i = 0; i < initializerCount; i++) {
          var initResult = initializers[i]();
          if (initResult is Future) {
            asyncInitResults.add(initResult);
          }
        }
      }
      if (asyncInitResults.length > 0) {
        asyncInitDonePromise =
            Future.wait(asyncInitResults).then((_) => _asyncInitDone = true);
        _asyncInitDone = false;
      } else {
        _asyncInitDone = true;
        asyncInitDonePromise = new Future.value(true);
      }
      return asyncInitDonePromise;
    });
    _zone.onError.listen((NgZoneError error) {
      _exceptionHandler.call(error.error, error.stackTrace);
    });
    _zone.onMicrotaskEmpty.listen((_) {
      _zone.run(() {
        tick();
      });
    });
  }
  void registerBootstrapListener(void listener(ComponentRef ref)) {
    _bootstrapListeners.add(listener);
  }

  void registerDisposeListener(void dispose()) {
    _disposeListeners.add(dispose);
  }

  void registerChangeDetector(ChangeDetectorRef changeDetector) {
    _changeDetectorRefs.add(changeDetector);
  }

  void unregisterChangeDetector(ChangeDetectorRef changeDetector) {
    _changeDetectorRefs.remove(changeDetector);
  }

  Future<dynamic> waitForAsyncInitializers() => _asyncInitDonePromise;

  @override
  // There is no current way to express the valid results of this call.
  // The real solution here is to remove supports for returning anything.
  // i.e. just void run(void callback()) { ... }
  /*Future<R>|R|Null*/ run(callback()) {
    // TODO(matanl): Remove support for futures inside of appRef.run.
    var zone = injector.get(NgZone);
    var result;
    // Note: Don't use zone.runGuarded as we want to know about the thrown
    // exception!
    //
    // Note: the completer needs to be created outside of `zone.run` as Dart
    // swallows rejected promises via the onError callback of the promise.
    var completer = new Completer();
    zone.run(() {
      try {
        result = callback();
        if (result is Future) {
          result.then((ref) {
            completer.complete(ref);
          }, onError: (err, stackTrace) {
            completer.completeError(err, stackTrace);
            _exceptionHandler.call(err, stackTrace);
          });
        }
      } catch (e, e_stack) {
        _exceptionHandler.call(e, e_stack);
        rethrow;
      }
    });
    return result is Future ? completer.future : result;
  }

  ComponentRef bootstrap(ComponentFactory componentFactory) {
    assert(() {
      if (!_asyncInitDone) {
        throw new BaseException(
            'Cannot bootstrap as there are still asynchronous initializers '
            'running. Wait for them using waitForAsyncInitializers().');
      }
      return true;
    });

    return run(() {
      _rootComponentFactories.add(componentFactory);
      var compRef =
          componentFactory.create(_injector, [], componentFactory.selector);
      compRef.onDestroy(() {
        _unloadComponent(compRef);
      });
      var testability = compRef.injector.get(Testability, null);
      if (testability != null) {
        compRef.injector
            .get(TestabilityRegistry)
            .registerApplication(compRef.location.nativeElement, testability);
      }
      _loadComponent(compRef);
      return compRef;
    });
  }

  void _loadComponent(ComponentRef componentRef) {
    _changeDetectorRefs.add(componentRef.changeDetectorRef);
    tick();
    _rootComponents.add(componentRef);
    _bootstrapListeners.forEach((listener) => listener(componentRef));
  }

  void _unloadComponent(ComponentRef componentRef) {
    if (!_rootComponents.contains(componentRef)) {
      return;
    }
    unregisterChangeDetector(componentRef.changeDetectorRef);
    _rootComponents.remove(componentRef);
  }

  @override
  Injector get injector => _injector;

  @override
  NgZone get zone => _zone;

  @override
  void tick() {
    AppViewUtils.resetChangeDetection();
    if (_runningTick) {
      throw new BaseException('ApplicationRef.tick is called recursively');
    }
    var s = ApplicationRefImpl._tickScope();
    try {
      _runningTick = true;
      int changeDetectorCount = _changeDetectorRefs.length;
      for (int c = 0; c < changeDetectorCount; c++) {
        _changeDetectorRefs[c].detectChanges();
      }
      if (_enforceNoNewChanges) {
        for (int c = 0; c < changeDetectorCount; c++) {
          _changeDetectorRefs[c].checkNoChanges();
        }
      }
    } finally {
      _runningTick = false;
      wtfLeave(s);
    }
  }

  @override
  void dispose() {
    _rootComponents.forEach((ref) => ref.destroy());
    _disposeListeners.forEach((dispose) => dispose());
    _disposeListeners.clear();
    _platform._applicationDisposed(this);
  }

  @override
  List<Type> get componentTypes =>
      _rootComponentFactories.map((factory) => factory.componentType).toList();

  @override
  List<ComponentFactory> get componentFactories => _rootComponentFactories;
}

const PLATFORM_CORE_PROVIDERS = const [
  PlatformRefImpl,
  const Provider(PlatformRef, useExisting: PlatformRefImpl)
];

const APPLICATION_CORE_PROVIDERS = const [
  const Provider(NgZone, useFactory: createNgZone, deps: const []),
  ApplicationRefImpl,
  const Provider(ApplicationRef, useExisting: ApplicationRefImpl)
];
