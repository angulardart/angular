import 'package:meta/meta.dart';

import '../../core/linker/app_view.dart';
import 'hierarchical.dart';
import 'injector.dart';

/// **INTERNAL ONLY**: Adapts the [AppView] interfaces as an injector.
@Immutable()
class ElementInjector extends Injector implements HierarchicalInjector {
  final AppView _view;
  final int _nodeIndex;

  HierarchicalInjector _parent;

  ElementInjector(this._view, this._nodeIndex);

  @override
  T inject<T>({
    @required Object token,
    OrElseInject<T> orElse: throwsNotFound,
  }) =>
      _view.injectorGet(
        token,
        _nodeIndex,
        identical(orElse, throwsNotFound) ? throwIfNotFound : null,
      );

  @override
  T injectFromAncestry<T>(
    Object token, {
    OrElseInject<T> orElse: throwsNotFound,
  }) =>
      _view.parentView.injectorGet(
        token,
        _view.viewData.parentIndex,
        identical(orElse, throwsNotFound) ? throwIfNotFound : null,
      );

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
