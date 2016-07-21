import "package:angular2/src/compiler/directive_resolver.dart"
    show DirectiveResolver;
import "package:angular2/src/core/di.dart" show Injectable;

import "../core/metadata.dart" show DirectiveMetadata, ComponentMetadata;

/// An implementation of [DirectiveResolver] that allows overriding
/// various properties of directives.
@Injectable()
class MockDirectiveResolver extends DirectiveResolver {
  var _providerOverrides = new Map<Type, List<dynamic>>();
  var viewProviderOverrides = new Map<Type, List<dynamic>>();
  DirectiveMetadata resolve(Type type) {
    var dm = super.resolve(type);
    var providerOverrides = _providerOverrides[type];
    var viewOverrides = viewProviderOverrides[type];
    var providers = dm.providers;
    if (providerOverrides != null) {
      var originalViewProviders = dm.providers ?? [];
      providers =
          (new List.from(originalViewProviders)..addAll(providerOverrides));
    }
    if (dm is ComponentMetadata) {
      var viewProviders = dm.viewProviders;
      if (viewOverrides != null) {
        var originalViewProviders = dm.viewProviders ?? [];
        viewProviders =
            (new List.from(originalViewProviders)..addAll(viewOverrides));
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
          preserveWhitespace: dm.preserveWhitespace,
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

  void setBindingsOverride(Type type, List<dynamic> bindings) {
    _providerOverrides[type] = bindings;
  }

  void setViewBindingsOverride(Type type, List<dynamic> viewBindings) {
    viewProviderOverrides[type] = viewBindings;
  }

  void setProvidersOverride(Type type, List<dynamic> providers) {
    _providerOverrides[type] = providers;
  }

  void setViewProvidersOverride(Type type, List<dynamic> viewProviders) {
    viewProviderOverrides[type] = viewProviders;
  }
}
