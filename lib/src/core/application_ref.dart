import "dart:async";

import "package:angular2/src/core/change_detection/change_detector_ref.dart"
    show ChangeDetectorRef;
import "package:angular2/src/core/console.dart" show Console;
import "package:angular2/src/core/di.dart" show Provider, Injector, Injectable;
import "package:angular2/src/core/linker/view_utils.dart" show ViewUtils;
import "package:angular2/src/core/linker/component_factory.dart"
    show ComponentRef;
import "package:angular2/src/core/linker/component_factory.dart"
    show ComponentFactory;
import "package:angular2/src/core/linker/component_resolver.dart"
    show ComponentResolver;
import "package:angular2/src/core/testability/testability.dart"
    show TestabilityRegistry, Testability;
import "package:angular2/src/core/zone/ng_zone.dart" show NgZone, NgZoneError;
import "package:angular2/src/facade/async.dart"
    show PromiseWrapper, ObservableWrapper;
import "package:angular2/src/facade/collection.dart" show ListWrapper;
import "package:angular2/src/facade/exceptions.dart"
    show BaseException, ExceptionHandler;
import "package:angular2/src/facade/lang.dart"
    show isBlank, isPresent, assertionsEnabled, isPromise;

import "application_tokens.dart" show PLATFORM_INITIALIZER, APP_INITIALIZER;
import "profile/profile.dart" show wtfLeave, wtfCreateScope, WtfScopeFn;

/**
 * Create an Angular zone.
 */
NgZone createNgZone() {
  return new NgZone(enableLongStackTrace: assertionsEnabled());
}

PlatformRef_ _platform;
bool _inPlatformCreate = false;
/**
 * Creates a platform.
 * Platforms have to be eagerly created via this function.
 */
PlatformRef_ createPlatform(Injector injector) {
  if (_inPlatformCreate) {
    throw new BaseException("Already creating a platform...");
  }
  if (_platform != null && !_platform.disposed) {
    throw new BaseException('There can be only one platform. Destroy the '
        'previous one to create a new one.');
  }
  _inPlatformCreate = true;
  try {
    _platform = injector.get(PlatformRef);
    _platform.init(injector);
  } finally {
    _inPlatformCreate = false;
  }
  return _platform;
}

/**
 * Checks that there currently is a platform
 * which contains the given token as a provider.
 */
PlatformRef assertPlatform(dynamic requiredToken) {
  var platform = getPlatform();
  if (isBlank(platform)) {
    throw new BaseException("Not platform exists!");
  }
  if (isPresent(platform) &&
      isBlank(platform.injector.get(requiredToken, null))) {
    throw new BaseException(
        "A platform with a different configuration has been created. Please destroy it first.");
  }
  return platform;
}

/**
 * Dispose the existing platform.
 */
void disposePlatform() {
  if (isPresent(_platform) && !_platform.disposed) {
    _platform.dispose();
  }
}

/**
 * Returns the current platform.
 */
PlatformRef getPlatform() {
  return isPresent(_platform) && !_platform.disposed ? _platform : null;
}

/**
 * Shortcut for ApplicationRef.bootstrap.
 * Requires a platform the be created first.
 */
ComponentRef coreBootstrap(
    Injector injector, ComponentFactory componentFactory) {
  ApplicationRef appRef = injector.get(ApplicationRef);
  return appRef.bootstrap(componentFactory);
}

/**
 * Resolves the componentFactory for the given component,
 * waits for asynchronous initializers and bootstraps the component.
 * Requires a platform the be created first.
 */
Future<ComponentRef> coreLoadAndBootstrap(
    Injector injector, Type componentType) async {
  ApplicationRef appRef = injector.get(ApplicationRef);
  return await appRef.run(() async {
    ComponentResolver componentResolver = injector.get(ComponentResolver);
    ComponentFactory factory =
        await componentResolver.resolveComponent(componentType);
    appRef.waitForAsyncInitializers();
    return appRef.bootstrap(factory);
  });
}

/**
 * The Angular platform is the entry point for Angular on a web page. Each page
 * has exactly one platform, and services (such as reflection) which are common
 * to every Angular application running on the page are bound in its scope.
 *
 * A page's platform is initialized implicitly when [bootstrap]() is called, or
 * explicitly by calling [createPlatform]().
 */
abstract class PlatformRef {
  /**
   * Register a listener to be called when the platform is disposed.
   */
  void registerDisposeListener(void dispose());
  /**
   * Retrieve the platform [Injector], which is the parent injector for
   * every Angular application on the page and provides singleton providers.
   */
  Injector get injector;

  /**
   * Destroy the Angular platform and all Angular applications on the page.
   */
  void dispose();
  bool get disposed;
}

@Injectable()
class PlatformRef_ extends PlatformRef {
  /** @internal */
  List<ApplicationRef> _applications = [];
  /** @internal */
  List<Function> _disposeListeners = [];
  bool _disposed = false;
  Injector _injector;
  void init(Injector injector) {
    if (!_inPlatformCreate) {
      throw new BaseException(
          "Platforms have to be initialized via `createPlatform`!");
    }
    this._injector = injector;
    List<Function> inits =
        (injector.get(PLATFORM_INITIALIZER, null) as List<Function>);
    inits?.forEach((init) => init());
  }

