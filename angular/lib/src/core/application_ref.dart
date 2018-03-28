import 'dart:async';
import 'dart:html';

import 'package:angular/src/core/change_detection/host.dart';
import 'package:angular/src/runtime.dart';
import 'package:meta/meta.dart';

import '../facade/exceptions.dart' show BaseException, ExceptionHandler;
import '../platform/dom/shared_styles_host.dart';
import 'application_tokens.dart' show APP_INITIALIZER;
import 'change_detection/host.dart';
import 'di.dart';
import 'linker/app_view.dart' show AppView;
import 'linker/app_view_utils.dart';
import 'linker/component_factory.dart' show ComponentRef, ComponentFactory;
import 'linker/component_resolver.dart' show typeToFactory;
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
NgZone createNgZone() => new NgZone(enableLongStackTrace: isDevMode);

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
    final factory = typeToFactory(componentType);
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
}

typedef void ViewUpdateCallback(AppView view, Element el);

@Injectable()
class PlatformRefImpl extends PlatformRef {
  final List<ApplicationRef> _applications = [];
  final List<Function> _disposeListeners = [];
  bool _disposed = false;
  Injector _injector;

  /// Given an injector, gets platform initializers to initialize at bootstrap.
  void init(Injector injector) {
    if (isDevMode && !_inPlatformCreate) {
      throw new BaseException(
          'Platforms have to be initialized via `createPlatform`!');
    }
    _injector = injector;
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
}

/// A reference to an Angular application running on a page.
///
/// For more about Angular applications, see the documentation for [bootstrap].
abstract class ApplicationRef implements ChangeDetectionHost {
  /// Register a listener to be called each time `bootstrap()` is called to bootstrap
  /// a new root component.
  void registerBootstrapListener(void listener(ComponentRef<Null> ref));

  /// Register a listener to be called when the application is disposed.
  void registerDisposeListener(void dispose());

  /// Returns a promise that resolves when all asynchronous application
  /// initializers are done.
  Future<dynamic> waitForAsyncInitializers();

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

  /// Dispose of this application and all of its components.
  void dispose();
}

@Injectable()
class ApplicationRefImpl extends ApplicationRef with ChangeDetectionHost {
  final PlatformRefImpl _platform;
  final NgZone _zone;
  final Injector _injector;
  final List<Function> _bootstrapListeners = [];
  final List<Function> _disposeListeners = [];
  final List<ComponentRef> _rootComponents = [];
  final List<StreamSubscription> _streamSubscriptions = [];

  ExceptionHandler _exceptionHandler;
  Future<bool> _asyncInitDonePromise;
  bool _asyncInitDone;

  ApplicationRefImpl(this._platform, this._zone, this._injector) {
    _zone.run(() {
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
      handleUncaughtException(error.error, error.stackTrace);
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

  Future<dynamic> waitForAsyncInitializers() => _asyncInitDonePromise;

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
    registerChangeDetector(componentRef.changeDetectorRef);
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
  void handleUncaughtException(Object error, [StackTrace trace]) {
    _exceptionHandler.call(error, trace);
  }

  @override
  R runInZone<R>(R Function() callback) => _zone.run(callback);
}
