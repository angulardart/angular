import 'dart:async';
import 'dart:html';

import 'package:angular/src/core/change_detection/host.dart';
import 'package:angular/src/runtime.dart';
import 'package:meta/dart2js.dart' as dart2js;

import '../facade/exception_handler.dart' show ExceptionHandler;
import 'change_detection/host.dart';
import 'di.dart';
import 'linker/component_factory.dart' show ComponentRef, ComponentFactory;
import 'testability/testability.dart' show TestabilityRegistry, Testability;
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
  final List<void Function()> _disposeListeners = [];
  final List<ComponentRef<void>> _rootComponents = [];

  final ExceptionHandler _exceptionHandler;
  final Injector _injector;
  final NgZone _ngZone;

  StreamSubscription<void> _onErrorSub;
  StreamSubscription<void> _onMicroSub;

  ApplicationRef._(
    this._ngZone,
    this._exceptionHandler,
    this._injector,
  ) {
    _onErrorSub = _ngZone.onError.listen((e) {
      handleUncaughtException(
        e.error,
        StackTrace.fromString(e.stackTrace.join('\n')),
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
  ComponentRef<T> bootstrap<T>(ComponentFactory<T> componentFactory) {
    return unsafeCast(run(() {
      final component = componentFactory.create(_injector);
      final existing = querySelector(componentFactory.selector);
      Element replacement;
      if (existing != null) {
        final newElement = component.location;
        // For app shards using bootstrapStatic, transfer element id
        // from original node to allow hosting applications to locate loaded
        // application root.
        if (newElement.id == null || newElement.id.isEmpty) {
          newElement.id = existing.id;
        }
        replacement = newElement;
        existing.replaceWith(replacement);
      } else {
        assert(component.location != null);
        document.body.append(component.location);
      }
      final injector = component.injector;
      final Testability testability = injector.provideTypeOptional(Testability);
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

  void _loadedRootComponent(ComponentRef<void> component, Element node) {
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
    for (final component in _rootComponents) {
      component.destroy();
    }
    for (final listener in _disposeListeners) {
      listener();
    }
  }

  @override
  void handleUncaughtException(
    Object error, [
    StackTrace trace,
    String reason,
  ]) {
    _exceptionHandler.call(error, trace, reason);
  }

  @override
  R runInZone<R>(R Function() callback) => _ngZone.run(callback);
}
