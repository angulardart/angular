import 'package:angular/src/runtime.dart';

import '../../core/di/decorators.dart';
import '../../core/di/opaque_token.dart';
import '../../facade/lang.dart' show assertionsEnabled;
import '../errors.dart' as errors;
import '../providers.dart';
import '../reflector.dart' as reflector;

import 'empty.dart';
import 'hierarchical.dart';
import 'injector.dart';

/// An injector that resolves [Provider] instances with runtime information.
abstract class ReflectiveInjector implements HierarchicalInjector {
  /// Create a new [RuntimeInjector] by resolving [providersOrLists] at runtime.
  static ReflectiveInjector resolveAndCreate(
    List<Object> providersOrLists, [
    HierarchicalInjector parent = const EmptyInjector(),
  ]) {
    // Return the default implementation.
    final flatProviders = _flattenProviders(providersOrLists);
    if (assertionsEnabled()) {
      _assertProviders(flatProviders.providers.values);
      _assertProviders(flatProviders.multiProviders);
    }
    return new _RuntimeInjector(
      flatProviders.providers,
      flatProviders.multiProviders,
      parent,
    );
  }

  @Deprecated('Unsupported, here for compatibility only. Remove usage.')
  dynamic resolveAndInstantiate(dynamic providerOrType);

  /// Creates a new child reflective injector from [providersOrLists].
  ReflectiveInjector resolveAndCreateChild(List<Object> providersOrLists);
}

bool _isMultiProvider(Provider p) => p.multi == true || p.token is MultiToken;

class _RuntimeInjector extends HierarchicalInjector
    implements ReflectiveInjector, RuntimeInjectorBuilder {
  // Cached instances of resolving a provider by token -> instance.
  final _instances = new Map.identity();

  // A pre-processed token -> `RuntimeProvider` mapping.
  final Map<Object, Provider<Object>> _providers;
  final List<Provider<Object>> _multiProviders;

  _RuntimeInjector(
    this._providers,
    this._multiProviders,
    HierarchicalInjector parent,
  )
      : super(parent) {
    assert(parent != null, 'A parent injector is always required.');
    // Injectors as a contract must return themselves if `Injector` is a token.
    _instances[Injector] = this;
  }

  @override
  Object injectFromSelfOptional(
    Object token, [
    Object orElse = throwIfNotFound,
  ]) {
    // Look for a previously instantiated instance.
    var instance = _instances[token];
    // If not found (and was truly a cache miss) resolve and create one.
    if (instance == null && !_instances.containsKey(instance)) {
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
    return ReflectiveInjector.resolveAndCreate(providersOrLists, this);
  }

  @override
  dynamic resolveAndInstantiate(dynamic providerOrType) {
    final provider = providerOrType is Provider
        ? providerOrType
        : new Provider(
            providerOrType,
            useClass: unsafeCast<Type>(providerOrType),
          );
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
  List<Object> _resolveArgs(Object token, [List<Object> deps]) {
    deps ??= reflector.getDependencies(token);
    final resolved = new List(deps.length);
    for (var i = 0, l = resolved.length; i < l; i++) {
      final dep = deps[i];
      Object result;
      if (dep is List) {
        result = _resolveMeta(dep);
      } else {
        errors.debugInjectorEnter(dep);
        result = inject(dep);
        errors.debugInjectorLeave(dep);
      }
      // We don't check to see if this failed otherwise, because this is an
      // edge case where we just delegate to Function.apply to invoke a factory.
      if (identical(result, throwIfNotFound)) {
        return throwsNotFound(this, dep);
      }
      resolved[i] = result;
    }
    return resolved;
  }

  List<Object> _resolveMulti(Provider<Object> provider) {
    final results = listOfMulti(provider);
    for (final other in _multiProviders) {
      if (identical(other.token, provider.token)) {
        results.add(buildAtRuntime(other, this));
      }
    }
    return results;
  }

  Object _resolveMeta(List<Object> metadata) {
    Object token;
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
    // TODO(matanl): Assert that there is no invalid combination.
    Object result;
    errors.debugInjectorEnter(token);
    final orElse = isOptional ? null : throwIfNotFound;
    if (isSkipSelf) {
      result = injectFromAncestryOptional(token, orElse);
    } else if (isSelf) {
      result = injectFromSelfOptional(token, orElse);
    } else if (isHost) {
      result = injectFromParentOptional(token, orElse);
    } else {
      result = injectOptional(token, orElse);
    }
    if (identical(result, throwIfNotFound)) {
      throwsNotFound(this, token);
    }
    errors.debugInjectorLeave(token);
    return result;
  }

  @override
  Object useClass(Type clazz, {List<Object> deps}) {
    final factory = reflector.getFactory(clazz);
    return Function.apply(factory, _resolveArgs(clazz, deps));
  }

  @override
  Object useExisting(Object to) => inject(to);

  @override
  Object useFactory(Function factory, {List<Object> deps}) {
    return Function.apply(factory, _resolveArgs(factory, deps));
  }

  @override
  Object useValue(Object value) => value;
}

class _FlatProviders {
  final Map<dynamic, Provider<Object>> providers;
  final List<Provider<Object>> multiProviders;

  const _FlatProviders(this.providers, this.multiProviders);
}

// When assertions enabled, verify that providers accessible (initReflector).
//
// This matches the old behavior of ReflectiveInjector (which eagerly resolved
// all providers), instead of letting teams introduce unresolvable providers.
void _assertProviders(Iterable<Provider<Object>> providers) {
  for (final provider in providers) {
    if (provider.deps != null) {
      continue;
    }
    if (provider.useClass != null) {
      reflector.getFactory(provider.useClass);
    } else if (provider.useFactory != null) {
      reflector.getDependencies(provider.useFactory);
    } else if (provider.useFactory == noValueProvided &&
        provider.useExisting == null &&
        provider.token is Type) {
      reflector.getFactory(unsafeCast<Type>(provider.token));
    }
  }
}

/// Creates a "flattened" linked hash map of all providers, keyed by token.
///
/// Walks [providersOrLists], recursively iterating where needed.
_FlatProviders _flattenProviders(
  List<Object> providersOrLists, [
  Map<Object, Provider<Object>> allProviders,
  List<Provider<Object>> multiProviders,
]) {
  allProviders ??= new Map<Object, Provider<Object>>.identity();
  multiProviders ??= <Provider<Object>>[];
  for (var i = 0, len = providersOrLists.length; i < len; i++) {
    final item = providersOrLists[i];
    if (item is List) {
      _flattenProviders(item, allProviders, multiProviders);
    } else if (item is Provider) {
      if (_isMultiProvider(item)) {
        multiProviders.add(item);
      }
      allProviders[item.token] = item;
    } else if (item is Type) {
      allProviders[item] = new Provider(item, useClass: item);
    } else {
      assert(false, 'Unsupported: $item');
    }
  }
  return new _FlatProviders(allProviders, multiProviders);
}
