import 'package:angular2/src/core/linker/app_element.dart';
import 'package:angular2/src/core/linker/app_view.dart';
import 'package:angular2/src/debug/debug_app_view.dart';
import 'package:angular2/src/debug/debug_context.dart' show StaticNodeDebugInfo;
import 'package:angular2/src/facade/exceptions.dart' show BaseException;

import 'dynamic_instance.dart';

class InterpretiveAppViewInstanceFactory implements InstanceFactory {
  DynamicInstance createInstance(
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
        "Can't instantiate class ${superClass} in interpretative mode");
  }
}

class _InterpretiveAppView extends DebugAppView<dynamic>
    implements DynamicInstance {
  final Map<String, dynamic> props;
  final Map<String, Function> getters;
  final Map<String, Function> methods;
  _InterpretiveAppView(
      List<dynamic> args, this.props, this.getters, this.methods)
      : super(args[0], args[1], args[2], args[3] as Map<String, dynamic>,
            args[4], args[5], args[6], args[7] as List<StaticNodeDebugInfo>);

  AppElement createInternal(dynamic /* String | dynamic */ rootSelector) {
    var m = methods['createInternal'];
    if (m != null) {
      return m(rootSelector);
    } else {
      return super.createInternal(rootSelector);
    }
  }

  dynamic injectorGetInternal(
      dynamic token, num nodeIndex, dynamic notFoundResult) {
    var m = methods['injectorGetInternal'];
    if (m != null) {
      return m(token, nodeIndex, notFoundResult);
    } else {
      return super.injectorGet(token, nodeIndex, notFoundResult);
    }
  }

  void destroyInternal() {
    var m = methods['destroyInternal'];
    if (m != null) {
      return m();
    } else {
      return super.destroyInternal();
    }
  }

  void dirtyParentQueriesInternal() {
    var m = methods['dirtyParentQueriesInternal'];
    if (m != null) {
      return m();
    } else {
      return super.dirtyParentQueriesInternal();
    }
  }

  void detectChangesInternal() {
    var m = methods['detectChangesInternal'];
    if (m != null) {
      return m();
    } else {
      return super.detectChangesInternal();
    }
  }
}
