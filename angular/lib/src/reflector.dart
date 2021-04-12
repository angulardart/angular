/// This library supports a limited form of runtime reflection.
///
/// In an ideal scenario, most or all projects would not need to import or use
/// this code. However, at least two classes (`SlowComponentLoader` and
/// `ReflectiveInjector`), are implemented using this library:
///
/// - `SlowComponentLoader` can be replaced incrementally via `ComponentLoader`.
/// - `ReflectiveInjector` can be replaced partially be either using the
///   `providers: [...]` field of an `@Component` or using the
///   `@GenerateInjector` to generate a standalone injector. Additionally, some
///   of the more "dynamic" elements of `ReflectiveInjector` can be satisfied
///   from a combination of `Injector.map` and potentially a limited form of
///   runtime injection (e.g. `ValueProvider` and `FactoryProvider`s that do not
///   need to lookup factories or dependencies using this library)
///
/// This library is additionally imported and referenced by the `.template.dart`
/// generator in order to generate an `initReflector()` statement, and as such
/// relies on a few exported symbols/classes (seen below as `export ...`).
///
/// **DO NOT USE**: The API of this library can and will change at any time.
library angular.src.reflector;

// Provides symbols easily accessible when importing this package, i.e.
//
// ```
// import 'package:angular/src/reflector.dart' as _reflector;
//
// void initReflector() {
//   _reflector.registerDependencies(const _reflector.OpaqueToken(...), [...]);
// }
// ```
//
export 'meta.dart'
    show Host, Inject, Optional, Self, SkipSelf, OpaqueToken, MultiToken;

// This would ideally be typed, but the lib/di.dart is used by some users in a
// VM environment where dart:html cannot be imported. Since the reflector is
// already considered the "slow" path, this isn't a regression.
//
// TODO(b/161737141): If `di.dart` is removed first, type this API.
final _components = <Object, Object /*ComponentFactory*/ >{};

/// Registers [component] as the static factory for [type].
///
/// This is done entirely to support `SlowComponentLoader`; applications may be
/// able to opt-out of generating this code if they do not use it.
///
/// TODO(b/161737141): If `di.dart` is removed first, type this API.
void registerComponent(Type type, Object /*ComponentFactory*/ component) {
  _components[type] = component;
}

/// Returns the static factory for [type].
///
/// TODO(b/161737141): If `di.dart` is removed first, type this API.
/*ComponentFactory*/ dynamic getComponent(Type type) {
  final component = _components[type];
  if (component == null) {
    throw StateError('Could not find a component factory for $type.');
  }
  return component;
}

final _factories = <Object, Function>{};

/// Registers [factory] as a factory function for [classtypeOrFunctionType].
///
/// This is done entirely to support `ReflectiveInjector`; applications may be
/// able to opt-out of generating this code if they do not use it.
void registerFactory(Object classtypeOrFunctionType, Function factory) {
  _factories[classtypeOrFunctionType] = factory;
}

/// Returns a factory function for creating [type].
Function getFactory(Type type) {
  final factory = _factories[type];
  if (factory == null) {
    if (_factories.isEmpty) {
      throw StateError(
        'Could not find a factory for $type, there were no factories of any '
        'type found. The likely causes is that you are using the newer '
        'runApp() semantics, which does not support runtime lookups of '
        'factories (and does not support ReflectiveInjector) *or* '
        'AngularDart code generation was never invoked (either due to a '
        'misconfiguration of Blaze or a missing invocation of '
        '`initReflector()` in your `main.dart`).',
      );
    } else {
      throw StateError(
        'Could not find a factory for $type. Either a provider was not set, '
        '*or*  AngularDart code generation was never invoked on the dependant  '
        'package containing $type.',
      );
    }
  }
  return factory;
}

final _dependencies = <Object, List<List<Object>>>{};

/// Registers [dependencies] as positional arguments for invoking [invokable].
///
/// A [_dependencies] list is expected in the form of:
/// ```dart
/// [
///   [typeOrToken, metadata, metadata, ..., metadata],
/// ],
/// ```
///
/// This is done entirely to support `ReflectiveInjector`; applications may be
/// able to opt-out of generating this code if they do not use it.
void registerDependencies(Object invokable, List<List<Object>> dependencies) {
  _dependencies[invokable] = dependencies;
}

/// Returns dependencies needed to invoke [object].
List<Object> getDependencies(Object object) {
  return _dependencies[object] ?? const <List<Object>>[];
}
