import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart" show isBlank;

import "../compile_metadata.dart" show CompilePipeMetadata;
import "../identifiers.dart" show Identifiers, identifierToken;
import "../output/output_ast.dart" as o;
import "compile_view.dart" show CompileView;
import "util.dart"
    show injectFromViewParentInjector, createPureProxy, getPropertyInView;

class _PurePipeProxy {
  CompileView view;
  o.ReadPropExpr instance;
  num argCount;
  _PurePipeProxy(this.view, this.instance, this.argCount) {}
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

  o.ReadPropExpr instance;
  List<_PurePipeProxy> _purePipeProxies = [];
  CompilePipe(this.view, this.meta) {
    this.instance =
        o.THIS_EXPR.prop('''_pipe_${ meta . name}_${ view . pipeCount ++}''');
  }
  bool get pure {
    return this.meta.pure;
  }

  void create() {
    var deps = this.meta.type.diDeps.map((diDep) {
      if (diDep.token
          .equalsTo(identifierToken(Identifiers.ChangeDetectorRef))) {
        return o.THIS_EXPR.prop("ref");
      }
      return injectFromViewParentInjector(diDep.token, false);
    }).toList();
    this.view.fields.add(new o.ClassField(this.instance.name,
        o.importType(this.meta.type), [o.StmtModifier.Private]));
    this.view.createMethod.resetDebugInfo(null, null);
    this.view.createMethod.addStmt(o.THIS_EXPR
        .prop(this.instance.name)
        .set(o.importExpr(this.meta.type).instantiate(deps))
        .toStmt());
    this._purePipeProxies.forEach((purePipeProxy) {
      var pipeInstanceSeenFromPureProxy =
          getPropertyInView(this.instance, purePipeProxy.view, this.view);
      createPureProxy(
          pipeInstanceSeenFromPureProxy.prop("transform").callMethod(
              o.BuiltinMethod.bind, [pipeInstanceSeenFromPureProxy]),
          purePipeProxy.argCount,
          purePipeProxy.instance,
          purePipeProxy.view);
    });
  }

  o.Expression _call(CompileView callingView, List<o.Expression> args) {
    if (this.meta.pure) {
      // PurePipeProxies live on the view that called them.
      var purePipeProxy = new _PurePipeProxy(
          callingView,
          o.THIS_EXPR.prop(
              '''${ this . instance . name}_${ this . _purePipeProxies . length}'''),
          args.length);
      this._purePipeProxies.add(purePipeProxy);
      return o.importExpr(Identifiers.castByValue).callFn([
        purePipeProxy.instance,
        getPropertyInView(
            this.instance.prop("transform"), callingView, this.view)
      ]).callFn(args);
    } else {
      return getPropertyInView(this.instance, callingView, this.view)
          .callMethod("transform", args);
    }
  }
}

CompilePipeMetadata _findPipeMeta(CompileView view, String name) {
  CompilePipeMetadata pipeMeta = null;
  for (var i = view.pipeMetas.length - 1; i >= 0; i--) {
    var localPipeMeta = view.pipeMetas[i];
    if (localPipeMeta.name == name) {
      pipeMeta = localPipeMeta;
      break;
    }
  }
  if (isBlank(pipeMeta)) {
    throw new BaseException(
        '''Illegal state: Could not find pipe ${ name} although the parser should have detected this error!''');
  }
  return pipeMeta;
}
