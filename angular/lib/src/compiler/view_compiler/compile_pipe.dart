import "package:angular/src/facade/exceptions.dart" show BaseException;

import "../compile_metadata.dart" show CompilePipeMetadata;
import "../identifiers.dart" show Identifiers, identifierToken;
import "../output/output_ast.dart" as o;
import "compile_view.dart" show CompileView;
import "view_compiler_utils.dart"
    show injectFromViewParentInjector, createPureProxy, getPropertyInView;

class _PurePipeProxy {
  CompileView view;
  o.ReadClassMemberExpr instance;
  num argCount;
  _PurePipeProxy(this.view, this.instance, this.argCount);
}

class CompilePipe {
  CompileView view;
  CompilePipeMetadata meta;
  static o.Expression call(
      CompileView view, String name, List<o.Expression> args) {
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
    return pipe._call(view, args);
  }

  o.ReadClassMemberExpr instance;
  final _purePipeProxies = <_PurePipeProxy>[];
  CompilePipe(this.view, this.meta) {
    this.instance =
        new o.ReadClassMemberExpr('_pipe_${meta.name}_${view.pipeCount++}');
  }
  bool get pure {
    return this.meta.pure;
  }

  void create() {
    var deps = this.meta.type.diDeps.map((diDep) {
      if (diDep.token
          .equalsTo(identifierToken(Identifiers.ChangeDetectorRef))) {
        return new o.ReadClassMemberExpr('ref');
      }
      return injectFromViewParentInjector(this.view, diDep.token, false);
    }).toList();
    this.view.nameResolver.addField(new o.ClassField(this.instance.name,
        outputType: o.importType(this.meta.type),
        modifiers: [o.StmtModifier.Private]));
    this.view.createMethod.resetDebugInfo(null, null);
    this.view.createMethod.addStmt(new o.WriteClassMemberExpr(
            instance.name, o.importExpr(this.meta.type).instantiate(deps))
        .toStmt());
    this._purePipeProxies.forEach((purePipeProxy) {
      var pipeInstanceSeenFromPureProxy =
          getPropertyInView(this.instance, purePipeProxy.view, this.view);
      createPureProxy(pipeInstanceSeenFromPureProxy.prop("transform"),
          purePipeProxy.argCount, purePipeProxy.instance, purePipeProxy.view);
    });
  }

  o.Expression _call(CompileView callingView, List<o.Expression> args) {
    if (this.meta.pure) {
      // PurePipeProxies live on the view that called them.
      var purePipeProxy = new _PurePipeProxy(
          callingView,
          new o.ReadClassMemberExpr(
              '${this.instance.name}_${this._purePipeProxies.length}'),
          args.length);
      this._purePipeProxies.add(purePipeProxy);
      return o.importExpr(Identifiers.castByValue).callFn([
        purePipeProxy.instance,
        getPropertyInView(
          this.instance.prop("transform"),
          callingView,
          this.view,
          forceCast: true,
        )
      ]).callFn(args);
    } else {
      return getPropertyInView(this.instance, callingView, this.view)
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
