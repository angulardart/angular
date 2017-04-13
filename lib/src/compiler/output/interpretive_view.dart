import 'package:angular2/src/core/linker/app_view.dart';
import 'package:angular2/src/core/linker/component_factory.dart';
import 'package:angular2/src/debug/debug_app_view.dart';
import 'package:angular2/src/debug/debug_context.dart' show StaticNodeDebugInfo;
import 'package:angular2/src/facade/exceptions.dart' show BaseException;

import 'dynamic_instance.dart';

class InterpretiveAppViewInstanceFactory implements InstanceFactory {
  @override
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
      return new _InterpretiveAppView(clazz, args, props, getters, methods);
    } else if (identical(superClass, DebugAppView)) {
      return new _InterpretiveAppView(clazz, args, props, getters, methods);
    }
    throw new BaseException(
        "Can't instantiate class ${superClass} in interpretative mode");
  }
}

class _InterpretiveAppView<T> extends DebugAppView<T>
    implements DynamicInstance {
  @override
  final dynamicRuntimeType;

  @override
  final Map<String, dynamic> props;
  @override
  final Map<String, Function> getters;
  @override
  final Map<String, Function> methods;

  _InterpretiveAppView(
    this.dynamicRuntimeType,
    List<dynamic> args,
    this.props,
    this.getters,
    this.methods,
  )
      : super(
          args[0],
          args[1] as Map<String, dynamic>,
          args[2],
          args[3],
          args[4],
          args[5] as List<StaticNodeDebugInfo>,
        );
  
  @override
  ComponentRef build() {
    var m = methods['build'];
    if (m != null) {
      return m();
    } else {
      return super.build();
    }
  }

  @override
  dynamic injectorGetInternal(
      dynamic token, int nodeIndex, dynamic notFoundResult) {
    var m = methods['injectorGetInternal'];
    if (m != null) {
      return m(token, nodeIndex, notFoundResult);
    }
    return notFoundResult;
  }

  @override
  void destroyInternal() {
    var m = methods['destroyInternal'];
    if (m != null) {
      return m();
    } else {
      return super.destroyInternal();
    }
  }

  @override
  void dirtyParentQueriesInternal() {
    var m = methods['dirtyParentQueriesInternal'];
    if (m != null) {
      return m();
    } else {
      return super.dirtyParentQueriesInternal();
    }
  }

  @override
  void detectChangesInternal() {
    var m = methods['detectChangesInternal'];
    if (m != null) {
      return m();
    } else {
      return super.detectChangesInternal();
    }
  }
}
