import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart" show isBlank;

import "../di/injector.dart" show Injector, THROW_IF_NOT_FOUND;

const _UNDEFINED = const Object();

abstract class CodegenInjector<MODULE> implements Injector {
  Injector parent;
  MODULE mainModule;
  CodegenInjector(this.parent, _needsMainModule, this.mainModule) {
    if (_needsMainModule && isBlank(mainModule)) {
      throw new BaseException("This injector needs a main module instance!");
    }
  }
  dynamic get(dynamic token, [dynamic notFoundValue = THROW_IF_NOT_FOUND]) {
    var result = this.getInternal(token, _UNDEFINED);
    return identical(result, _UNDEFINED)
        ? this.parent.get(token, notFoundValue)
        : result;
  }

  dynamic getInternal(dynamic token, dynamic notFoundValue);
}

class CodegenInjectorFactory<MODULE> {
  final dynamic /* (parent: Injector, mainModule: MODULE) => Injector */ _injectorFactory;
  const CodegenInjectorFactory(this._injectorFactory);
  Injector create([Injector parent = null, MODULE mainModule = null]) {
    if (isBlank(parent)) {
      parent = Injector.NULL;
    }
    return this._injectorFactory(parent, mainModule);
  }
}
