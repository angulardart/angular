import "dart:async";

import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/core/reflection/reflection.dart" show reflector;
import "package:angular2/src/facade/exceptions.dart" show BaseException;

import "component_factory.dart" show ComponentFactory;
import "injector_factory.dart" show CodegenInjectorFactory;

/// Low-level service for loading [ComponentFactory]s, which
/// can later be used to create and render a Component instance.
abstract class ComponentResolver {
  Future<ComponentFactory> resolveComponent(Type componentType);

  CodegenInjectorFactory createInjectorFactory(Type injectorModule,
      [List extraProviders]);

  void clearCache();
}

bool _isComponentFactory(dynamic type) {
  return type is ComponentFactory;
}

@Injectable()
class ReflectorComponentResolver implements ComponentResolver {
  Future<ComponentFactory> resolveComponent(Type componentType) {
    var metadatas = reflector.annotations(componentType);
    var componentFactory =
        metadatas.firstWhere(_isComponentFactory, orElse: () => null);
    if (componentFactory == null) {
      throw new BaseException('No precompiled component $componentType found');
    }
    return new Future<ComponentFactory>.value(componentFactory);
  }

  @override
  CodegenInjectorFactory createInjectorFactory(Type injectorModule,
      [List extraProviders]) {
    throw new UnimplementedError();
  }

  @override
  void clearCache() {}
}
