import 'dart:async';
import 'dart:html';

import 'package:angular/src/core/change_detection/host.dart';
import 'package:angular/src/runtime.dart';

import '../facade/exception_handler.dart' show ExceptionHandler;
import 'change_detection/host.dart';
import 'di.dart';
import 'linker/component_factory.dart' show ComponentRef, ComponentFactory;
import 'testability/testability.dart' show TestabilityRegistry, Testability;
import 'zone/ng_zone.dart' show NgZone, NgZoneError;

/// Create an Angular zone.
NgZone createNgZone() => new NgZone(enableLongStackTrace: isDevMode);

/// A reference to an Angular application running on a page.
///
/// For more about Angular applications, see the documentation for [bootstrap].
abstract class ApplicationRef implements ChangeDetectionHost {
  /// Register a listener to be called when the application is disposed.
  void registerDisposeListener(void Function() listener);

  /// Bootstrap a new component at the root level of the application.
  ///
  /// When bootstrapping a new root component into an application,
  /// Angular mounts the specified application component onto DOM elements
  /// identified by the component's selector and kicks off automatic change
  /// detection to finish initializing the component.
  ComponentRef<T> bootstrap<T>(ComponentFactory<T> componentFactory);

  /// Dispose of this application and all of its components.
  void dispose();
}

@Injectable()
class ApplicationRefImpl extends ApplicationRef with ChangeDetectionHost {
  final NgZone _zone;
  final Injector _injector;
  final List<void Function()> _disposeListeners = [];
  final List<ComponentRef> _rootComponents = [];
  final List<StreamSubscription> _streamSubscriptions = [];

  ExceptionHandler _exceptionHandler;

  ApplicationRefImpl(this._zone, this._injector) {
    _zone.run(() {
      _exceptionHandler = unsafeCast(_injector.get(ExceptionHandler));
    });
    _streamSubscriptions.add(_zone.onError.listen((NgZoneError error) {
      handleUncaughtException(
        error.error,
        new StackTrace.fromString(error.stackTrace.join('\n')),
      );
    }));
    _streamSubscriptions.add(_zone.onMicrotaskEmpty.listen((_) {
      _zone.runGuarded(() {
        tick();
      });
    }));
  }
  void registerDisposeListener(void Function() listener) {
    _disposeListeners.add(listener);
  }

  ComponentRef<T> bootstrap<T>(ComponentFactory<T> componentFactory) {
    return unsafeCast(run(() {
      var compRef = componentFactory.create(_injector, const []);
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
    }));
  }

  void _loadComponent(ComponentRef<dynamic> componentRef) {
    registerChangeDetector(componentRef.changeDetectorRef);
    tick();
    _rootComponents.add(componentRef);
  }

  void _unloadComponent(ComponentRef<dynamic> componentRef) {
    if (!_rootComponents.contains(componentRef)) {
      return;
    }
    unregisterChangeDetector(componentRef.changeDetectorRef);
    _rootComponents.remove(componentRef);
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
  }

  @override
  void handleUncaughtException(Object error, [StackTrace trace]) {
    _exceptionHandler.call(error, trace);
  }

  @override
  R runInZone<R>(R Function() callback) => _zone.run(callback);
}
