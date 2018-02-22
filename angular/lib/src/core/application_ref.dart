import 'dart:async';
import 'dart:html';

import 'package:angular/src/runtime.dart';
import 'package:meta/meta.dart';

import '../facade/exceptions.dart' show BaseException, ExceptionHandler;
import '../facade/lang.dart' show assertionsEnabled;
import '../platform/dom/shared_styles_host.dart';
import 'application_tokens.dart' show PLATFORM_INITIALIZER, APP_INITIALIZER;
import 'change_detection/change_detector_ref.dart';
import 'change_detection/constants.dart';
import 'di.dart';
import 'linker/app_view.dart'
    show lastGuardedView, caughtException, caughtStack, AppView;
import 'linker/app_view_utils.dart';
import 'linker/component_factory.dart' show ComponentRef, ComponentFactory;
import 'linker/component_resolver.dart';
import 'linker/view_ref.dart';
import 'render/api.dart' show sharedStylesHost;
import 'testability/testability.dart' show TestabilityRegistry, Testability;
import 'zone/ng_zone.dart' show NgZone, NgZoneError;

// TODO: Remove the following lines (for --no-implicit-casts).
// ignore_for_file: argument_type_not_assignable
// ignore_for_file: invalid_assignment
// ignore_for_file: list_element_type_not_assignable
// ignore_for_file: non_bool_operand
// ignore_for_file: return_of_invalid_type

/// Create an Angular zone.
NgZone createNgZone() => new NgZone(enableLongStackTrace: assertionsEnabled());

PlatformRefImpl _platform;
bool _inPlatformCreate = false;

