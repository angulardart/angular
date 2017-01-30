import 'package:angular2/src/core/di/injector.dart'
    show Injector, THROW_IF_NOT_FOUND;

import 'app_view.dart';

class ElementInjector extends Injector {
  final AppView _view;
  final int _nodeIndex;

  ElementInjector(this._view, this._nodeIndex);

  dynamic get(dynamic token, [dynamic notFoundValue = THROW_IF_NOT_FOUND]) =>
      _view.injectorGet(token, _nodeIndex, notFoundValue);
}
