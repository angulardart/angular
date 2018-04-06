import 'dart:async';

import 'package:angular/src/runtime.dart';

import '../di.dart';
import 'component_factory.dart' show ComponentRef;
import 'component_loader.dart' show ComponentLoader;
// ignore: deprecated_member_use
import 'component_resolver.dart' show typeToFactory;
import 'view_container_ref.dart' show ViewContainerRef;

/// Supports imperatively loading and binding new components at runtime.
///
/// It will soon be required to instead use `ComponentLoader`, which is a nearly
/// identical _synchronous_ API that is much more optimized and will be
/// supported long-term. See `doc/component_loading.md` for more information.
@Deprecated('Use ComponentLoader with an imported ComponentFactory instead.')
@Injectable()
class SlowComponentLoader {
  final ComponentLoader _loader;

  const SlowComponentLoader(this._loader);

  /// Creates and loads a new instance of the component defined by [type].
  ///
  /// See [ComponentLoader.loadDetached] for a similar example.
  Future<ComponentRef<T>> load<T>(Type type, Injector injector) {
    // Purposefully don't use async/await to retain timing.
    final factoryFuture = new Future.value(typeToFactory(type));
    return factoryFuture.then((component) {
      final reference = _loader.loadDetached(component, injector: injector);
      reference.onDestroy(() {
        reference.location.remove();
      });
      return unsafeCast(reference);
    });
  }

  /// Creates and loads a new instance of component [type] next to [location].
  ///
  /// See [ComponentLoader.loadNextToLocation] for a similar example.
  Future<ComponentRef<T>> loadNextToLocation<T>(
    Type type,
    ViewContainerRef location, [
    Injector injector,
  ]) {
    // Purposefully don't use async/await to retain timing.
    final factoryFuture = new Future.value(typeToFactory(type));
    return factoryFuture.then((component) {
      return _loader.loadNextToLocation(
        unsafeCast(component),
        location,
        injector: injector,
      );
    });
  }
}
