library angular2.src.core.linker.component_resolver;

import "dart:async";
import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/facade/lang.dart"
    show Type, isBlank, isString, stringify;
import "package:angular2/src/facade/exceptions.dart"
    show BaseException, unimplemented;
import "package:angular2/src/facade/async.dart" show PromiseWrapper;
import "package:angular2/src/core/reflection/reflection.dart" show reflector;
import "component_factory.dart" show ComponentFactory;
import "injector_factory.dart" show CodegenInjectorFactory;

/**
 * Low-level service for loading [ComponentFactory]s, which
 * can later be used to create and render a Component instance.
 */
abstract class ComponentResolver {
  Future<ComponentFactory> resolveComponent(Type componentType);
  CodegenInjectorFactory<dynamic> createInjectorFactory(Type injectorModule,
      [List<dynamic> extraProviders]);
  clearCache();
}

bool _isComponentFactory(dynamic type) {
  return type is ComponentFactory;
}

@Injectable()
class ReflectorComponentResolver extends ComponentResolver {
  Future<ComponentFactory> resolveComponent(Type componentType) {
    var metadatas = reflector.annotations(componentType);
    var componentFactory =
        metadatas.firstWhere(_isComponentFactory, orElse: () => null);
    if (isBlank(componentFactory)) {
      throw new BaseException(
          '''No precompiled component ${ stringify ( componentType )} found''');
    }
    return PromiseWrapper.resolve(componentFactory);
  }

  CodegenInjectorFactory<dynamic> createInjectorFactory(Type injectorModule,
      [List<dynamic> extraProviders]) {
    return unimplemented();
  }

  clearCache() {}
}
