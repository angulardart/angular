import 'package:angular/src/core/di/decorators.dart';
import 'package:angular/src/facade/lang.dart';

import '../provider.dart';
import '../reflector.dart' as reflector;
import 'empty.dart';
import 'hierarchical.dart';
import 'injector.dart';

/// An injector that resolves provider instances with runtime information.
///
/// This type is only accessible internal to AngularDart.
class ReflectiveInjector extends HierarchicalInjector {
  // Cached instances of resolving a provider by token -> instance.
  final _instances = new Map.identity();

  // A pre-processed token -> `RuntimeProvider` mapping.
  final Map<Object, RuntimeProvider<dynamic>> _providers;
  final List<RuntimeProvider<dynamic>> _multiProviders;

  /// Creates a new [SlowInjector] by resolving [providersOrLists] at runtime.
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
    return new ReflectiveInjector._(
      flatProviders.providers,
      flatProviders.multiProviders,
      parent,
    );
  }

  ReflectiveInjector._(
    this._providers,
    this._multiProviders, [
    HierarchicalInjector parent,
  ])
      : super(parent) {
    assert(parent != null, 'A parent injector is always required.');
    // Injectors as a contract must return themselves if `Injector` is a token.
    _instances[Injector] = this;
  }

  /// Creates a new child reflective injector from [providersOrLists].
  ReflectiveInjector resolveAndCreateChild(List<Object> providersOrLists) {
    return resolveAndCreate(providersOrLists, this);
  }

  @override
  T inject<T>({
    Object token,
    OrElseInject<T> orElse: throwsNotFound,
  }) {
    return injectFromSelf(
      token,
      orElse: (_, token) {
        return injectFromAncestry(
          token,
          orElse: (_, token) => orElse(this, token),
        );
      },
    );
  }

  @override
  T injectFromSelf<T>(
    Object token, {
    OrElseInject<T> orElse: throwsNotFound,
  }) {
    // Look for a previously instantiated instance.
    var instance = _instances[token];
    // If not found (and was truly a cache miss) resolve and create one.
    if (instance == null && !_instances.containsKey(instance)) {
      final provider = _providers[token];
      // Provider not found, default to "orElse".
      if (provider == null) {
        return orElse(this, token);
      }
      // Resolve the provider and cache the instance.
      if (provider.multi) {
        instance = _resolveWithReflectorMulti(provider);
      } else {
        instance = _resolveWithReflector(provider);
      }
      _instances[token] = instance;
    }
    return instance;
  }

  @Deprecated('Unsupported, here for compatibility only. Remove usage.')
  dynamic resolveAndInstantiate(dynamic providerOrType) {
    RuntimeProvider<dynamic> provider;
    if (providerOrType is RuntimeProvider) {
      provider = providerOrType;
    } else if (providerOrType is Type) {
      provider = new Provider(
        providerOrType,
        useClass: providerOrType,
      );
    } else {
      throw new ArgumentError.value(providerOrType, 'providerOrType');
    }
    return _resolveWithReflector(provider);
  }

  // Returns the result of "resolving" [provider] at runtime.
  //
  // This "parses" [provider], and invokes the necessary code path in order to
  // get the concrete object that the user expects.
  dynamic _resolveWithReflector(RuntimeProvider<dynamic> provider) {
    // useValue.
    if (!identical(provider.useValue, noValueProvided)) {
      return provider.useValue;
    }
    // useClass or implicit useClass.
    Type useClass = provider.useClass;
    if (useClass == null && provider.token is Type) {
      useClass = provider.token;
    }
    // useFactory.
    if (provider.useFactory != null) {
      return _newInstanceOrInvoke(
        provider.useFactory,
        provider.dependencies,
      );
    }
    // useExisting (Redirect).
    if (provider.useExisting != null) {
      return inject(token: provider.useExisting);
    }
    assert(useClass != null, 'Only valid option is "useClass" here.');
    return _newInstanceOrInvoke(
      useClass,
      provider.dependencies,
    );
  }

  List<dynamic> _resolveWithReflectorMulti(RuntimeProvider<dynamic> provider) {
    final results = <dynamic>[];
    for (final multiProvider in _multiProviders) {
      if (identical(multiProvider.token, provider.token)) {
        results.add(_resolveWithReflector(multiProvider));
      }
    }
    return results;
  }

  // Creates a new instance of an object reflectively by invoking [typeOrFunc].
  dynamic _newInstanceOrInvoke(
    dynamic typeOrFunc,
    List<Object> diTokens,
  ) {
    diTokens ??= reflector.getDependencies(typeOrFunc);
    final factory =
        typeOrFunc is Function ? typeOrFunc : reflector.getFactory(typeOrFunc);
    final arguments = _resolveArguments(diTokens);
    return Function.apply(factory, arguments);
  }

  // Resolves and injects an instance for each set of [metadata].
  List<dynamic> _resolveArguments(List<Object> arguments) {
    final results = new List<Object>(arguments.length);
    for (var i = 0; i < arguments.length; i++) {
      final metadata = arguments[i];
      Object token;
      Object dependency;
      if (metadata is List) {
        token = metadata[0];
        if (token is Inject) {
          token = (token as Inject).token;
        }
        if (metadata.length == 1) {
          // Most common case: no "annotations" on this token.
          dependency = inject(token: token);
        } else {
          dependency = _resolveArgumentWithAnnotations(token, metadata);
        }
      } else {
        dependency = inject(token: metadata);
      }
      results[i] = dependency;
    }
    return results;
  }

  // Default `OrElseInject` implementation for backing @Optional().
  static Null _orElseNull(_, __) => null;

  // Iterates over the token metadata to call the appropriate injector method.
  dynamic _resolveArgumentWithAnnotations(Object token, List<Object> metadata) {
    var isOptional = false;
    var isSkipSelf = false;
    var isSelf = false;
    var isHost = false;
    for (var n = 1, l = metadata.length; n < l; n++) {
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
      }
    }
    // TODO(matanl): Assert that there is no invalid combination.
    final OrElseInject orElse = isOptional ? _orElseNull : throwsNotFound;
    if (isSkipSelf) {
      return injectFromAncestry<dynamic>(token, orElse: orElse);
    }
    if (isSelf) {
      return injectFromSelf<dynamic>(token, orElse: orElse);
    }
    if (isHost) {
      return injectFromParent<dynamic>(token, orElse: orElse);
    }
    return inject<dynamic>(token: token, orElse: orElse);
  }
}

