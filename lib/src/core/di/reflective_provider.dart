import "package:angular2/src/core/reflection/reflection.dart" show reflector;

import '../reflection/reflection.dart' show NoReflectionCapabilitiesError;
import '../metadata.dart';
import "decorators.dart";
import "provider.dart" show Provider, provide, noValueProvided;
import "reflective_exceptions.dart"
    show
        NoAnnotationError,
        MixingMultiProvidersWithRegularProvidersError,
        InvalidProviderError;
import "reflective_key.dart";

/// [Dependency] is used by the framework to extend DI.
/// This is internal to Angular and should not be used directly.
class ReflectiveDependency {
  ReflectiveKey key;
  bool optional;
  dynamic lowerBoundVisibility;
  dynamic upperBoundVisibility;
  List<dynamic> properties;
  ReflectiveDependency(this.key, this.optional, this.lowerBoundVisibility,
      this.upperBoundVisibility, this.properties);
  static ReflectiveDependency fromKey(ReflectiveKey key) {
    return new ReflectiveDependency(key, false, null, null, []);
  }
}

dynamic _identityPostProcess(obj) {
  return obj;
}

/// An internal resolved representation of a [Provider] used by the [Injector].
///
/// It is usually created automatically by `Injector.resolveAndCreate`.
///
/// It can be created manually, as follows:
///
/// Example:
///
///     var resolvedProviders = Injector.resolve([provide('message', useValue: 'Hello')]);
///     var injector = Injector.fromResolvedProviders(resolvedProviders);
///     expect(injector.get('message')).toEqual('Hello');
///
abstract class ResolvedReflectiveProvider {
  /// A key, usually a [Type].
  ReflectiveKey key;

  /// Return instances of objects for the given [key].
  List<ResolvedReflectiveFactory> resolvedFactories;

  /// Indicates if the provider is a multi-provider or a regular provider.
  bool multiProvider;
}

/// See [ResolvedProvider] instead.
abstract class ResolvedReflectiveBinding implements ResolvedReflectiveProvider {
}

class ResolvedReflectiveProviderImpl implements ResolvedReflectiveBinding {
  ReflectiveKey key;
  List<ResolvedReflectiveFactory> resolvedFactories;
  bool multiProvider;
  ResolvedReflectiveProviderImpl(
      this.key, this.resolvedFactories, this.multiProvider);
  ResolvedReflectiveFactory get resolvedFactory {
    return this.resolvedFactories[0];
  }
}

/// An internal resolved representation of a factory function created by
/// resolving [Provider].
class ResolvedReflectiveFactory {
  Function factory;
  List<ReflectiveDependency> dependencies;
  Function postProcess;

  /// Constructs a resolved factory.
  ///
  /// [factory] returns an instance of an object represented by a key.
  ///
  /// [dependencies] is a list of dependencies passed to [factory] as
  /// parameters.
  ///
  /// [postProcess] function is applied to the value constructed by [factory].
  ResolvedReflectiveFactory(this.factory, this.dependencies, this.postProcess);
}

/// Resolve a single provider.
ResolvedReflectiveFactory resolveReflectiveFactory(Provider provider) {
  Function factoryFn;
  List<ReflectiveDependency> resolvedDeps;
  if (provider.useExisting != null) {
    factoryFn = (aliasInstance) => aliasInstance;
    resolvedDeps = [
      ReflectiveDependency.fromKey(ReflectiveKey.get(provider.useExisting))
    ];
  } else if (provider.useFactory != null) {
    factoryFn = provider.useFactory;
    resolvedDeps =
        constructDependencies(provider.useFactory, provider.dependencies);
  } else if (provider.useClass != null) {
    var useClass = provider.useClass;
    factoryFn = reflector.factory(useClass);
    resolvedDeps = _dependenciesFor(useClass);
  } else if (provider.useValue != noValueProvided) {
    factoryFn = () => provider.useValue;
    resolvedDeps = const <ReflectiveDependency>[];
  } else if (provider.token is Type) {
    var useClass = provider.token;
    factoryFn = reflector.factory(useClass);
    resolvedDeps = _dependenciesFor(useClass);
  } else {
    throw new InvalidProviderError.withCustomMessage(
        provider, 'token is not a Type and no factory was specified');
  }

  var postProcess = provider.useProperty != null
      ? reflector.getter(provider.useProperty)
      : _identityPostProcess;
  return new ResolvedReflectiveFactory(factoryFn, resolvedDeps, postProcess);
}

/// Converts the [Provider] into [ResolvedProvider].
///
/// [Injector] internally only uses [ResolvedProvider], [Provider] contains
/// convenience provider syntax.
ResolvedReflectiveProvider resolveReflectiveProvider(Provider provider) {
  return new ResolvedReflectiveProviderImpl(ReflectiveKey.get(provider.token),
      [resolveReflectiveFactory(provider)], provider.multi);
}

/// Resolve a list of Providers.
List<ResolvedReflectiveProvider> resolveReflectiveProviders(
    List<dynamic /* Type | Provider | List < dynamic > */ > providers) {
  var normalized = _normalizeProviders(providers, []);
  var resolved = normalized.map(resolveReflectiveProvider).toList();
  return mergeResolvedReflectiveProviders(
          resolved, new Map<num, ResolvedReflectiveProvider>())
      .values
      .toList();
}

