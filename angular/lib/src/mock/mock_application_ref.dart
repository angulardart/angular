import "dart:async";

import "package:angular/src/core/application_ref.dart" show ApplicationRef;
import "package:angular/src/core/di.dart" show Injectable, Injector;
import "package:angular/src/core/linker/component_factory.dart"
    show ComponentRef, ComponentFactory;
import "package:angular/src/core/zone/ng_zone.dart" show NgZone;

/// A no-op implementation of [ApplicationRef], useful for testing.
@Injectable()
class MockApplicationRef extends ApplicationRef {
  void registerBootstrapListener(void listener(ComponentRef ref)) {}
  void registerDisposeListener(void dispose()) {}
  ComponentRef bootstrap(ComponentFactory componentFactory) {
    return null;
  }

  Injector get injector {
    return null;
  }

  NgZone get zone {
    return null;
  }

  @override
  dynamic run<R>(FutureOr<R> callback()) => null;

  Future<dynamic> waitForAsyncInitializers() {
    return null;
  }

  void dispose() {}
  void tick() {}
  List<Type> get componentTypes {
    return null;
  }

  List<ComponentFactory> get componentFactories => null;
}
