library angular2.src.core.linker.element_injector;

import "package:angular2/src/facade/lang.dart" show isBlank, stringify;
import "package:angular2/src/core/di/injector.dart" show Injector, UNDEFINED;
import "view.dart" show AppView;

class ElementInjector extends Injector {
  AppView<dynamic> _view;
  num _nodeIndex;
  ElementInjector(this._view, this._nodeIndex) : super() {
    /* super call moved to initializer */;
  }
  dynamic get(dynamic token) {
    var result = this._view.injectorGet(token, this._nodeIndex, UNDEFINED);
    if (identical(result, UNDEFINED)) {
      result = this._view.parentInjector.get(token);
    }
    return result;
  }

  dynamic getOptional(dynamic token) {
    var result = this._view.injectorGet(token, this._nodeIndex, UNDEFINED);
    if (identical(result, UNDEFINED)) {
      result = this._view.parentInjector.getOptional(token);
    }
    return result;
  }
}
