import "package:angular2/src/facade/collection.dart"
    show ListWrapper, StringMapWrapper;
import "package:angular2/src/facade/lang.dart"
    show isBlank, isPresent, StringWrapper;

import "../compile_metadata.dart" show CompileDirectiveMetadata;
import "../output/output_ast.dart" as o;
import "../template_ast.dart" show BoundEventAst, DirectiveAst;
import "compile_binding.dart" show CompileBinding;
import "compile_element.dart" show CompileElement;
import "compile_method.dart" show CompileMethod;
import "constants.dart" show EventHandlerVars, ViewProperties;
import "expression_converter.dart" show convertCdStatementToIr;

class CompileEventListener {
  CompileElement compileElement;
  String eventTarget;
  String eventName;
  CompileMethod _method;
  bool _hasComponentHostListener = false;
  String _methodName;
  o.FnParam _eventParam;
  List<o.Expression> _actionResultExprs = [];
  static CompileEventListener getOrCreate(
      CompileElement compileElement,
      String eventTarget,
      String eventName,
      List<CompileEventListener> targetEventListeners) {
    var listener = targetEventListeners.firstWhere(
        (listener) =>
            listener.eventTarget == eventTarget &&
            listener.eventName == eventName,
        orElse: () => null);
    if (isBlank(listener)) {
      listener = new CompileEventListener(
          compileElement, eventTarget, eventName, targetEventListeners.length);
      targetEventListeners.add(listener);
    }
    return listener;
  }

  CompileEventListener(this.compileElement, this.eventTarget, this.eventName,
      num listenerIndex) {
    this._method = new CompileMethod(compileElement.view);
    this._methodName =
        '''_handle_${ santitizeEventName ( eventName )}_${ compileElement . nodeIndex}_${ listenerIndex}''';
    this._eventParam = new o.FnParam(
        EventHandlerVars.event.name,
        o.importType(
            this.compileElement.view.genConfig.renderTypes.renderEvent));
  }
  addAction(BoundEventAst hostEvent, CompileDirectiveMetadata directive,
      o.Expression directiveInstance) {
    if (isPresent(directive) && directive.isComponent) {
      this._hasComponentHostListener = true;
    }
    this._method.resetDebugInfo(this.compileElement.nodeIndex, hostEvent);
    var context = isPresent(directiveInstance)
        ? directiveInstance
        : o.THIS_EXPR.prop("context");
    var actionStmts = convertCdStatementToIr(
        this.compileElement.view, context, hostEvent.handler);
    var lastIndex = actionStmts.length - 1;
    if (lastIndex >= 0) {
      var lastStatement = actionStmts[lastIndex];
      var returnExpr = convertStmtIntoExpression(lastStatement);
      var preventDefaultVar =
          o.variable('''pd_${ this . _actionResultExprs . length}''');
      this._actionResultExprs.add(preventDefaultVar);
      if (isPresent(returnExpr)) {
        // Note: We need to cast the result of the method call to dynamic,

        // as it might be a void method!
        actionStmts[lastIndex] = preventDefaultVar
            .set(returnExpr.cast(o.DYNAMIC_TYPE).notIdentical(o.literal(false)))
            .toDeclStmt(null, [o.StmtModifier.Final]);
      }
    }
    this._method.addStmts(actionStmts);
  }

  finishMethod() {
    var markPathToRootStart = this._hasComponentHostListener
        ? this.compileElement.appElement.prop("componentView")
        : o.THIS_EXPR;
    o.Expression resultExpr = o.literal(true);
    this._actionResultExprs.forEach((expr) {
      resultExpr = resultExpr.and(expr);
    });
    List<o.Statement> stmts = (new List.from((new List.from((<o.Statement>[
      markPathToRootStart.callMethod("markPathToRootAsCheckOnce", []).toStmt()
    ]))..addAll(this._method.finish())))
      ..addAll([new o.ReturnStatement(resultExpr)]));
    this.compileElement.view.eventHandlerMethods.add(new o.ClassMethod(
        this._methodName,
        [this._eventParam],
        stmts,
        o.BOOL_TYPE,
        [o.StmtModifier.Private]));
  }

  listenToRenderer() {
    var listenExpr;
    var eventListener = o.THIS_EXPR.callMethod("eventHandler", [
      o.THIS_EXPR
          .prop(this._methodName)
          .callMethod(o.BuiltinMethod.bind, [o.THIS_EXPR])
    ]);
    if (isPresent(this.eventTarget)) {
      listenExpr = ViewProperties.renderer.callMethod("listenGlobal", [
        o.literal(this.eventTarget),
        o.literal(this.eventName),
        eventListener
      ]);
    } else {
      listenExpr = ViewProperties.renderer.callMethod("listen", [
        this.compileElement.renderNode,
        o.literal(this.eventName),
        eventListener
      ]);
    }
    var disposable = o.variable(
        '''disposable_${ this . compileElement . view . disposables . length}''');
    this.compileElement.view.disposables.add(disposable);
    this.compileElement.view.createMethod.addStmt(disposable
        .set(listenExpr)
        .toDeclStmt(o.FUNCTION_TYPE, [o.StmtModifier.Private]));
  }

  listenToDirective(o.Expression directiveInstance, String observablePropName) {
    var subscription = o.variable(
        '''subscription_${ this . compileElement . view . subscriptions . length}''');
    this.compileElement.view.subscriptions.add(subscription);
    var eventListener = o.THIS_EXPR.callMethod("eventHandler", [
      o.THIS_EXPR
          .prop(this._methodName)
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
        compileElement, hostEvent.target, hostEvent.name, eventListeners);
    listener.addAction(hostEvent, null, null);
  });
  ListWrapper.forEachWithIndex(dirs, (directiveAst, i) {
    var directiveInstance = compileElement.directiveInstances[i];
    directiveAst.hostEvents.forEach((hostEvent) {
      compileElement.view.bindings
          .add(new CompileBinding(compileElement, hostEvent));
      var listener = CompileEventListener.getOrCreate(
          compileElement, hostEvent.target, hostEvent.name, eventListeners);
      listener.addAction(hostEvent, directiveAst.directive, directiveInstance);
    });
  });
  eventListeners.forEach((listener) => listener.finishMethod());
  return eventListeners;
}

bindDirectiveOutputs(DirectiveAst directiveAst, o.Expression directiveInstance,
    List<CompileEventListener> eventListeners) {
  StringMapWrapper.forEach(directiveAst.directive.outputs,
      (eventName, observablePropName) {
    eventListeners
        .where((listener) => listener.eventName == eventName)
        .toList()
        .forEach((listener) {
      listener.listenToDirective(directiveInstance, observablePropName);
    });
  });
}

bindRenderOutputs(List<CompileEventListener> eventListeners) {
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

String santitizeEventName(String name) {
  return StringWrapper.replaceAll(name, new RegExp(r'[^a-zA-Z_]'), "_");
}
