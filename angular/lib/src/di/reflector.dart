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
import 'package:angular/src/core/linker/component_factory.dart';

final _components = <Object, ComponentFactory>{};

/// Registers [component] as the static factory for [type].
///
/// This is done entirely to support `SlowComponentLoader`; applications may be
/// able to opt-out of generating this code if they do not use it.
void registerComponent(Type type, ComponentFactory component) {
  _components[type] = component;
}

/// Returns the static factory for [type].
ComponentFactory getComponent(Type type) {
  final component = _components[type];
  assert(component != null, 'Could not find a component factory for $type.');
  return component;
}

final _factories = <Type, Function>{};

/// Registers [factory] as a factory function for creating [type].
///
/// This is done entirely to support `ReflectiveInjector`; applications may be
/// able to opt-out of generating this code if they do not use it.
void registerFactory(Type type, Function factory) => _factories[type] = factory;

/// Returns a factory function for creating [type].
Function getFactory(Type type) {
  final factory = _factories[type];
  assert(factory != null, 'Could not find a factory for $type.');
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
List<List<Object>> getDependencies(Object object) {
  final dependencies = _dependencies[object];
  assert(dependencies != null, 'Could not find dependencies for $object.');
  return dependencies;
}
