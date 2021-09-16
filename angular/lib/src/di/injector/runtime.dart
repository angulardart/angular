import 'package:angular/src/meta.dart';
import 'package:angular/src/reflector.dart' as reflector;
import 'package:angular/src/utilities.dart';
import 'package:meta/meta.dart';

import '../errors.dart' as errors;
import '../injector.dart';

const _globalSingletonServices = [
  'ApplicationRef',
  'NgZone',
];

/// An injector that resolves [Provider] instances with runtime information.
abstract class ReflectiveInjector implements Injector {
  /// Creates a new [Injector] that resolves `Provider` instances at runtime.
  ///
  /// This is an **expensive** operation without any sort of caching or
  /// optimizations that manually walks the nested [providersOrLists], and uses
  /// a form of runtime reflection to figure out how to map the providers to
  /// runnable code.
  ///
  /// Using this function can **disable all tree-shaking** for any `@Injectable`
  /// annotated function or class in your _entire_ transitive application, and
  /// is provided for legacy compatibility only.
  static ReflectiveInjector resolveAndCreate(
    List<Object> providersOrLists, [
    Injector? parent,
  ]) {
    // Return the default implementation.
    final flatProviders = _flattenProviders(providersOrLists);
    if (isDevMode) {
      _assertProviders(flatProviders.providers.values);
      _assertProviders(flatProviders.multiProviders);
      _assertGlobalSingletonService(flatProviders.providers.values);
      _assertGlobalSingletonService(flatProviders.multiProviders);
    }
    return _RuntimeInjector(
      flatProviders.providers,
      flatProviders.multiProviders,
      parent,
      false,
    );
  }

  /// Creates a new [Injector] that resolves some `Provider` instances.
  ///
  /// In particular, only the following provider types are now valid:
  /// * `ValueProvider` (or `Provider(useValue: ...)`)
  /// * `ExistingProvider` (or `Provider(useExisting: ...)`)
  /// * `FactoryProvider` (or `Provider(useFactory: ...)`) with `deps` provided.
  ///
  /// Specifically, any providers that require looking up factory functions or
  /// argument information for factory functions at runtime are not supported
  /// since they would defeat the tree-shaking improvements of "runApp".
  ///
  /// See https://github.com/angulardart/angular/issues/1426 for details.
  ///
  /// Any other type of [Provider] will throw during creation in development
  /// mode and may fail unexpectedly in production mode. This is to allow eased
  /// migration towards the `runApp` API without entirely giving up the ability
  /// to use the dynamic nature of [ReflectiveInjector].
  ///
  /// **WARNING**: This is not intended to be a long-term API, and instead is
  /// an _alternative_ to [ReflectiveInjector.resolveAndCreate]. It is greatly
  /// preferred to use `Injector.map` or `@GeneratedInjector` for new usages.
  @experimental
  static ReflectiveInjector resolveStaticAndCreate(
    List<Object> providersOrLists, [
    Injector? parent,
  ]) {
    final flatProviders = _flattenProviders(providersOrLists);
    if (isDevMode) {
      _assertStaticProviders(flatProviders.providers.values);
      _assertStaticProviders(flatProviders.multiProviders);
      _assertGlobalSingletonService(flatProviders.providers.values);
      _assertGlobalSingletonService(flatProviders.multiProviders);
    }
    return _RuntimeInjector(
      flatProviders.providers,
      flatProviders.multiProviders,
      parent,
      true,
    );
  }

  @Deprecated('Unsupported, here for compatibility only. Remove usage.')
  dynamic resolveAndInstantiate(Object providerOrType);

  /// Creates a new child reflective injector from [providersOrLists].
  ReflectiveInjector resolveAndCreateChild(List<Object> providersOrLists);
}

bool _isMultiProvider(Provider p) => p.token is MultiToken;