class _FlatProviders {
  final Map<dynamic, RuntimeProvider<dynamic>> providers;
  final List<RuntimeProvider<dynamic>> multiProviders;

  const _FlatProviders(this.providers, this.multiProviders);
}

/// Creates a "flattened" linked hash map of all providers, keyed by token.
///
/// Walks [providersOrLists], recursively iterating where needed.
_FlatProviders _flattenProviders(
  List<dynamic> providersOrLists, [
  Map<dynamic, RuntimeProvider<dynamic>> allProviders,
  List<RuntimeProvider<dynamic>> multiProviders,
]) {
  allProviders ??= new Map<dynamic, RuntimeProvider<dynamic>>.identity();
  multiProviders ??= <RuntimeProvider<dynamic>>[];
  for (var i = 0, len = providersOrLists.length; i < len; i++) {
    final item = providersOrLists[i];
    if (item is List) {
      _flattenProviders(item, allProviders, multiProviders);
    } else if (item is RuntimeProvider) {
      if (item.multi) {
        multiProviders.add(item);
      }
      allProviders[item.token] = item;
    } else if (item is Type) {
      allProviders[item] = new Provider(item, useClass: item);
    } else {
      assert(false, 'Unsupported: ${item.runtimeType}');
    }
  }
  return new _FlatProviders(allProviders, multiProviders);
}

// When assertions enabled, verify that providers accessible (initReflector).
//
// This matches the old behavior of ReflectiveInjector (which eagerly resolved
// all providers), instead of letting teams introduce unresolvable providers.
void _assertProviders(Iterable<RuntimeProvider<dynamic>> providers) {
  for (final provider in providers) {
    if (provider.dependencies != null) {
      continue;
    }
    if (provider.useClass != null) {
      reflector.getFactory(provider.useClass);
    } else if (provider.useFactory != null) {
      reflector.getDependencies(provider.useFactory);
    } else if (provider.useFactory == noValueProvided &&
        provider.useExisting == null &&
        provider.token is Type) {
      reflector.getFactory(provider.token);
    }
  }
}
