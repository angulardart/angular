import 'package:meta/meta.dart';

import '../../core/linker/app_view.dart';
import 'hierarchical.dart';
import 'injector.dart';

/// **INTERNAL ONLY**: Adapts the [AppView] interfaces as an injector.
@Immutable()
class ElementInjector extends HierarchicalInjector {
  final AppView<Object> _view;
  final int _nodeIndex;

  ElementInjector(this._view, this._nodeIndex);

  @override
  dynamic provideUntyped(Object token, [Object orElse = throwIfNotFound]) =>
      _view.injectorGet(token, _nodeIndex, orElse);

  @override
  injectFromAncestryOptional(
    Object token, [
    Object orElse = throwIfNotFound,
  ]) =>
      throw UnimplementedError();

  @override
  injectFromParentOptional(
    Object token, [
    Object orElse = throwIfNotFound,
  ]) =>
      throw UnimplementedError();

  @override
  injectFromSelfOptional(
    Object token, [
    Object orElse = throwIfNotFound,
  ]) =>
      throw UnimplementedError();
}