class _RuntimeInjector extends HierarchicalInjector
    implements ReflectiveInjector, RuntimeInjectorBuilder {
  // Cached instances of resolving a provider by token -> instance.
  final _instances = Map.identity();

  // A pre-processed token -> `RuntimeProvider` mapping.
  final Map<Object, Provider<Object>> _providers;
  final List<Provider<Object>> _multiProviders;
  final bool _staticOnlyResolveAndCreate;

  _RuntimeInjector(
    this._providers,
    this._multiProviders,
    Injector? parent,
    this._staticOnlyResolveAndCreate,
  ) : super(parent) {
    // Injectors as a contract must return themselves if `Injector` is a token.
    _instances[Injector] = this;
  }

  static const _inDartVM = !identical(1, 1.0);

  /// In the Dart VM, Type instances are not canonicalized across mixed-mode
  /// (e.g., a reference to a class from a library that is opted-in - and a
  /// reference to that same class from a library that is _not_ opted-in).
  ///
  /// Specifically, the benchpress/latency tests that ACX use, which currently
  /// run in the Dart VM and use AngularDart dependency injection, try to inject
  /// the token [Injector], but the types are no longer identical - and across
  /// DI and AngularDart more broadly we use [identical] and not `Object.==`.
  ///
  /// TODO(b/168902085): This is a one-off hack to fix latency tests for now.
  static Object _canonicalizeInjectorTypeToFixMixedModeVmTests(Object token) {
    return _inDartVM && Injector == token ? Injector : token;
  }

  @override
  Object? injectFromSelfOptional(
    Object token, [
    Object? orElse = throwIfNotFound,
  ]) {
    token = _canonicalizeInjectorTypeToFixMixedModeVmTests(token);
    // Look for a previously instantiated instance.
    var instance = _instances[token];
    // If not found (and was truly a cache miss) resolve and create one.
    if (instance == null && !_instances.containsKey(token)) {
      final provider = _providers[token];
      // Provider not found, default to "orElse".
      if (provider == null) {
        return orElse;
      }
      // Resolve the provider and cache the instance.
      if (_isMultiProvider(provider)) {
        return _instances[provider.token] = _resolveMulti(provider);
      }
      _instances[token] = instance = buildAtRuntime(provider, this);
    }
    return instance;
  }

  @override
  ReflectiveInjector resolveAndCreateChild(List<Object> providersOrLists) {
    if (_staticOnlyResolveAndCreate) {
      return ReflectiveInjector.resolveStaticAndCreate(providersOrLists, this);
    }
    return ReflectiveInjector.resolveAndCreate(providersOrLists, this);
  }

  @override
  dynamic resolveAndInstantiate(Object providerOrType) {
    final provider = providerOrType is Provider
        ? providerOrType
        : Provider(
            providerOrType,
            useClass: unsafeCast<Type>(providerOrType),
          );
    if (_staticOnlyResolveAndCreate) {
      _assertStaticProviders([provider]);
    }
    return buildAtRuntime(provider, this);
  }

  /// Given a list of arguments to a constructor of function, resolve them.
  ///
  /// i.e. in the format of:
  /// ```dart
  /// // Inject `FooType` optionally.
  /// _resolveArgs(token, [
  ///   [ FooType, const Optional() ],
  /// ])
  /// ```
  ///
  /// If [deps] are provided, they are used, otherwise the reflector is checked.
  List<Object?> _resolveArgs(Object token, [List<Object>? deps]) {
    deps ??= reflector.getDependencies(token);
    return [for (var i = 0, l = deps.length; i < l; i++) _resolveArg(deps[i])];
  }

  Object? _resolveArg(Object dependency) {
    if (dependency is List<Object>) {
      return _resolveMeta(dependency);
    }
    final result = get(dependency);
    // We don't check to see if this failed otherwise, because this is an
    // edge case where we just delegate to Function.apply to invoke a factory.
    if (identical(result, throwIfNotFound)) {
      return throwsNotFound(this, dependency);
    }
    return unsafeCast(result);
  }

  List<Object> _resolveMulti(Provider<Object> provider) {
    final results = listOfMultiToken(unsafeCast(provider.token));
    for (final other in _multiProviders) {
      if (identical(other.token, provider.token)) {
        results.add(buildAtRuntime(other, this));
      }
    }
    return results;
  }

  Object? _resolveMeta(List<Object> metadata) {
    late final Object token;
    var isOptional = false;
    var isSkipSelf = false;
    var isSelf = false;
    var isHost = false;
    for (var n = 0, l = metadata.length; n < l; n++) {
      final annotation = metadata[n];
      if (annotation is Inject) {
        token = annotation.token;
      } else if (annotation is Optional) {
        isOptional = true;
      } else if (annotation is SkipSelf) {
        isSkipSelf = true;
      } else if (annotation is Self) {
        isSelf = true;
      } else if (annotation is Host) {
        isHost = true;
      } else {
        token = annotation;
      }
    }
    Object? result;
    errors.debugInjectorEnter(token);
    final orElse = isOptional ? null : throwIfNotFound;
    if (isSkipSelf) {
      result = injectFromAncestryOptional(token, orElse);
    } else if (isSelf) {
      result = injectFromSelfOptional(token, orElse);
    } else if (isHost) {
      result = injectFromParentOptional(token, orElse);
    } else {
      result = provideUntyped(token, orElse);
    }
    if (identical(result, throwIfNotFound)) {
      throwsNotFound(this, token);
    }
    errors.debugInjectorLeave(token);
    return result;
  }

  @override
  Object useClass(Type clazz, {List<Object>? deps}) {
    final factory = reflector.getFactory(clazz);
    return unsafeCast(Function.apply(factory, _resolveArgs(clazz, deps)));
  }

  @override
  Object useExisting(Object token) => provideUntyped(token) as Object;

  @override
  Object useFactory(Function factory, {List<Object>? deps}) {
    final resolvedArgs = _resolveArgs(factory, deps);
    // This call will fail at runtime (a non-zero arg function w/ 1+ args).
    assert(
      _functionHasNoRequiredArguments(factory) || resolvedArgs.isNotEmpty,
      'Could not resolve dependencies for factory function $factory. This '
      'is is usually a sign of an omitted @Injectable. Consider migrating '
      'to @GeneratedInjector (and "runApp") or add the missing annotation '
      'for the time being.',
    );
    return unsafeCast(Function.apply(factory, resolvedArgs));
  }

  static bool _functionHasNoRequiredArguments(Function function) {
    return function is void Function();
  }

  @override
  Object useValue(Object value) => value;
}

