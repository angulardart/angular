import 'dart:async';

import 'package:angular/src/core/di.dart' show Injectable;
import 'package:angular/src/di/reflector.dart' as reflector;
import 'package:angular/src/facade/exceptions.dart' show BaseException;

import 'component_factory.dart' show ComponentFactory;

/// Low-level service for loading [ComponentFactory]s, which
/// can later be used to create and render a Component instance.
abstract class ComponentResolver {
  Future<ComponentFactory> resolveComponent(Type componentType);

  ComponentFactory resolveComponentSync(Type componentType);

  void clearCache();
}

@Injectable()
class ReflectorComponentResolver implements ComponentResolver {
  const ReflectorComponentResolver();

  Future<ComponentFactory> resolveComponent(Type componentType) {
    final component = reflector.getComponent(componentType) as ComponentFactory;
    if (component == null) {
      throw new BaseException('No precompiled component $componentType found');
    }
    return new Future<ComponentFactory>.value(component);
  }

  @override
  ComponentFactory resolveComponentSync(Type componentType) {
    final component = reflector.getComponent(componentType) as ComponentFactory;
    if (component == null) {
      throw new BaseException('No precompiled component $componentType found');
    }
    return component;
  }

  @override
  void clearCache() {}
}
