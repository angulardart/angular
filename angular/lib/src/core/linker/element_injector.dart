import 'package:meta/meta.dart';
import 'package:angular/src/core/di/injector.dart'
    show Injector, THROW_IF_NOT_FOUND;

import 'app_view.dart';

/// **INTERNAL ONLY**: Adapts the [AppView] interface as an [Injector].
@visibleForTesting
class ElementInjector implements Injector {
  final AppView _view;
  final int _nodeIndex;

  ElementInjector(this._view, this._nodeIndex);

  @override
  get(
    token, [
    notFoundValue = THROW_IF_NOT_FOUND,
  ]) =>
      _view.injectorGet(token, _nodeIndex, notFoundValue);
}