class _FlatProviders {
  final Map<Object, Provider<Object>> providers;
  final List<Provider<Object>> multiProviders;

  const _FlatProviders(this.providers, this.multiProviders);
}

// When assertions enabled, verify that providers accessible (initReflector).
//
// This matches the old behavior of ReflectiveInjector (which eagerly resolved
// all providers), instead of letting teams introduce unresolvable providers.
void _assertProviders(Iterable<Provider<void>> providers) {
  for (final provider in providers) {
    final useClass = provider.useClass;
    if (useClass != null) {
      reflector.getFactory(useClass);
    } else {
      final useFactory = provider.useFactory;
      if (useFactory != null && provider.deps == null) {
        reflector.getDependencies(useFactory);
      } else if (identical(provider.useFactory, noValueProvided) &&
          provider.useExisting == null &&
          provider.token is Type) {
        reflector.getFactory(unsafeCast<Type>(provider.token));
      }
    }
  }
}

Never _throwUnsupportedProvider(Provider<void> provider) {
  throw UnsupportedError(
    'Could not create a provider for token "${provider.token}"!\n\n'
    'ReflectiveInjector.resolveStaticAndCreate only supports some providers.\n'
    '\n'
    '* FactoryProvider (or Provider(useFactory: ...)) with deps: [ ... ] set\n'
    '* ValueProvider (or Provider(useValue: ...))\n'
    '* ExistingProvider (or Provider(useExisting: ...))\n'
    '\n'
    'Specifically, any providers that require looking up factory functions or '
    'argument information for factory functions at runtime are not supported '
    'since they would defeat the tree-shaking improvements of "runApp".\n\n'
    'See https://github.com/angulardart/angular/issues/1426 for details',
  );
}

// When assertions enabled, verify that providers do not need initReflector.
//
// See https://github.com/angulardart/angular/issues/1426.
void _assertStaticProviders(Iterable<Provider<void>> providers) {
  for (final provider in providers) {
    // ValueProvider or Provider(useValue: ...) is fine.
    if (!identical(provider.useValue, noValueProvided)) {
      continue;
    }
    // ExistingProvider or Provider(useExisting: ...) is fine.
    if (!identical(provider.useExisting, null)) {
      continue;
    }
    // FactoryProvider or Provider(useFactory: ...) with deps is fine.
    if (!identical(provider.useFactory, noValueProvided)) {
      if (provider.deps != null) {
        continue;
      }
    }
    _throwUnsupportedProvider(provider);
  }
}

void _assertGlobalSingletonService(Iterable<Provider<void>> providers) {
  for (final provider in providers) {
    final tokenName = '${provider.token}';
    if (_globalSingletonServices.contains(tokenName)) {
      // Error message copied from .../cli/messages/messages.dart to avoid
      // circular dependency.
      throw UnsupportedError(
          '"$tokenName" is an app-wide, singleton service provided by the '
          'framework that cannot be overridden or manually provided.\n'
          '\n'
          'If you are providing this service to fix a missing provider error, '
          'you likely have created an injector that is disconnected from the '
          "app's injector hierarchy. This can occur when instantiating an "
          'injector and you omit the parent injector argument, or explicitly '
          'configure an empty parent injector. Please check your injector '
          "constructors to make sure the current context's injector is passed "
          'as the parent.\n'
          '\n'
          'If you are instead providing this service in order to unit test an '
          'injector, please see http://go/angulardart/style/testing.');
    }
  }
}

/// Creates a "flattened" linked hash map of all providers, keyed by token.
///
/// Walks [providersOrLists], recursively iterating where needed.
_FlatProviders _flattenProviders(
  List<Object> providersOrLists, [
  Map<Object, Provider<Object>>? allProviders,
  List<Provider<Object>>? multiProviders,
]) {
  allProviders ??= Map.identity();
  multiProviders ??= [];
  for (var i = 0, len = providersOrLists.length; i < len; i++) {
    final item = providersOrLists[i];
    if (item is List<Object>) {
      _flattenProviders(item, allProviders, multiProviders);
    } else if (item is Provider) {
      if (_isMultiProvider(item)) {
        multiProviders.add(item);
      }
      // Even if `item` is a multi provider, we still add it to the map of
      // regular providers to indicate that a multi provider for that token
      // exists.
      allProviders[item.token] = item;
    } else if (item is Type) {
      allProviders[item] = Provider(item, useClass: item);
    } else if (item is Module) {
      final providers = internalModuleToList(item);
      _flattenProviders(providers, allProviders, multiProviders);
    } else {
      assert(false, 'Unsupported: $item');
    }
  }
  return _FlatProviders(allProviders, multiProviders);
}
