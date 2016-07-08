library angular2.src.mock.mock_application_ref;

import "dart:async";

import "package:angular2/src/core/application_ref.dart" show ApplicationRef;
import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/core/di.dart" show Injector;
import "package:angular2/src/core/linker/component_factory.dart"
    show ComponentRef, ComponentFactory;
import "package:angular2/src/core/zone/ng_zone.dart" show NgZone;
import "package:angular2/src/facade/lang.dart" show Type;

/**
 * A no-op implementation of [ApplicationRef], useful for testing.
 */
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

  dynamic run(Function callback) {
    return null;
  }

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
