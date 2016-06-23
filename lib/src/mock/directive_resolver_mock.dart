library angular2.src.mock.directive_resolver_mock;

import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/facade/collection.dart"
    show Map, MapWrapper, ListWrapper;
import "package:angular2/src/facade/lang.dart"
    show Type, isPresent, stringify, isBlank, print;
import "../core/metadata.dart" show DirectiveMetadata, ComponentMetadata;
import "package:angular2/src/compiler/directive_resolver.dart"
    show DirectiveResolver;

/**
 * An implementation of [DirectiveResolver] that allows overriding
 * various properties of directives.
 */
@Injectable()
class MockDirectiveResolver extends DirectiveResolver {
  var _providerOverrides = new Map<Type, List<dynamic>>();
  var viewProviderOverrides = new Map<Type, List<dynamic>>();
  DirectiveMetadata resolve(Type type) {
    var dm = super.resolve(type);
    var providerOverrides = this._providerOverrides[type];
    var viewProviderOverrides = this.viewProviderOverrides[type];
    var providers = dm.providers;
    if (isPresent(providerOverrides)) {
      var originalViewProviders = isPresent(dm.providers) ? dm.providers : [];
      providers =
          (new List.from(originalViewProviders)..addAll(providerOverrides));
    }
    if (dm is ComponentMetadata) {
      var viewProviders = dm.viewProviders;
      if (isPresent(viewProviderOverrides)) {
        var originalViewProviders =
            isPresent(dm.viewProviders) ? dm.viewProviders : [];
        viewProviders = (new List.from(originalViewProviders)
          ..addAll(viewProviderOverrides));
      }
      return new ComponentMetadata(
          selector: dm.selector,
          inputs: dm.inputs,
          outputs: dm.outputs,
          host: dm.host,
          exportAs: dm.exportAs,
          moduleId: dm.moduleId,
          queries: dm.queries,
          changeDetection: dm.changeDetection,
          providers: providers,
          viewProviders: viewProviders);
    }
    return new DirectiveMetadata(
        selector: dm.selector,
        inputs: dm.inputs,
        outputs: dm.outputs,
        host: dm.host,
        providers: providers,
        exportAs: dm.exportAs,
        queries: dm.queries);
  }

  /**
   * 
   */
  void setBindingsOverride(Type type, List<dynamic> bindings) {
    this._providerOverrides[type] = bindings;
  }

  /**
   * 
   */
  void setViewBindingsOverride(Type type, List<dynamic> viewBindings) {
    this.viewProviderOverrides[type] = viewBindings;
  }

  void setProvidersOverride(Type type, List<dynamic> providers) {
    this._providerOverrides[type] = providers;
  }

  void setViewProvidersOverride(Type type, List<dynamic> viewProviders) {
    this.viewProviderOverrides[type] = viewProviders;
  }
}
