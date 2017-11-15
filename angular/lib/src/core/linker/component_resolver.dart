import 'dart:async';

import 'package:angular/src/core/di.dart' show Injectable;
import 'package:angular/src/di/reflector.dart' as reflector;

import 'component_factory.dart' show ComponentFactory;

/// Low-level service for loading [ComponentFactory]s, which
/// can later be used to create and render a Component instance.
@Deprecated('Use a ComponentFactory with ComponentLoader instead.')
@Injectable()
class ComponentResolver {
  // Prevent inheritance.
  const factory ComponentResolver() = ComponentResolver._;
  const ComponentResolver._();

  @Deprecated('Use a ComponentFactory with ComponentLoader instead.')
  Future<ComponentFactory<dynamic>> resolveComponent(Type componentType) {
    final component = reflector.getComponent(componentType) as ComponentFactory;
    if (component == null) {
      throw new StateError('No precompiled component $componentType found');
    }
    return new Future<ComponentFactory>.value(component);
  }
}
