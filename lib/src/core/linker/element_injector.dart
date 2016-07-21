import "package:angular2/src/core/di/injector.dart"
    show Injector, THROW_IF_NOT_FOUND;

import "view.dart" show AppView;

const _UNDEFINED = const Object();

class ElementInjector extends Injector {
  AppView<dynamic> _view;
  num _nodeIndex;
  ElementInjector(this._view, this._nodeIndex) : super() {
    /* super call moved to initializer */;
  }
  dynamic get(dynamic token, [dynamic notFoundValue = THROW_IF_NOT_FOUND]) {
    var result = _UNDEFINED;
    if (identical(result, _UNDEFINED)) {
      result = this._view.injectorGet(token, this._nodeIndex, _UNDEFINED);
    }
    if (identical(result, _UNDEFINED)) {
      result = this._view.parentInjector.get(token, notFoundValue);
    }
    return result;
  }
}
