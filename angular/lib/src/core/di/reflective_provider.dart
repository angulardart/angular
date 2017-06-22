import 'package:angular/src/core/reflection/reflection.dart'
    show reflector, NoReflectionCapabilitiesError;
import 'package:angular/src/facade/lang.dart' show assertionsEnabled;

import '../metadata.dart';
import 'decorators.dart';
import 'provider.dart' show Provider, noValueProvided;
import 'reflective_exceptions.dart'
    show
        NoAnnotationError,
        MixingMultiProvidersWithRegularProvidersError,
        InvalidProviderError;
import 'reflective_key.dart';

/// [Dependency] is used by the framework to extend DI.
/// This is internal to Angular and should not be used directly.
class ReflectiveDependency {
  final ReflectiveKey key;
  final bool optional;
  final dynamic lowerBoundVisibility;
  final dynamic upperBoundVisibility;
  final List properties;
  ReflectiveDependency(this.key, this.optional, this.lowerBoundVisibility,
      this.upperBoundVisibility, this.properties);
  static ReflectiveDependency fromKey(ReflectiveKey key) {
    return new ReflectiveDependency(key, false, null, null, const []);
  }
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

  ResolvedReflectiveFactory get resolvedFactory => resolvedFactories.first;
}

/// An internal resolved representation of a factory function created by
/// resolving [Provider].
class ResolvedReflectiveFactory {
  final Function factory;
  final List<ReflectiveDependency> dependencies;

  /// Constructs a resolved factory.
  ///
  /// [factory] returns an instance of an object represented by a key.
  ///
  /// [dependencies] is a list of dependencies passed to [factory] as
  /// parameters.
  ResolvedReflectiveFactory(this.factory, this.dependencies);
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
    if (assertionsEnabled()) {
      try {
        resolvedDeps = constructDependencies(
          provider.useFactory,
          provider.dependencies,
        );
      } on NoReflectionCapabilitiesError catch (e, s) {
        // When assertions are enabled, we want to expand this error message
        // to have lots of information about the provider so our users can debug
        // and fix the problem.
        var description =
            '$Provider {${provider.token} useFactory: ${provider.useFactory}}';
        throw new NoReflectionCapabilitiesError.debug(
          ''
              'Attempted to use reflection to resolve $description, and failed'
              '\n'
              '\n'
              'Stack trace: $s',
        );
      }
    } else {
      // In production mode, we just directly call this and assume it will work.
      resolvedDeps = constructDependencies(
        provider.useFactory,
        provider.dependencies,
      );
    }
  } else {
    var useClass = provider.useClass;
    if (useClass != null) {
      factoryFn = reflector.factory(useClass);
      resolvedDeps = _dependenciesFor(useClass);
    } else {
      var useValue = provider.useValue;
      if (useValue != noValueProvided) {
        factoryFn = () => useValue;
        resolvedDeps = const <ReflectiveDependency>[];
      } else if (provider.token is Type) {
        var useClass = provider.token;
        factoryFn = reflector.factory(useClass);
        resolvedDeps = _dependenciesFor(useClass);
      } else {
        throw new InvalidProviderError.withCustomMessage(
            provider, 'token is not a Type and no factory was specified');
      }
    }
  }
  return new ResolvedReflectiveFactory(factoryFn, resolvedDeps);
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
  var resolved = <ResolvedReflectiveProvider>[];
  for (int i = 0, len = normalized.length; i < len; i++) {
    resolved.add(resolveReflectiveProvider(normalized[i]));
  }
  return mergeResolvedReflectiveProviders(resolved);
}

/// Merges a list of ResolvedProviders into a list where
/// each key is contained exactly once and multi providers
/// have been merged.
List<ResolvedReflectiveProvider> mergeResolvedReflectiveProviders(
    List<ResolvedReflectiveProvider> providers) {
  // Map used to dedup by provider key id.
  var idToProvider = <num, ResolvedReflectiveProvider>{};
  for (var i = 0, len = providers.length; i < len; i++) {
    var provider = providers[i];
    var existing = idToProvider[provider.key.id];
    if (existing != null) {
      if (!identical(provider.multiProvider, existing.multiProvider)) {
        throw new MixingMultiProvidersWithRegularProvidersError(
            existing, provider);
      }
      if (provider.multiProvider) {
        var factories = provider.resolvedFactories;
        for (var j = 0, len = factories.length; j < len; j++) {
          existing.resolvedFactories.add(provider.resolvedFactories[j]);
        }
      } else {
        idToProvider[provider.key.id] = provider;
      }
    } else {
      var resolvedProvider;
      if (provider.multiProvider) {
        resolvedProvider = new ResolvedReflectiveProviderImpl(provider.key,
            new List.from(provider.resolvedFactories), provider.multiProvider);
      } else {
        resolvedProvider = provider;
      }
      idToProvider[provider.key.id] = resolvedProvider;
    }
  }
  return idToProvider.values.toList();
}

// Flattens list of lists of providers into a flat list. If any entry is a
// Type it converts it to a useClass provider.
List<Provider> _normalizeProviders(
    List<dynamic /* Type | Provider | List < dynamic > */ > providers,
    List<Provider> res) {
  for (int i = 0, len = providers.length; i < len; i++) {
    var b = providers[i];
    if (b is Type) {
      // If user listed a Type in provider list create Provide useClass: for it.
      // This is a shortcut to make provider lists easier to create.
      res.add(new Provider(b, useClass: b));
    } else if (b is Provider) {
      res.add(b);
    } else if (b is List) {
      _normalizeProviders(b, res);
    } else {
      throw new InvalidProviderError(b);
    }
  }
  return res;
}

List<ReflectiveDependency> constructDependencies(
    dynamic typeOrFunc, List<dynamic> dependencies) {
  if (dependencies == null) {
    return _dependenciesFor(typeOrFunc);
  } else {
    var deps = <ReflectiveDependency>[];
    for (int i = 0, len = dependencies.length; i < len; i++) {
      deps.add(_extractTokenUnwrappedParameters(
          typeOrFunc, dependencies[i], dependencies));
    }
    return deps;
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

// Same as _extractToken but doesn't expect list wrapped parameters. This is
// to reduce GC by eliminating list allocations for each parameter.
ReflectiveDependency _extractTokenUnwrappedParameters(
    typeOrFunc, metadata, List<dynamic> params) {
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
  if (token == null) {
    // Since we have rare failure, wrap parameter types into a format that
    // NoAnnotationError expects in reflective mode.
    var paramList = <List<dynamic>>[];
    for (var param in params) {
      paramList.add([param]);
    }
    throw new NoAnnotationError(typeOrFunc, params);
  }
  return _createDependency(
      token, optional, lowerBoundVisibility, upperBoundVisibility, depProps);
}

ReflectiveDependency _createDependency(
    token, optional, lowerBoundVisibility, upperBoundVisibility, depProps) {
  return new ReflectiveDependency(ReflectiveKey.get(token), optional,
      lowerBoundVisibility, upperBoundVisibility, depProps);
}
