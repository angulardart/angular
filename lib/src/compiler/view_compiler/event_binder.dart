import '../compile_metadata.dart' show CompileDirectiveMetadata;
import '../output/output_ast.dart' as o;
import '../template_ast.dart' show BoundEventAst, DirectiveAst;
import 'compile_binding.dart' show CompileBinding;
import 'compile_element.dart' show CompileElement;
import 'compile_method.dart' show CompileMethod;
import 'constants.dart' show EventHandlerVars;
import 'expression_converter.dart' show convertCdStatementToIr;

/// Generates code to listen to a single eventName on a [CompileElement].
///
/// Since multiple directives on an element could potentially listen to the
/// same event, this class collects the individual handlers as actions and
/// creates a single member method on the component that calls each of the
/// handlers and then applies logical AND to determine resulting
/// prevent default value.
class CompileEventListener {
  CompileElement compileElement;
  String eventName;
  CompileMethod _method;
  bool _hasComponentHostListener = false;
  String _methodName;
  o.FnParam _eventParam;
  List<o.Expression> _actionResultExprs = <o.Expression>[];

  /// Helper function to search for an event in [targetEventListeners] list and
  /// add a new one if it doesn't exist yet.
  /// TODO: try using Map, this code is quadratic and assumes typical event
  /// lists are very small.
  static CompileEventListener getOrCreate(CompileElement compileElement,
      String eventName, List<CompileEventListener> targetEventListeners) {
    for (int i = 0, len = targetEventListeners.length; i < len; i++) {
      var existingListener = targetEventListeners[i];
      if (existingListener.eventName == eventName) return existingListener;
    }
    var listener = new CompileEventListener(
        compileElement, eventName, targetEventListeners.length);
    targetEventListeners.add(listener);
    return listener;
  }

  CompileEventListener(this.compileElement, this.eventName, int listenerIndex) {
    _method = new CompileMethod(compileElement.view);
    _methodName =
        '_handle_${sanitizeEventName(eventName)}_${compileElement.nodeIndex}_'
        '$listenerIndex';
    // TODO: type event param as Identifiers.HTML_EVENT if non-custom event or
    // stream.
    _eventParam =
        new o.FnParam(EventHandlerVars.event.name, o.importType(null));
  }

  void addAction(BoundEventAst hostEvent, CompileDirectiveMetadata directive,
      o.Expression directiveInstance) {
    if (directive != null && directive.isComponent) {
      _hasComponentHostListener = true;
    }
    _method.resetDebugInfo(compileElement.nodeIndex, hostEvent);
    var context = directiveInstance ?? new o.ReadClassMemberExpr('ctx');
    var actionStmts = convertCdStatementToIr(
        compileElement.view,
        context,
        hostEvent.handler,
        this.compileElement.view.component.template.preserveWhitespace);
    var lastIndex = actionStmts.length - 1;
    if (lastIndex >= 0) {
      var lastStatement = actionStmts[lastIndex];
      var returnExpr = convertStmtIntoExpression(lastStatement);
      var preventDefaultVar = o.variable('pd_${_actionResultExprs.length}');
      _actionResultExprs.add(preventDefaultVar);
      if (returnExpr != null) {
        // Note: We need to cast the result of the method call to dynamic,
        // as it might be a void method!
        actionStmts[lastIndex] = preventDefaultVar
            .set(returnExpr.cast(o.DYNAMIC_TYPE).notIdentical(o.literal(false)))
            .toDeclStmt(null, [o.StmtModifier.Final]);
      }
    }
    _method.addStmts(actionStmts);
  }

  void finishMethod() {
    var markPathToRootStart = _hasComponentHostListener
        ? compileElement.appViewContainer.prop('componentView')
        : o.THIS_EXPR;
    o.Expression resultExpr = o.literal(true);
    for (var i = 0, len = _actionResultExprs.length; i < len; i++) {
      resultExpr = resultExpr.and(_actionResultExprs[i]);
    }
    List<o.Statement> stmts = <o.Statement>[
      markPathToRootStart.callMethod('markPathToRootAsCheckOnce', []).toStmt()
    ]
      ..addAll(_method.finish())
      ..add(new o.ReturnStatement(resultExpr));

    compileElement.view.eventHandlerMethods.add(new o.ClassMethod(
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

    o.Expression listenExpr = new o.InvokeMemberMethodExpr('listen', [
      this.compileElement.renderNode,
      o.literal(this.eventName),
      eventListener
    ]);

    compileElement.view.createMethod
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
  for (var hostEvent in hostEvents) {
    compileElement.view.bindings
        .add(new CompileBinding(compileElement, hostEvent));
    var listener = CompileEventListener.getOrCreate(
        compileElement, hostEvent.name, eventListeners);
    listener.addAction(hostEvent, null, null);
  }
  var i = -1;
  for (var directiveAst in dirs) {
    i++;
    var directiveInstance = compileElement.directiveInstances[i];
    for (var hostEvent in directiveAst.hostEvents) {
      compileElement.view.bindings
          .add(new CompileBinding(compileElement, hostEvent));
      var listener = CompileEventListener.getOrCreate(
          compileElement, hostEvent.name, eventListeners);
      listener.addAction(hostEvent, directiveAst.directive, directiveInstance);
    }
  }
  for (int i = 0, len = eventListeners.length; i < len; i++) {
    eventListeners[i].finishMethod();
  }
  return eventListeners;
}

void bindDirectiveOutputs(DirectiveAst directiveAst,
    o.Expression directiveInstance, List<CompileEventListener> eventListeners) {
  directiveAst.directive.outputs.forEach((observablePropName, eventName) {
    for (int i = 0, len = eventListeners.length; i < len; i++) {
      CompileEventListener listener = eventListeners[i];
      if (listener.eventName != eventName) continue;
      listener.listenToDirective(directiveInstance, observablePropName);
    }
  });
}

void bindRenderOutputs(List<CompileEventListener> eventListeners) {
  for (int i = 0, len = eventListeners.length; i < len; i++) {
    CompileEventListener listener = eventListeners[i];
    listener.listenToRenderer();
  }
}

o.Expression convertStmtIntoExpression(o.Statement stmt) {
  if (stmt is o.ExpressionStatement) {
    return stmt.expr;
  } else if (stmt is o.ReturnStatement) {
    return stmt.value;
  }
  return null;
}

final RegExp _eventNameRegExp = new RegExp(r'[^a-zA-Z_]');

String sanitizeEventName(String name) {
  return name.replaceAll(_eventNameRegExp, '_');
}