  void registerDisposeListener(void dispose()) {
    this._disposeListeners.add(dispose);
  }

  Injector get injector {
    return this._injector;
  }

  get disposed {
    return this._disposed;
  }

  addApplication(ApplicationRef appRef) {
    this._applications.add(appRef);
  }

  void dispose() {
    ListWrapper.clone(this._applications).forEach((app) => app.dispose());
    this._disposeListeners.forEach((dispose) => dispose());
    this._disposed = true;
  }

  /** @internal */
  void _applicationDisposed(ApplicationRef app) {
    ListWrapper.remove(this._applications, app);
  }
}

/**
 * A reference to an Angular application running on a page.
 *
 * For more about Angular applications, see the documentation for [bootstrap].
 */
abstract class ApplicationRef {
  /**
   * Register a listener to be called each time `bootstrap()` is called to bootstrap
   * a new root component.
   */
  void registerBootstrapListener(void listener(ComponentRef ref));
  /**
   * Register a listener to be called when the application is disposed.
   */
  void registerDisposeListener(void dispose());
  /**
   * Returns a promise that resolves when all asynchronous application initializers
   * are done.
   */
  Future<dynamic> waitForAsyncInitializers();
  /**
   * Runs the given callback in the zone and returns the result of the callback.
   * Exceptions will be forwarded to the ExceptionHandler and rethrown.
   */
  dynamic run(Function callback);
  /**
   * Bootstrap a new component at the root level of the application.
   *
   * ### Bootstrap process
   *
   * When bootstrapping a new root component into an application, Angular mounts the
   * specified application component onto DOM elements identified by the [componentType]'s
   * selector and kicks off automatic change detection to finish initializing the component.
   *
   * ### Example
   * {@example core/ts/platform/platform.ts region='longform'}
   */
  ComponentRef bootstrap(ComponentFactory componentFactory);
  /**
   * Retrieve the application [Injector].
   */
  Injector get injector;

  /**
   * Retrieve the application [NgZone].
   */
  NgZone get zone;

  /**
   * Dispose of this application and all of its components.
   */
  void dispose();
  /**
   * Invoke this method to explicitly process change detection and its side-effects.
   *
   * In development mode, `tick()` also performs a second change detection cycle to ensure that no
   * further changes are detected. If additional changes are picked up during this second cycle,
   * bindings in the app have side-effects that cannot be resolved in a single change detection
   * pass.
   * In this case, Angular throws an error, since an Angular application can only have one change
   * detection pass during which all change detection must complete.
   */
  void tick();
  /**
   * Get a list of component types registered to this application.
   */
  List<Type> get componentTypes;

  /**
   * Get a list of component factories registered to this application.
   */
  List<ComponentFactory> get componentFactories;
}

@Injectable()
class ApplicationRef_ extends ApplicationRef {
  PlatformRef_ _platform;
  NgZone _zone;
  Injector _injector;
  /** @internal */
  static WtfScopeFn _tickScope = wtfCreateScope("ApplicationRef#tick()");
  /** @internal */
  List<Function> _bootstrapListeners = [];
  /** @internal */
  List<Function> _disposeListeners = [];
  /** @internal */
  List<ComponentRef> _rootComponents = [];
  /** @internal */
  List<ComponentFactory> _rootComponentFactories = [];
  /** @internal */
  List<ChangeDetectorRef> _changeDetectorRefs = [];
  /** @internal */
  bool _runningTick = false;
  /** @internal */
  bool _enforceNoNewChanges = false;
  ExceptionHandler _exceptionHandler;
  Future<dynamic> _asyncInitDonePromise;
  bool _asyncInitDone;
  ApplicationRef_(this._platform, this._zone, this._injector) : super() {
    /* super call moved to initializer */;
    NgZone zone = _injector.get(NgZone);
    this._enforceNoNewChanges = assertionsEnabled();
    zone.run(() {
      this._exceptionHandler = _injector.get(ExceptionHandler);
    });
    this._asyncInitDonePromise = this.run(() {
      List<Function> inits =
          _injector.get(APP_INITIALIZER, null) as List<Function>;
      var asyncInitResults = [];
      var asyncInitDonePromise;
      if (isPresent(inits)) {
        for (var i = 0; i < inits.length; i++) {
          var initResult = inits[i]();
          if (isPromise(initResult)) {
            asyncInitResults.add(initResult);
          }
        }
      }
      if (asyncInitResults.length > 0) {
        asyncInitDonePromise = PromiseWrapper
            .all(asyncInitResults)
            .then((_) => this._asyncInitDone = true);
        this._asyncInitDone = false;
      } else {
        this._asyncInitDone = true;
        asyncInitDonePromise = PromiseWrapper.resolve(true);
      }
      return asyncInitDonePromise;
    });
    ObservableWrapper.subscribe(zone.onError, (NgZoneError error) {
      this._exceptionHandler.call(error.error, error.stackTrace);
    });
    ObservableWrapper.subscribe(this._zone.onMicrotaskEmpty, (_) {
      this._zone.run(() {
        this.tick();
      });
    });
  }
  void registerBootstrapListener(void listener(ComponentRef ref)) {
    this._bootstrapListeners.add(listener);
  }

