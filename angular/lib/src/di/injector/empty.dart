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
  Object injectFromSelfOptional(
    Object token, [
    Object orElse = throwIfNotFound,
  ]) =>
      identical(token, Injector) ? this : orElse;

  @override
  Object injectFromParentOptional(
    Object token, [
    Object orElse = throwIfNotFound,
  ]) {
    if (parent == null) {
      return orElse;
    }
    return parent.injectFromSelfOptional(token, orElse);
  }

  @override
  Object injectFromAncestryOptional(
    Object token, [
    Object orElse = throwIfNotFound,
  ]) {
    if (parent == null) {
      return orElse;
    }
    return parent.injectOptional(token, orElse);
  }
}
