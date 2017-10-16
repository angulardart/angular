import "package:angular/src/facade/exceptions.dart" show BaseException;

import "../compile_metadata.dart" show CompilePipeMetadata;
import "../output/output_ast.dart" as o;
import "compile_view.dart" show CompileView;
import "view_compiler_utils.dart" show getPropertyInView;

class _PurePipeProxy {
  final CompileView view;
  final o.ReadClassMemberExpr instance;
  final int argCount;

  _PurePipeProxy(this.view, this.instance, this.argCount);
}

class CompilePipe {
  final CompileView view;
  final CompilePipeMetadata meta;
  final _purePipeProxies = <_PurePipeProxy>[];
  o.ReadClassMemberExpr instance;

  static o.Expression createCallPipeExpression(CompileView view, String name,
      o.Expression input, List<o.Expression> args) {
    var compView = view.componentView;
    var meta = _findPipeMeta(compView, name);
    CompilePipe pipe;
    if (meta.pure) {
      // pure pipes live on the component view
      pipe = compView.purePipes[name];
      if (pipe == null) {
        pipe = new CompilePipe(compView, meta);
        compView.purePipes[name] = pipe;
        compView.pipes.add(pipe);
      }
    } else {
      // Non pure pipes live on the view that called it
      pipe = new CompilePipe(view, meta);
      view.pipes.add(pipe);
    }
    return pipe._call(view, [input]..addAll(args));
  }

  CompilePipe(this.view, this.meta) {
    instance =
        new o.ReadClassMemberExpr('_pipe_${meta.name}_${view.pipeCount++}');
  }

  void create() {
    view.createPipeInstance(instance.name, meta);
    for (var purePipeProxy in _purePipeProxies) {
      final pipeInstanceSeenFromPureProxy =
          getPropertyInView(instance, purePipeProxy.view, view);
      // A pipe transform method has one required argument, and a variable
      // number of optional arguments. However, each call site will always
      // invoke the transform method with a fixed number of arguments, so we
      // can use a pure proxy with the same number of required arguments.
      final pureProxyType = new o.FunctionType(
        meta.transformType.returnType,
        meta.transformType.paramTypes.sublist(0, purePipeProxy.argCount),
      );
      purePipeProxy.view.createPureProxy(
        pipeInstanceSeenFromPureProxy.prop("transform"),
        purePipeProxy.argCount,
        purePipeProxy.instance,
        pureProxyType: pureProxyType,
      );
    }
  }

  o.Expression _call(CompileView callingView, List<o.Expression> args) {
    if (meta.pure) {
      // PurePipeProxies live on the view that called them.
      final purePipeProxy = new _PurePipeProxy(
          callingView,
          new o.ReadClassMemberExpr(
              '${instance.name}_${_purePipeProxies.length}'),
          args.length);
      _purePipeProxies.add(purePipeProxy);
      return purePipeProxy.instance.callFn(args);
    } else {
      return getPropertyInView(instance, callingView, view)
          .callMethod("transform", args);
    }
  }
}

CompilePipeMetadata _findPipeMeta(CompileView view, String name) {
  CompilePipeMetadata pipeMeta;
  for (var i = view.pipeMetas.length - 1; i >= 0; i--) {
    var localPipeMeta = view.pipeMetas[i];
    if (localPipeMeta.name == name) {
      pipeMeta = localPipeMeta;
      break;
    }
  }
  if (pipeMeta == null) {
    throw new BaseException('Illegal state: Could not find pipe $name '
        'although the parser should have detected this error!');
  }
  return pipeMeta;
}
