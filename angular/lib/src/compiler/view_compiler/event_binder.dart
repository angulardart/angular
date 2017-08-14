import '../compile_metadata.dart' show CompileDirectiveMetadata;
import '../html_events.dart';
import '../identifiers.dart' show Identifiers;
import '../output/output_ast.dart' as o;
import '../template_ast.dart' show BoundEventAst, DirectiveAst;
import 'compile_element.dart' show CompileElement;
import 'compile_method.dart' show CompileMethod;
import 'constants.dart' show EventHandlerVars;
import 'expression_converter.dart' show convertCdStatementToIr;
import 'parse_utils.dart';

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
  bool _isSimple = true;
  HandlerType _handlerType = HandlerType.notSimple;
  o.Expression _simpleHandler;
  String _methodName;
  o.FnParam _eventParam;

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
    _method = new CompileMethod(compileElement.view.genDebugInfo);
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
    if (_isSimple) {
      _handlerType = hostEvent.handlerType;
      _isSimple = _method.isEmpty && _handlerType != HandlerType.notSimple;
    }
    if (directive != null && directive.isComponent) {
      _hasComponentHostListener = true;
    }
    _method.resetDebugInfo(compileElement.nodeIndex, hostEvent);
    var context = directiveInstance ?? new o.ReadClassMemberExpr('ctx');
    var actionStmts = convertCdStatementToIr(
        compileElement.view.nameResolver,
        context,
        hostEvent.handler,
        this.compileElement.view.component.template.preserveWhitespace);
    _method.addStmts(actionStmts);
  }

  void finish() {
    final stmts = _method.finish();
    if (_isSimple) {
      // If debug info is enabled, the first statement is a call to [dbg], so
      // retrieve last statement to ensure it's the handler invocation.
      _simpleHandler = _extractFunction(convertStmtIntoExpression(stmts.last));
    } else {
      compileElement.view.eventHandlerMethods.add(new o.ClassMethod(
          _methodName, [_eventParam], stmts, null, [o.StmtModifier.Private]));
    }
  }

  void listenToRenderer() {
    final handlerExpr = _createEventHandlerExpr();
    var listenExpr;

    if (isNativeHtmlEvent(eventName)) {
      listenExpr = compileElement.renderNode
          .callMethod('addEventListener', [o.literal(eventName), handlerExpr]);
    } else {
      final appViewUtilsExpr = o.importExpr(Identifiers.appViewUtils);
      final eventManagerExpr = appViewUtilsExpr.prop('eventManager');
      listenExpr = eventManagerExpr.callMethod('addEventListener',
          [compileElement.renderNode, o.literal(eventName), handlerExpr]);
    }

    compileElement.view.createMethod.addStmt(listenExpr.toStmt());
  }

  void listenToDirective(
    DirectiveAst directiveAst,
    o.Expression directiveInstance,
    String observablePropName,
  ) {
    final subscription =
        o.variable('subscription_${compileElement.view.subscriptions.length}');
    final handlerExpr = _createEventHandlerExpr();
    final isMockLike = directiveAst.directive.analyzedClass.isMockLike;
    compileElement.view
      ..subscriptions.add(subscription)
      ..createMethod.addStmt(subscription
          .set(directiveInstance.prop(observablePropName).callMethod(
              o.BuiltinMethod.SubscribeObservable, [handlerExpr],
              checked: isMockLike))
          .toDeclStmt(null, [o.StmtModifier.Final]));
    if (isMockLike) {
      compileElement.view.subscribesToMockLike = true;
    }
  }

  o.Expression _createEventHandlerExpr() {
    var handlerExpr;
    var numArgs;

    if (_isSimple) {
      handlerExpr = _simpleHandler;
      numArgs = _handlerType == HandlerType.simpleNoArgs ? 0 : 1;
    } else {
      handlerExpr = new o.ReadClassMemberExpr(_methodName);
      numArgs = 1;
    }

    final wrapperName = 'eventHandler$numArgs';
    if (_hasComponentHostListener) {
      return compileElement.componentView
          .callMethod(wrapperName, [handlerExpr]);
    } else {
      return new o.InvokeMemberMethodExpr(wrapperName, [handlerExpr]);
    }
  }
}

List<CompileEventListener> collectEventListeners(List<BoundEventAst> hostEvents,
    List<DirectiveAst> dirs, CompileElement compileElement) {
  List<CompileEventListener> eventListeners = [];
  for (var hostEvent in hostEvents) {
    compileElement.view.addBinding(compileElement, hostEvent);
    var listener = CompileEventListener.getOrCreate(
        compileElement, hostEvent.name, eventListeners);
    listener.addAction(hostEvent, null, null);
  }
  for (var i = 0, len = dirs.length; i < len; i++) {
    final directiveAst = dirs[i];
    // Don't collect component host event listeners because they're registered
    // by the component implementation.
    if (directiveAst.directive.isComponent) continue;
    for (var hostEvent in directiveAst.hostEvents) {
      compileElement.view.addBinding(compileElement, hostEvent);
      var listener = CompileEventListener.getOrCreate(
          compileElement, hostEvent.name, eventListeners);
      listener.addAction(hostEvent, directiveAst.directive,
          compileElement.directiveInstances[i]);
    }
  }
  for (int i = 0, len = eventListeners.length; i < len; i++) {
    eventListeners[i].finish();
  }
  return eventListeners;
}

void bindDirectiveOutputs(DirectiveAst directiveAst,
    o.Expression directiveInstance, List<CompileEventListener> eventListeners) {
  directiveAst.directive.outputs.forEach((observablePropName, eventName) {
    for (int i = 0, len = eventListeners.length; i < len; i++) {
      CompileEventListener listener = eventListeners[i];
      if (listener.eventName != eventName) continue;
      listener.listenToDirective(
          directiveAst, directiveInstance, observablePropName);
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

o.Expression _extractFunction(o.Expression returnExpr) {
  assert(returnExpr is o.InvokeMethodExpr);
  var callExpr = returnExpr as o.InvokeMethodExpr;
  return new o.ReadPropExpr(callExpr.receiver, callExpr.name);
}
