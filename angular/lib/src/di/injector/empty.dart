import 'package:meta/meta.dart';

import 'hierarchical.dart';
import 'injector.dart';

/// Implements a simple injector that always delegates to the parent or throws.
///
/// **INTERNAL ONLY**: Use [Injector.empty] to create this class.
@Immutable()
class EmptyInjector extends HierarchicalInjector {
  @protected
  const EmptyInjector([HierarchicalInjector parent]) : super.maybeEmpty(parent);

  @override
  T injectFromSelf<T>(
    Object token, {
    OrElseInject<T> orElse: throwsNotFound,
  }) =>
      identical(token, Injector) ? this : orElse(this, token);

  @override
  T injectFromParent<T>(
    Object token, {
    OrElseInject<T> orElse: throwsNotFound,
  }) =>
      parent?.injectFromSelf(token, orElse: orElse) ?? orElse(this, token);

  @override
  T injectFromAncestry<T>(
    Object token, {
    OrElseInject<T> orElse: throwsNotFound,
  }) =>
      parent?.inject(token: token, orElse: orElse) ?? orElse(this, token);
}
