import 'package:meta/meta.dart';

import '../../core/linker/app_view.dart';
import 'hierarchical.dart';
import 'injector.dart';

/// Sentinel object representing the need to invoke "orElse" if returned.
final Object _useOrElse = new Object();

/// **INTERNAL ONLY**: Adapts the [AppView] interfaces as an injector.
@Immutable()
class ElementInjector extends Injector implements HierarchicalInjector {
  final AppView _view;
  final int _nodeIndex;

  HierarchicalInjector _parent;

  ElementInjector(this._view, this._nodeIndex);

  T _injectFrom<T>(
    AppView view,
    int nodeIndex,
    Object token,
    OrElseInject<T> orElse,
  ) {
    final result = view.injectorGet(token, nodeIndex, _useOrElse);
    if (identical(result, _useOrElse)) {
      return orElse(this, token);
    }
    return result;
  }

  @override
  T inject<T>({
    @required Object token,
    OrElseInject<T> orElse: throwsNotFound,
  }) =>
      _injectFrom(_view, _nodeIndex, token, orElse);

  @override
  T injectFromAncestry<T>(
    Object token, {
    OrElseInject<T> orElse: throwsNotFound,
  }) =>
      _injectFrom(_view.parentView, _view.viewData.parentIndex, token, orElse);

  @override
  T injectFromParent<T>(
    Object token, {
    OrElseInject<T> orElse: throwsNotFound,
  }) =>
      throw new UnimplementedError();

  @override
  T injectFromSelf<T>(
    Object token, {
    OrElseInject<T> orElse: throwsNotFound,
  }) =>
      throw new UnimplementedError();

  @override
  HierarchicalInjector get parent {
    if (_parent == null) {
      _parent = new ElementInjector(
        _view.parentView,
        _view.viewData.parentIndex,
      );
    }
    return _parent;
  }
}
