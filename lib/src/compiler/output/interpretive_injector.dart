import "package:angular2/src/core/linker/injector_factory.dart"
    show CodegenInjector;
import "package:angular2/src/facade/exceptions.dart" show BaseException;

import "output_interpreter.dart" show InstanceFactory, DynamicInstance;

class InterpretiveInjectorInstanceFactory implements InstanceFactory {
  DynamicInstance createInstance(
      dynamic superClass,
      dynamic clazz,
      List<dynamic> args,
      Map<String, dynamic> props,
      Map<String, Function> getters,
      Map<String, Function> methods) {
    if (identical(superClass, CodegenInjector)) {
      return new _InterpretiveInjector(args, clazz, props, getters, methods);
    }
    throw new BaseException(
        '''Can\'t instantiate class ${ superClass} in interpretative mode''');
  }
}

class _InterpretiveInjector extends CodegenInjector<dynamic>
    implements DynamicInstance {
  dynamic clazz;
  Map<String, dynamic> props;
  Map<String, Function> getters;
  Map<String, Function> methods;
  _InterpretiveInjector(
      List<dynamic> args, this.clazz, this.props, this.getters, this.methods)
      : super(args[0], args[1], args[2]) {
    /* super call moved to initializer */;
  }
  dynamic getInternal(dynamic token, dynamic notFoundResult) {
    var m = this.methods["getInternal"];
    return m(token, notFoundResult);
  }
}