/// Creates a platform.
/// Platforms have to be eagerly created via this function.
PlatformRefImpl createPlatform(Injector injector) {
  if (isDevMode) {
    if (_inPlatformCreate) {
      throw new BaseException('Already creating a platform...');
    }
    if (_platform != null && !_platform.disposed) {
      throw new BaseException('There can be only one platform. Destroy the '
          'previous one to create a new one.');
    }
  }
  _inPlatformCreate = true;
  sharedStylesHost ??= new DomSharedStylesHost(document);
  try {
    _platform = injector.get(PlatformRef) as PlatformRefImpl;
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
ComponentRef<T> coreBootstrap<T>(
  Injector injector,
  ComponentFactory<T> componentFactory,
) {
  appViewUtils = injector.get(AppViewUtils);
  ApplicationRef appRef = injector.get(ApplicationRef);
  return appRef.bootstrap(componentFactory);
}

/// Resolves the componentFactory for the given component,
/// waits for asynchronous initializers and bootstraps the component.
///
/// Requires a platform the be created first.
Future<ComponentRef<T>> coreLoadAndBootstrap<T>(
  Injector injector,
  Type componentType,
) async {
  appViewUtils = injector.get(AppViewUtils);
  ApplicationRef appRef = injector.get(ApplicationRef);
  return await appRef.run(() async {
    // ignore: deprecated_member_use
    ComponentResolver componentResolver = injector.get(ComponentResolver);
    ComponentFactory factory =
        // ignore: deprecated_member_use
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

  // Schedules change detection and view update to be executed on next
  /// animation frame.
  void scheduleViewUpdate(
      ViewUpdateCallback callback, AppView view, Element el);
}

typedef void ViewUpdateCallback(AppView view, Element el);

@Injectable()
class PlatformRefImpl extends PlatformRef {
  final List<ApplicationRef> _applications = [];
  final List<Function> _disposeListeners = [];
  bool _disposed = false;
  Injector _injector;
  // When true, indicates that we have already scheduled an animation frame
  // callback.
  bool _rafScheduled = false;
  List<AppView> _targetViews;
  List<Element> _targetElements;
  List<ViewUpdateCallback> _viewUpdateCallbacks;

  /// Given an injector, gets platform initializers to initialize at bootstrap.
  void init(Injector injector) {
    if (isDevMode && !_inPlatformCreate) {
      throw new BaseException(
          'Platforms have to be initialized via `createPlatform`!');
    }
    _injector = injector;

    List initializers = injector.get(PLATFORM_INITIALIZER, null);
    if (initializers == null) return;
    for (var initializer in initializers) {
      initializer();
    }
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
    for (var app in _applications) {
      app.dispose();
    }
    _applications.clear();
    for (var dispose in _disposeListeners) {
      dispose();
    }
    _disposeListeners.clear();
    _disposed = true;
  }

  void _applicationDisposed(ApplicationRef app) {
    _applications.remove(app);
  }

  @override
  void scheduleViewUpdate(
      ViewUpdateCallback callback, AppView view, Element el) {
    if (_targetViews == null) {
      _targetViews = <AppView>[];
      _targetElements = <Element>[];
      _viewUpdateCallbacks = <ViewUpdateCallback>[];
    }
    _targetViews.add(view);
    _targetElements.add(el);
    _viewUpdateCallbacks.add(callback);
    if (_rafScheduled == false) {
      _rafScheduled = true;
      window.requestAnimationFrame(_onAnimationFrame);
    }
  }

  void _onAnimationFrame(num _) {
    int i = 0;
    try {
      while (i < _targetViews.length) {
        _viewUpdateCallbacks[i](_targetViews[i], _targetElements[i]);
        ++i;
      }
    } catch (e, s) {
      ExceptionHandler exceptionHandler = _injector.get(ExceptionHandler);
      exceptionHandler?.call(e, s);
      _viewUpdateCallbacks.removeAt(i);
      _targetViews.removeAt(i);
      _targetElements.removeAt(i);
    }
    _targetViews.clear();
    _targetElements.clear();
    _viewUpdateCallbacks.clear();
    _rafScheduled = false;
  }
}

/// A reference to an Angular application running on a page.
///
/// For more about Angular applications, see the documentation for [bootstrap].
abstract class ApplicationRef {
  /// Register a listener to be called each time `bootstrap()` is called to bootstrap
  /// a new root component.
  void registerBootstrapListener(void listener(ComponentRef<Null> ref));

  /// Register a listener to be called when the application is disposed.
  void registerDisposeListener(void dispose());

  /// Returns a promise that resolves when all asynchronous application
  /// initializers are done.
  Future<dynamic> waitForAsyncInitializers();

  /// Runs the given [callback] in the zone and returns the result of the call.
  ///
  /// Exceptions will be forwarded to the ExceptionHandler and rethrown.
  run<R>(FutureOr<R> callback());

  /// Bootstrap a new component at the root level of the application.
  ///
  /// When bootstrapping a new root component into an application,
  /// Angular mounts the specified application component onto DOM elements
  /// identified by the component's selector and kicks off automatic change
  /// detection to finish initializing the component.
  ComponentRef<T> bootstrap<T>(
    ComponentFactory<T> componentFactory, [
    // TODO(matanl): Remove from the public API before 5.x.
    //
    // In a normal application (bootstrapStatic), we always use the same
    // injector that contains ApplicationRef (root injector) to bootstrap the
    // root component.
    //
    // In an experimental application (bootstrapFactory), we have tiers:
    //   {empty} <-- platformInjector <-- bootstrapInjector <-- appInjector
    //
    // ... where appInjector is the user-defined set of modules that are
    // expected to be used when you bootstrap the root component. The "parent"
    // field may be set in that case.
    @experimental Injector parent,
  ]);

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
  final List<Function> _bootstrapListeners = [];
  final List<Function> _disposeListeners = [];
  final List<ComponentRef> _rootComponents = [];
  final List<ComponentFactory> _rootComponentFactories = [];
  final List<ChangeDetectorRef> _changeDetectorRefs = [];
  final List<StreamSubscription> _streamSubscriptions = [];
  bool _runningTick = false;
  bool _enforceNoNewChanges = false;
  ExceptionHandler _exceptionHandler;
  Future<bool> _asyncInitDonePromise;
  bool _asyncInitDone;

  ApplicationRefImpl(this._platform, this._zone, this._injector) {
    NgZone zone = _injector.get(NgZone);
    _enforceNoNewChanges = assertionsEnabled();
    zone.run(() {
      _exceptionHandler = _injector.get(ExceptionHandler);
    });
    // <bool> due to https://github.com/dart-lang/sdk/issues/32284.
    _asyncInitDonePromise = this.run<bool>(() {
      List<Function> initializers = _injector.get(APP_INITIALIZER, null);
      var asyncInitResults = <Future>[];
      Future<bool> asyncInitDonePromise;
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
        asyncInitDonePromise = Future.wait(asyncInitResults).then((_) {
          _asyncInitDone = true;
        });
        _asyncInitDone = false;
      } else {
        _asyncInitDone = true;
        asyncInitDonePromise = new Future.value(true);
      }
      return asyncInitDonePromise;
    });
    _streamSubscriptions.add(_zone.onError.listen((NgZoneError error) {
      _exceptionHandler.call(error.error, error.stackTrace);
    }));
    _streamSubscriptions.add(_zone.onMicrotaskEmpty.listen((_) {
      _zone.runGuarded(() {
        tick();
      });
    }));
  }
  void registerBootstrapListener(void listener(ComponentRef<Null> ref)) {
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
  // TODO(leafp): The return type of this is essentially Future<R>|R|Null.
  // When FutureOr<T> lands, this can be expressed as FutureOr<R>.  For now
  // leave it as dynamic, but pass a generic type so that the returned
  // Future (if any) has the correct reified type.
  run<R>(FutureOr<R> callback()) {
    // TODO(matanl): Remove support for futures inside of appRef.run.
    final NgZone zone = injector.get(NgZone);
    // Using FutureOr<R> results in strange behavior/bad type promotion:
    // https://github.com/dart-lang/sdk/issues/32285
    var result;
    // Note: Don't use zone.runGuarded as we want to know about the thrown
    // exception!
    //
    // Note: the completer needs to be created outside of `zone.run` as Dart
    // swallows rejected promises via the onError callback of the promise.
    var completer = new Completer<R>();
    zone.run(() {
      try {
        result = callback();
        // Cannot properly type (or type promote) due to analyzer bug:
        // https://github.com/dart-lang/sdk/issues/32285
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

  ComponentRef<T> bootstrap<T>(
    ComponentFactory<T> componentFactory, [
    Injector parent,
  ]) {
    if (isDevMode && !_asyncInitDone) {
      throw new BaseException(
          'Cannot bootstrap as there are still asynchronous initializers '
          'running. Wait for them using waitForAsyncInitializers().');
    }

    return run(() {
      _rootComponentFactories.add(componentFactory);
      var compRef = componentFactory.create(parent ?? _injector, const []);
      Element existingElement =
          document.querySelector(componentFactory.selector);
      Element replacement;
      if (existingElement != null) {
        Element newElement = compRef.location;
        // For app shards using bootstrapStatic, transfer element id
        // from original node to allow hosting applications to locate loaded
        // application root.
        if (newElement.id == null || newElement.id.isEmpty) {
          newElement.id = existingElement.id;
        }
        existingElement.replaceWith(newElement);
        replacement = newElement;
      } else {
        assert(compRef.location != null,
            'Could not locate node with selector ${componentFactory.selector}');
        document.body.append(compRef.location);
      }
      compRef.onDestroy(() {
        _unloadComponent(compRef);
        replacement?.remove();
      });
      var testability = compRef.injector.get(Testability, null);
      if (testability != null) {
        compRef.injector
            .get(TestabilityRegistry)
            .registerApplication(compRef.location, testability);
      }
      _loadComponent(compRef);
      return compRef;
    });
  }

  void _loadComponent(ComponentRef<dynamic> componentRef) {
    _changeDetectorRefs.add(componentRef.changeDetectorRef);
    tick();
    _rootComponents.add(componentRef);
    for (var listener in _bootstrapListeners) {
      listener(componentRef);
    }
  }

  void _unloadComponent(ComponentRef<dynamic> componentRef) {
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

    // Protect against tick being called recursively in development mode.
    //
    // This is mostly to assert valid changes to the framework, not user code.
    if (isDevMode && _runningTick) {
      throw new BaseException('ApplicationRef.tick is called recursively');
    }

    // Run the top-level 'tick' (i.e. detectChanges on root components).
    try {
      _runTick();
    } catch (e, s) {
      // A crash (uncaught exception) was found. That means at least one
      // directive in the application tree is throwing. We need to re-run
      // change detection to disable offending directives.
      if (!_runTickGuarded()) {
        // Propagate the original exception/stack upwards.
        _exceptionHandler.call(e, s, 'Tick');
      }
      // And re-throw.
      rethrow;
    } finally {
      // Tick is complete.
      _runningTick = false;
      lastGuardedView = null;
    }
  }

  /// Runs `detectChanges` for all top-level components/views.
  void _runTick() {
    _runningTick = true;
    for (int c = 0; c < _changeDetectorRefs.length; c++) {
      _changeDetectorRefs[c].detectChanges();
    }

    // Only occurs in dev-mode.
    if (_enforceNoNewChanges) {
      for (int c = 0; c < _changeDetectorRefs.length; c++) {
        _changeDetectorRefs[c].checkNoChanges();
      }
    }
  }

  /// Runs `detectChanges` for all top-level components/views.
  ///
  /// Unlike `_runTick`, this enters a guarded mode that checks a view tree
  /// for exceptions, trying to find the leaf-most node that throws during
  /// change detection.
  ///
  /// Returns whether an exception was caught.
  bool _runTickGuarded() {
    _runningTick = true;

    // For all ViewRefImpls (i.e. concrete AppViews), run change detection.
    for (int c = 0; c < _changeDetectorRefs.length; c++) {
      var cdRef = _changeDetectorRefs[c];
      if (cdRef is ViewRefImpl) {
        lastGuardedView = cdRef.appView;
        cdRef.appView.detectChanges();
      }
    }

    lastGuardedView?.cdState = ChangeDetectorState.Errored;

    // Original exception was already caught and will trickle up.
    if (caughtException != null) {
      _exceptionHandler.call(caughtException, caughtStack);
      caughtException = caughtStack = null;
      return true;
    }

    return false;
  }

  @override
  void dispose() {
    for (var ref in _rootComponents) {
      ref.destroy();
    }
    for (var dispose in _disposeListeners) {
      dispose();
    }
    _disposeListeners.clear();
    for (var subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
    _platform._applicationDisposed(this);
  }

  @override
  List<Type> get componentTypes =>
      // ignore: deprecated_member_use
      _rootComponentFactories.map((factory) => factory.componentType).toList();

  @override
  List<ComponentFactory> get componentFactories => _rootComponentFactories;
}
