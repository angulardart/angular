import 'dart:async';

import '../di.dart';
import 'component_factory.dart' show ComponentRef;
import 'component_loader.dart' show ComponentLoader;
import 'component_resolver.dart' show ComponentResolver;
import 'view_container_ref.dart' show ViewContainerRef;

/// Supports imperatively loading and binding new components at runtime.
///
/// **NOTE**: This class is _soft_ deprecated. It is _highly_ recommended to
/// instead use `ComponentLoader`, which is a nearly identical _synchronous_
/// API that is much more optimized and will be supported long-term.
@Injectable()
class SlowComponentLoader {
  final ComponentLoader _loader;
  final ComponentResolver _resolver;

  const SlowComponentLoader(this._loader, this._resolver);

  /// Creates and loads a new instance of the component defined by [type].
  ///
  /// See [ComponentLoader.loadDetached] for a similar example.
  Future<ComponentRef> load(Type type, Injector injector) {
    // Purposefully don't use async/await to retain timing.
    return _resolver.resolveComponent(type).then((component) {
      _resolver.resolveComponent(type);
      final reference = _loader.loadDetached(component, injector: injector);
      reference.onDestroy(() {
        reference.location.remove();
      });
      return reference;
    });
  }

  /// Creates and loads a new instance of component [type] next to [location].
  ///
  /// See [ComponentLoader.loadNextToLocation] for a similar example.
  Future<ComponentRef> loadNextToLocation(
    Type type,
    ViewContainerRef location, [
    Injector injector,
  ]) {
    // Purposefully don't use async/await to retain timing.
    return _resolver.resolveComponent(type).then((component) {
      return _loader.loadNextToLocation(
        component,
        location,
        injector: injector,
      );
    });
  }
}
