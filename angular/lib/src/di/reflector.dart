// The goal of this library is to support limited runtime reflection.
//
// In an ideal scenario, most or all projects would not need to import or use
// this code. However, at least two classes (SlowComponentLoader and
// ReflectiveInjector), are implemented using limited runtime reflection.
//
// * SlowComponentLoader can be replaced incrementally with ComponentLoader.
// * ReflectiveInjector can be replaced partially by a generated Injector; some
//   of the more "dynamic" elements of ReflectiveInjector can be satisfied from
//   a combination of `Injector.map` and potentially a limited form of runtime
//   injection.
//
// **DO NOT USE**: The API of this library can and will change at any time.
import 'package:angular/src/runtime.dart';
export '../core/di/decorators.dart' show Host, Inject, Optional, Self, SkipSelf;
export '../core/di/opaque_token.dart' show OpaqueToken;

// This would ideally be typed, but the lib/di.dart is used by some users in a
// VM environment where dart:html cannot be imported. Since the reflector is
// already considered the "slow" path, this isn't a regression.
final _components = <Object, dynamic /*ComponentFactory*/ >{};

/// May be overridden by legacy clients of AngularDart.
///
/// Otherwise, `ComponentRef.componentType` always returns throws.
Type Function(Object instance) runtimeTypeProvider = _nullTypeProvider;

Type _nullTypeProvider(Object _) {
  // In debug mode give a better error message.
  assert(
      false,
      ''
      'This feature is no longer supported in AngularDart due to '
      'the effects it has on code-size for highly optimized/size sensitive '
      'applications.');
  throw new UnsupportedError('');
}

/// Registers [component] as the static factory for [type].
///
/// This is done entirely to support `SlowComponentLoader`; applications may be
/// able to opt-out of generating this code if they do not use it.
void registerComponent(Type type, dynamic /*ComponentFactory*/ component) {
  _components[type] = component;
}

/// Returns the static factory for [type].
/*ComponentFactory*/ dynamic getComponent(Type type) {
  final component = _components[type];
  if (isDevMode && component == null) {
    throw new StateError('Could not find a component factory for $type.');
  }
  return component;
}

final _factories = <Object, Function>{};

/// Registers [factory] as a factory function for creating [typeOrFunc].
///
/// This is done entirely to support `ReflectiveInjector`; applications may be
/// able to opt-out of generating this code if they do not use it.
void registerFactory(Object typeOrFunc, Function factory) {
  _factories[typeOrFunc] = factory;
}

/// Returns a factory function for creating [type].
Function getFactory(Type type) {
  final factory = _factories[type];
  if (isDevMode && factory == null) {
    if (_factories.isEmpty) {
      throw new StateError(
          'Could not find a factory for $type, there were no factories of any '
          'type found. The likely causes is that you are using the newer '
          'runApp() semantics, which does not support runtime lookups of '
          'factories (and does not support ReflectiveInjector) *or* '
          'AngularDart code generation was never invoked (either due to a '
          'mis-configuration of Bazel or Build Runner or a missing invocation '
          'of `initReflector()` in your `main.dart`).');
    }
    throw new StateError('Could not find a factory for $type.');
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
