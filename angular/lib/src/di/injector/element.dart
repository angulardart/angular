import 'package:meta/meta.dart';

import '../../core/linker/app_view.dart';
import 'hierarchical.dart';
import 'injector.dart';

/// **INTERNAL ONLY**: Adapts the [AppView] interfaces as an injector.
@Immutable()
class ElementInjector extends HierarchicalInjector {
  final AppView _view;
  final int _nodeIndex;

  HierarchicalInjector _parent;

  ElementInjector(this._view, this._nodeIndex);

  dynamic _injectFrom(
    AppView view,
    int nodeIndex,
    Object token,
    Object orElse,
  ) {
    return view.injectorGet(token, nodeIndex, orElse);
  }

  @override
  dynamic injectOptionalUntyped(
    Object token, [
    Object orElse = throwIfNotFound,
  ]) =>
      _injectFrom(_view, _nodeIndex, token, orElse);

  @override
  injectFromAncestryOptional(
    Object token, [
    Object orElse = throwIfNotFound,
  ]) =>
      _injectFrom(_view.parentView, _view.viewData.parentIndex, token, orElse);

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

  @override
  HierarchicalInjector get parent {
    if (_parent == null) {
      _parent = ElementInjector(
        _view.parentView,
        _view.viewData.parentIndex,
      );
    }
    return _parent;
  }
}
