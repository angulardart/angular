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
  ])
      : super(parent);

  @override
  T injectFromSelf<T>(
    Object token, {
    OrElseInject<T> orElse: throwsNotFound,
  }) =>
      _providers[token] ??
      (identical(token, Injector) ? this : orElse(this, token));
}
