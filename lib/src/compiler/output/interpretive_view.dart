import 'package:angular2/src/core/linker/view_container.dart';
import 'package:angular2/src/core/linker/app_view.dart';
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
      return new _InterpretiveAppView(args, props, getters, methods);
    } else if (identical(superClass, DebugAppView)) {
      return new _InterpretiveAppView(args, props, getters, methods);
    }
    throw new BaseException(
        "Can't instantiate class ${superClass} in interpretative mode");
  }
}

/// AppView that delegates generated methods to interpreted version stored
/// in methods/getter/props constructed at runtime.
///
/// Any time a new method is added to AppView by code generator, this class
/// will need to be updated with member method signature.
class _InterpretiveAppView extends DebugAppView<dynamic>
    implements DynamicInstance {
  @override
  final Map<String, dynamic> props;
  @override
  final Map<String, Function> getters;
  @override
  final Map<String, Function> methods;
  _InterpretiveAppView(
      List<dynamic> args, this.props, this.getters, this.methods)
      : super(args[0], args[1], args[2], args[3] as Map<String, dynamic>,
            args[4], args[5], args[6], args[7] as List<StaticNodeDebugInfo>);

  @override
  ViewContainer createInternal(dynamic /* String | dynamic */ rootSelector) {
    var m = methods['createInternal'];
    if (m != null) {
      return m(rootSelector);
    } else {
      return super.createInternal(rootSelector);
    }
  }

  @override
  dynamic injectorGetInternal(
      dynamic token, int nodeIndex, dynamic notFoundResult) {
    var m = methods['injectorGetInternal'];
    if (m != null) {
      return m(token, nodeIndex, notFoundResult);
    } else {
      return super.injectorGet(token, nodeIndex, notFoundResult);
    }
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

  @override
  void visitRootNodesInternal(void callback(node, nodeContext), ctx) {
    var m = methods['visitRootNodesInternal'];
    if (m != null) {
      return m(callback, ctx);
    } else {
      return super.visitRootNodesInternal(callback, ctx);
    }
  }

  @override
  void visitProjectedNodes(
      int ngContentIndex, void callback(node, nodeContext), ctx) {
    var m = methods['visitProjectedNodes'];
    if (m != null) {
      return m(ngContentIndex, callback, ctx);
    } else {
      return super.visitProjectableNodes(ngContentIndex, callback, ctx);
    }
  }

  @override
  void visitProjectableNodesInternal(int nodeIndex, int ngContentIndex,
      void callback(node, nodeContext), ctx) {
    var m = methods['visitProjectableNodesInternal'];
    if (m != null) {
      return m(nodeIndex, ngContentIndex, callback, ctx);
    } else {
      return super.visitProjectableNodesInternal(
          nodeIndex, ngContentIndex, callback, ctx);
    }
  }
}
