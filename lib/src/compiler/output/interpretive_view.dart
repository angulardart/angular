library angular2.src.compiler.output.interpretive_view;

import "package:angular2/src/facade/lang.dart" show isPresent;
import "package:angular2/src/core/linker/view.dart" show AppView, DebugAppView;
import "package:angular2/src/core/linker/element.dart" show AppElement;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "output_interpreter.dart" show InstanceFactory, DynamicInstance;

class InterpretiveAppViewInstanceFactory implements InstanceFactory {
  dynamic createInstance(
      dynamic superClass,
      dynamic clazz,
      List<dynamic> args,
      Map<String, dynamic> props,
      Map<String, Function> getters,
      Map<String, Function> methods) {
    if (identical(superClass, AppView)) {
      // We are always using DebugAppView as parent.

      // However, in prod mode we generate a constructor call that does

      // not have the argument for the debugNodeInfos.
      args = (new List.from(args)..addAll([null]));
      return new _InterpretiveAppView(args, props, getters, methods);
    } else if (identical(superClass, DebugAppView)) {
      return new _InterpretiveAppView(args, props, getters, methods);
    }
    throw new BaseException(
        '''Can\'t instantiate class ${ superClass} in interpretative mode''');
  }
}

class _InterpretiveAppView extends DebugAppView<dynamic>
    implements DynamicInstance {
  Map<String, dynamic> props;
  Map<String, Function> getters;
  Map<String, Function> methods;
  _InterpretiveAppView(
      List<dynamic> args, this.props, this.getters, this.methods)
      : super(args[0], args[1], args[2], args[3], args[4], args[5], args[6],
            args[7], args[8]) {
    /* super call moved to initializer */;
  }
  AppElement createInternal(dynamic /* String | dynamic */ rootSelector) {
    var m = this.methods["createInternal"];
    if (isPresent(m)) {
      return m(rootSelector);
    } else {
      return super.createInternal(rootSelector);
    }
  }

  dynamic injectorGetInternal(
      dynamic token, num nodeIndex, dynamic notFoundResult) {
    var m = this.methods["injectorGetInternal"];
    if (isPresent(m)) {
      return m(token, nodeIndex, notFoundResult);
    } else {
      return super.injectorGet(token, nodeIndex, notFoundResult);
    }
  }

  void destroyInternal() {
    var m = this.methods["destroyInternal"];
    if (isPresent(m)) {
      return m();
    } else {
      return super.destroyInternal();
    }
  }

  void dirtyParentQueriesInternal() {
    var m = this.methods["dirtyParentQueriesInternal"];
    if (isPresent(m)) {
      return m();
    } else {
      return super.dirtyParentQueriesInternal();
    }
  }

  void detectChangesInternal(bool throwOnChange) {
    var m = this.methods["detectChangesInternal"];
    if (isPresent(m)) {
      return m(throwOnChange);
    } else {
      return super.detectChangesInternal(throwOnChange);
    }
  }
}
