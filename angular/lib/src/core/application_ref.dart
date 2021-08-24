import 'dart:async';
import 'dart:html';

import 'package:meta/dart2js.dart' as dart2js;
import 'package:angular/src/core/exception_handler.dart';
import 'package:angular/src/devtools.dart';
import 'package:angular/src/di/injector.dart';
import 'package:angular/src/testability.dart';
import 'package:angular/src/utilities.dart';

import 'change_detection/host.dart';
import 'linker/component_factory.dart' show ComponentRef, ComponentFactory;
import 'zone/ng_zone.dart' show NgZone;

/// **INTERNAL ONLY**: Do not use.
@dart2js.tryInline
ApplicationRef internalCreateApplicationRef(
  NgZone ngZone,
  Injector injector,
) =>
    ApplicationRef._(
      ngZone,
      injector.provideType(ExceptionHandler),
      injector,
    );

/// A reference to an Angular application running on a page.
///
/// For more about Angular applications, see the documentation for [bootstrap].
class ApplicationRef extends ChangeDetectionHost {
  final _disposeListeners = <void Function()>[];
  final _rootComponents = <ComponentRef<void>>[];

  final ExceptionHandler _exceptionHandler;
  final Injector _injector;
  final NgZone _ngZone;

  late final StreamSubscription<void> _onErrorSub;
  late final StreamSubscription<void> _onMicroSub;

  ApplicationRef._(
    this._ngZone,
    this._exceptionHandler,
    this._injector,
  ) {
    _onErrorSub = _ngZone.onUncaughtError.listen((e) {
      handleUncaughtException(
        e.error,
        e.stackTrace,
      );
    });
    _onMicroSub = _ngZone.onMicrotaskEmpty.listen((_) {
      _ngZone.runGuarded(tick);
    });
  }

  /// Register a listener to be called when the application is disposed.
  void registerDisposeListener(void Function() listener) {
    _disposeListeners.add(listener);
  }

  /// Bootstrap a new component at the root level of the application.
  ///
  /// When bootstrapping a new root component into an application,
  /// Angular mounts the specified application component onto DOM elements
  /// identified by the component's selector and kicks off automatic change
  /// detection to finish initializing the component.
  ComponentRef<T> bootstrap<T extends Object>(
    ComponentFactory<T> componentFactory,
  ) {
    return unsafeCast(run(() {
      final component = componentFactory.create(_injector);
      final existing = querySelector(componentFactory.selector);
      Element? replacement;
      if (existing != null) {
        final newElement = component.location;
        // For app shards using bootstrapStatic, transfer element id
        // from original node to allow hosting applications to locate loaded
        // application root.
        if (newElement.id.isEmpty) {
          newElement.id = existing.id;
        }
        replacement = newElement;
        existing.replaceWith(replacement);
      } else {
        document.body!.append(component.location);
      }
      final injector = component.injector;
      final testability = injector.provideTypeOptional<Testability>(
        Testability,
      );
      if (testability != null) {
        final registry = _injector.provideType<TestabilityRegistry>(
          TestabilityRegistry,
        );
        registry.registerApplication(component.location, testability);
      }
      _loadedRootComponent(component, replacement);
      return component;
    }));
  }

  void _loadedRootComponent(ComponentRef<void> component, Element? node) {
    if (isDevToolsEnabled) {
      Inspector.instance.registerContentRoot(component.location);
    }
    _rootComponents.add(component);
    component.onDestroy(() {
      _destroyedRootComponent(component);
      node?.remove();
    });
    registerChangeDetector(component.changeDetectorRef);
    tick();
  }

  void _destroyedRootComponent(ComponentRef<void> component) {
    if (!_rootComponents.remove(component)) {
      return;
    }
    unregisterChangeDetector(component.changeDetectorRef);
  }

  /// Dispose of this application and all of its components.
  void dispose() {
    _onErrorSub.cancel();
    _onMicroSub.cancel();
    // Destroying components removes them from this list. Destroying them in
    // reverse order by index ensures their removal is efficient and does not
    // cause a concurrent modification during iteration error.
    for (var i = _rootComponents.length - 1; i >= 0; --i) {
      _rootComponents[i].destroy();
    }
    for (final listener in _disposeListeners) {
      listener();
    }
  }

  @override
  void handleUncaughtException(
    Object error, [
    StackTrace? trace,
    String? reason,
  ]) {
    _exceptionHandler.call(error, trace, reason);
  }

  @override
  R runInZone<R>(R Function() callback) => _ngZone.run(callback);
}

/// An extension for debugging this app.
///
/// This extension is experimental and subject to change.
extension DebugApplicationRef on ApplicationRef {
  /// Returns this app's [NgZone].
  NgZone get zone => _ngZone;

  /// Returns this app's [ExceptionHandler].
  // TODO(b/159650979): move to [App] if deemed an app-wide service.
  ExceptionHandler get exceptionHandler => _exceptionHandler;
}

/// An extension for testing this app.
///
/// This extension is experimental and subject to change.
// TODO(b/157073968): replace with common implementation.
extension TestApplicationRef on ApplicationRef {
  /// Registers a root [componentRef] with this app.
  void registerRootComponent(ComponentRef<void> componentRef) {
    _loadedRootComponent(componentRef, componentRef.location);
  }
}