  void registerDisposeListener(void dispose()) {
    this._disposeListeners.add(dispose);
  }

  void registerChangeDetector(ChangeDetectorRef changeDetector) {
    this._changeDetectorRefs.add(changeDetector);
  }

  void unregisterChangeDetector(ChangeDetectorRef changeDetector) {
    ListWrapper.remove(this._changeDetectorRefs, changeDetector);
  }

  Future<dynamic> waitForAsyncInitializers() {
    return this._asyncInitDonePromise;
  }

  dynamic run(Function callback) {
    var zone = this.injector.get(NgZone);
    var result;
    // Note: Don't use zone.runGuarded as we want to know about

    // the thrown exception!

    // Note: the completer needs to be created outside

    // of `zone.run` as Dart swallows rejected promises

    // via the onError callback of the promise.
    var completer = PromiseWrapper.completer();
    zone.run(() {
      try {
        result = callback();
        if (isPromise(result)) {
          PromiseWrapper.then(result, (ref) {
            completer.resolve(ref);
          }, (err, stackTrace) {
            completer.reject(err, stackTrace);
            this._exceptionHandler.call(err, stackTrace);
          });
        }
      } catch (e, e_stack) {
        this._exceptionHandler.call(e, e_stack);
        rethrow;
      }
    });
    return isPromise(result) ? completer.promise : result;
  }

  ComponentRef bootstrap(ComponentFactory componentFactory) {
    if (!this._asyncInitDone) {
      throw new BaseException(
          "Cannot bootstrap as there are still asynchronous initializers running. Wait for them using waitForAsyncInitializers().");
    }
    return this.run(() {
      this._rootComponentFactories.add(componentFactory);
      var compRef = componentFactory.create(
          this._injector, [], componentFactory.selector);
      compRef.onDestroy(() {
        this._unloadComponent(compRef);
      });
      var testability = compRef.injector.get(Testability, null);
      if (isPresent(testability)) {
        compRef.injector
            .get(TestabilityRegistry)
            .registerApplication(compRef.location.nativeElement, testability);
      }
      this._loadComponent(compRef);
      var c = (this._injector.get(Console) as Console);
      if (assertionsEnabled()) {
        c.log(
            "Angular 2 is running in the development mode. Call enableProdMode() to enable the production mode.");
      }
      return compRef;
    });
  }

  /** @internal */
  void _loadComponent(ComponentRef componentRef) {
    this._changeDetectorRefs.add(componentRef.changeDetectorRef);
    this.tick();
    this._rootComponents.add(componentRef);
    this._bootstrapListeners.forEach((listener) => listener(componentRef));
  }

  /** @internal */
  void _unloadComponent(ComponentRef componentRef) {
    if (!ListWrapper.contains(this._rootComponents, componentRef)) {
      return;
    }
    this.unregisterChangeDetector(componentRef.changeDetectorRef);
    ListWrapper.remove(this._rootComponents, componentRef);
  }

  Injector get injector {
    return this._injector;
  }

  NgZone get zone {
    return this._zone;
  }

  void tick() {
    ViewUtils.resetChangeDetection();
    if (this._runningTick) {
      throw new BaseException("ApplicationRef.tick is called recursively");
    }
    var s = ApplicationRef_._tickScope();
    try {
      this._runningTick = true;
      this._changeDetectorRefs.forEach((detector) => detector.detectChanges());
      if (this._enforceNoNewChanges) {
        this
            ._changeDetectorRefs
            .forEach((detector) => detector.checkNoChanges());
      }
    } finally {
      this._runningTick = false;
      wtfLeave(s);
    }
  }

  void dispose() {
    // TODO(alxhub): Dispose of the NgZone.
    ListWrapper.clone(this._rootComponents).forEach((ref) => ref.destroy());
    this._disposeListeners.forEach((dispose) => dispose());
    this._platform._applicationDisposed(this);
  }

  List<Type> get componentTypes {
    return this
        ._rootComponentFactories
        .map((factory) => factory.componentType)
        .toList();
  }

  List<ComponentFactory> get componentFactories {
    return this._rootComponentFactories;
  }
}

/**
 * @internal
 */
const PLATFORM_CORE_PROVIDERS = const [
  PlatformRef_,
  const Provider(PlatformRef, useExisting: PlatformRef_)
];
/**
 * @internal
 */
const APPLICATION_CORE_PROVIDERS = const [
  const Provider(NgZone, useFactory: createNgZone, deps: const []),
  ApplicationRef_,
  const Provider(ApplicationRef, useExisting: ApplicationRef_)
];
