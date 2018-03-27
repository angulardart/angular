import 'dart:async';

import '../di.dart';
import 'component_factory.dart' show ComponentRef;
import 'component_loader.dart' show ComponentLoader;
// ignore: deprecated_member_use
import 'component_resolver.dart' show typeToFactory;
import 'view_container_ref.dart' show ViewContainerRef;

// TODO: Remove the following lines (for --no-implicit-casts).
// ignore_for_file: argument_type_not_assignable
// ignore_for_file: invalid_assignment
// ignore_for_file: list_element_type_not_assignable
// ignore_for_file: non_bool_operand
// ignore_for_file: return_of_invalid_type

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
    final factoryFuture = new Future<T>.value(typeToFactory(type));
    return factoryFuture.then((component) {
      final reference = _loader.loadDetached<T>(component, injector: injector);
      reference.onDestroy(() {
        reference.location.remove();
      });
      return reference;
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
    final factoryFuture = new Future<T>.value(typeToFactory(type));
    return factoryFuture.then((component) {
      return _loader.loadNextToLocation(
        component,
        location,
        injector: injector,
      );
    });
  }
}
