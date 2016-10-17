import '../compile_metadata.dart' show CompileDirectiveMetadata;
import '../output/output_ast.dart' as o;
import '../template_ast.dart' show BoundEventAst, DirectiveAst;
import 'compile_binding.dart' show CompileBinding;
import 'compile_element.dart' show CompileElement;
import 'compile_method.dart' show CompileMethod;
import 'constants.dart' show EventHandlerVars, ViewProperties;
import 'expression_converter.dart' show convertCdStatementToIr;

class CompileEventListener {
  CompileElement compileElement;
  String eventName;
  CompileMethod _method;
  bool _hasComponentHostListener = false;
  String _methodName;
  o.FnParam _eventParam;
  List<o.Expression> _actionResultExprs = [];
  static CompileEventListener getOrCreate(CompileElement compileElement,
      String eventName, List<CompileEventListener> targetEventListeners) {
    var listener = targetEventListeners.firstWhere(
        (listener) => listener.eventName == eventName,
        orElse: () => null);
    if (listener == null) {
      listener = new CompileEventListener(
          compileElement, eventName, targetEventListeners.length);
      targetEventListeners.add(listener);
    }
    return listener;
  }

  CompileEventListener(this.compileElement, this.eventName, num listenerIndex) {
    this._method = new CompileMethod(compileElement.view);
    this._methodName =
        '_handle_${sanitizeEventName(eventName)}_${compileElement.nodeIndex}_'
        '${ listenerIndex}';
    this._eventParam = new o.FnParam(
        EventHandlerVars.event.name,
        o.importType(
            this.compileElement.view.genConfig.renderTypes.renderEvent));
  }
  void addAction(BoundEventAst hostEvent, CompileDirectiveMetadata directive,
      o.Expression directiveInstance) {
    if (directive != null && directive.isComponent) {
      this._hasComponentHostListener = true;
    }
    this._method.resetDebugInfo(this.compileElement.nodeIndex, hostEvent);
    var context = directiveInstance ?? new o.ReadClassMemberExpr('ctx');
    var actionStmts = convertCdStatementToIr(
        this.compileElement.view,
        context,
        hostEvent.handler,
        this.compileElement.view.component.template.preserveWhitespace);
    var lastIndex = actionStmts.length - 1;
    if (lastIndex >= 0) {
      var lastStatement = actionStmts[lastIndex];
      var returnExpr = convertStmtIntoExpression(lastStatement);
      var preventDefaultVar =
          o.variable('pd_${ this . _actionResultExprs . length}');
      this._actionResultExprs.add(preventDefaultVar);
      if (returnExpr != null) {
        // Note: We need to cast the result of the method call to dynamic,
        // as it might be a void method!
        actionStmts[lastIndex] = preventDefaultVar
            .set(returnExpr.cast(o.DYNAMIC_TYPE).notIdentical(o.literal(false)))
            .toDeclStmt(null, [o.StmtModifier.Final]);
      }
    }
    this._method.addStmts(actionStmts);
  }

  void finishMethod() {
    var markPathToRootStart = this._hasComponentHostListener
        ? this.compileElement.appElement.prop('componentView')
        : o.THIS_EXPR;
    o.Expression resultExpr = o.literal(true);
    this._actionResultExprs.forEach((expr) {
      resultExpr = resultExpr.and(expr);
    });
    List<o.Statement> stmts = (new List.from((new List.from((<o.Statement>[
      markPathToRootStart.callMethod('markPathToRootAsCheckOnce', []).toStmt()
    ]))..addAll(this._method.finish())))
      ..addAll([new o.ReturnStatement(resultExpr)]));
    this.compileElement.view.eventHandlerMethods.add(new o.ClassMethod(
        this._methodName,
        [this._eventParam],
        stmts,
        o.BOOL_TYPE,
        [o.StmtModifier.Private]));
  }

  void listenToRenderer() {
    var eventListener = new o.InvokeMemberMethodExpr('evt', [
      new o.ReadClassMemberExpr(_methodName)
          .callMethod(o.BuiltinMethod.bind, [o.THIS_EXPR])
    ]);
    o.Expression listenExpr = ViewProperties.renderer.callMethod('listen', [
      this.compileElement.renderNode,
      o.literal(this.eventName),
      eventListener
    ]);
    this
        .compileElement
        .view
        .createMethod
        .addStmt(new o.ExpressionStatement(listenExpr));
  }

  void listenToDirective(
      o.Expression directiveInstance, String observablePropName) {
    var subscription =
        o.variable('subscription_${compileElement.view.subscriptions.length}');
    this.compileElement.view.subscriptions.add(subscription);
    var eventListener = new o.InvokeMemberMethodExpr('evt', [
      new o.ReadClassMemberExpr(_methodName)
          .callMethod(o.BuiltinMethod.bind, [o.THIS_EXPR])
    ]);
    this.compileElement.view.createMethod.addStmt(subscription
        .set(directiveInstance
            .prop(observablePropName)
            .callMethod(o.BuiltinMethod.SubscribeObservable, [eventListener]))
        .toDeclStmt(null, [o.StmtModifier.Final]));
  }
}

List<CompileEventListener> collectEventListeners(List<BoundEventAst> hostEvents,
    List<DirectiveAst> dirs, CompileElement compileElement) {
  List<CompileEventListener> eventListeners = [];
  hostEvents.forEach((hostEvent) {
    compileElement.view.bindings
        .add(new CompileBinding(compileElement, hostEvent));
    var listener = CompileEventListener.getOrCreate(
        compileElement, hostEvent.name, eventListeners);
    listener.addAction(hostEvent, null, null);
  });
  var i = -1;
  dirs.forEach((directiveAst) {
    i++;
    var directiveInstance = compileElement.directiveInstances[i];
    directiveAst.hostEvents.forEach((hostEvent) {
      compileElement.view.bindings
          .add(new CompileBinding(compileElement, hostEvent));
      var listener = CompileEventListener.getOrCreate(
          compileElement, hostEvent.name, eventListeners);
      listener.addAction(hostEvent, directiveAst.directive, directiveInstance);
    });
  });
  eventListeners.forEach((listener) => listener.finishMethod());
  return eventListeners;
}

void bindDirectiveOutputs(DirectiveAst directiveAst,
    o.Expression directiveInstance, List<CompileEventListener> eventListeners) {
  directiveAst.directive.outputs.forEach((observablePropName, eventName) {
    eventListeners
        .where((listener) => listener.eventName == eventName)
        .toList()
        .forEach((listener) {
      listener.listenToDirective(directiveInstance, observablePropName);
    });
  });
}

void bindRenderOutputs(List<CompileEventListener> eventListeners) {
  eventListeners.forEach((listener) => listener.listenToRenderer());
}

o.Expression convertStmtIntoExpression(o.Statement stmt) {
  if (stmt is o.ExpressionStatement) {
    return stmt.expr;
  } else if (stmt is o.ReturnStatement) {
    return stmt.value;
  }
  return null;
}

String sanitizeEventName(String name) {
  return name.replaceAll(new RegExp(r'[^a-zA-Z_]'), '_');
}
