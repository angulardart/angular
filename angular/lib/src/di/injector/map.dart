import 'package:meta/meta.dart';

import 'empty.dart';
import 'hierarchical.dart';
import 'injector.dart';

/// Implements a simple injector backed by a [Map] of predefined values.
///
/// **INTERNAL ONLY**: Use [Injector.map] to create this class.
@Immutable()
class MapInjector extends HierarchicalInjector {
  final Map<Object, Object> _providers;

  const MapInjector(
    this._providers, [
    HierarchicalInjector parent = const EmptyInjector(),
  ]) : super(parent);

  @override
  Object injectFromSelfOptional(
    Object token, [
    Object orElse = throwIfNotFound,
  ]) {
    var result = _providers[token];
    if (result == null) {
      if (identical(token, Injector)) {
        return this;
      }
      result = orElse;
    }
    return result;
  }
}