/// Merges a list of ResolvedProviders into a list where
/// each key is contained exactly once and multi providers
/// have been merged.
Map<num, ResolvedReflectiveProvider> mergeResolvedReflectiveProviders(
    List<ResolvedReflectiveProvider> providers,
    Map<num, ResolvedReflectiveProvider> normalizedProvidersMap) {
  for (var i = 0; i < providers.length; i++) {
    var provider = providers[i];
    var existing = normalizedProvidersMap[provider.key.id];
    if (existing != null) {
      if (!identical(provider.multiProvider, existing.multiProvider)) {
        throw new MixingMultiProvidersWithRegularProvidersError(
            existing, provider);
      }
      if (provider.multiProvider) {
        for (var j = 0; j < provider.resolvedFactories.length; j++) {
          existing.resolvedFactories.add(provider.resolvedFactories[j]);
        }
      } else {
        normalizedProvidersMap[provider.key.id] = provider;
      }
    } else {
      var resolvedProvider;
      if (provider.multiProvider) {
        resolvedProvider = new ResolvedReflectiveProviderImpl(provider.key,
            new List.from(provider.resolvedFactories), provider.multiProvider);
      } else {
        resolvedProvider = provider;
      }
      normalizedProvidersMap[provider.key.id] = resolvedProvider;
    }
  }
  return normalizedProvidersMap;
}

List<Provider> _normalizeProviders(
    List<dynamic /* Type | Provider | List < dynamic > */ > providers,
    List<Provider> res) {
  providers.forEach((b) {
    if (b is Type) {
      res.add(provide(b, useClass: b));
      _normalizeProviders(getInjectorModuleProviders(b), res);
    } else if (b is Provider) {
      res.add(b);
      _normalizeProviders(getInjectorModuleProviders(b.token), res);
    } else if (b is List) {
      _normalizeProviders(b, res);
    } else {
      throw new InvalidProviderError(b);
    }
  });
  return res;
}

List<ReflectiveDependency> constructDependencies(
    dynamic typeOrFunc, List<dynamic> dependencies) {
  if (dependencies == null) {
    return _dependenciesFor(typeOrFunc);
  } else {
    List<List<dynamic>> params = dependencies.map((t) => [t]).toList();
    return dependencies
        .map((t) => _extractToken(typeOrFunc, t, params))
        .toList();
  }
}

List<ReflectiveDependency> _dependenciesFor(dynamic typeOrFunc) {
  var params = reflector.parameters(typeOrFunc);
  var deps = <ReflectiveDependency>[];
  if (params != null) {
    int paramCount = params.length;
    for (int p = 0; p < paramCount; p++) {
      var param = params[p];
      if (param == null) throw new NoAnnotationError(typeOrFunc, params);
      ReflectiveDependency dep = _extractToken(typeOrFunc, param, params);
      deps.add(dep);
    }
  }
  return deps;
}

ReflectiveDependency _extractToken(
    typeOrFunc, metadata, List<List<dynamic>> params) {
  var depProps = [];
  var token;
  var optional = false;
  if (metadata is! List) {
    if (metadata is Inject) {
      return _createDependency(metadata.token, optional, null, null, depProps);
    } else {
      return _createDependency(metadata, optional, null, null, depProps);
    }
  }
  var lowerBoundVisibility;
  var upperBoundVisibility;
  for (var i = 0; i < metadata.length; ++i) {
    var paramMetadata = metadata[i];
    if (paramMetadata is Type) {
      token = paramMetadata;
    } else if (paramMetadata is Inject) {
      token = paramMetadata.token;
    } else if (paramMetadata is Optional) {
      optional = true;
    } else if (paramMetadata is Self) {
      upperBoundVisibility = paramMetadata;
    } else if (paramMetadata is Host) {
      upperBoundVisibility = paramMetadata;
    } else if (paramMetadata is SkipSelf) {
      lowerBoundVisibility = paramMetadata;
    } else if (paramMetadata is DependencyMetadata) {
      if (paramMetadata.token != null) {
        token = paramMetadata.token;
      }
      depProps.add(paramMetadata);
    }
  }
  if (token == null) throw new NoAnnotationError(typeOrFunc, params);
  return _createDependency(
      token, optional, lowerBoundVisibility, upperBoundVisibility, depProps);
}

ReflectiveDependency _createDependency(
    token, optional, lowerBoundVisibility, upperBoundVisibility, depProps) {
  return new ReflectiveDependency(ReflectiveKey.get(token), optional,
      lowerBoundVisibility, upperBoundVisibility, depProps);
}

/// Returns [InjectorModule] providers for a given token if possible.
List getInjectorModuleProviders(dynamic token) {
  var providers = [];
  List<dynamic> annotations;
  try {
    if (token is Type) {
      annotations = reflector.annotations(token);
    }
  } on NoReflectionCapabilitiesError {
    // ignoring reflection errors here
  }
  InjectorModule metadata = annotations != null
      ? annotations.firstWhere((type) => type is InjectorModule,
          orElse: () => null)
      : null;
  if (metadata != null) {
    var propertyMetadata = reflector.propMetadata(token);
    providers.addAll(metadata.providers);
    propertyMetadata.forEach((String propName, List<dynamic> metadata) {
      metadata.forEach((a) {
        if (a is ProviderProperty) {
          providers.add(new Provider(a.token,
              multi: a.multi, useProperty: propName, useExisting: token));
        }
      });
    });
  }
  return providers;
}
