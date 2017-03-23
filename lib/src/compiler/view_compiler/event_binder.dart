import '../compile_metadata.dart' show CompileDirectiveMetadata;
import '../output/output_ast.dart' as o;
import '../template_ast.dart' show BoundEventAst, DirectiveAst;
import 'compile_binding.dart' show CompileBinding;
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
    if (_isSimple) {
      _handlerType = hostEvent.handlerType;
      _isSimple =
          _actionResultExprs.isEmpty && _handlerType != HandlerType.notSimple;
    }
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
      if (_isSimple) {
        _simpleHandler = _extractFunction(returnExpr);
      }
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
    // If this is a simple event binding, we don't need to generate a method.
    if (_isSimple) {
      return;
    }
    var markPathToRootStart =
        _hasComponentHostListener ? compileElement.compViewExpr : o.THIS_EXPR;
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
    o.Expression eventListener;
    if (!_isSimple) {
      eventListener = new o.InvokeMemberMethodExpr(
          'evt', [new o.ReadClassMemberExpr(_methodName)]);
    } else {
      var appView =
          _hasComponentHostListener ? compileElement.compViewExpr : o.THIS_EXPR;
      var handler = _simpleHandler;
      eventListener = appView.callMethod(
          'eventHandler${_handlerType == HandlerType.simpleNoArgs ? 0 : 1}',
          [handler]);
      // If native DOM event, bypass plugin system.
      if (isNativeHtmlEvent(eventName)) {
        o.Expression expr = compileElement.renderNode.callMethod(
            'addEventListener', [o.literal(eventName), eventListener]);
        compileElement.view.createMethod.addStmt(expr.toStmt());
        return;
      }
    }
    o.Expression listenExpr = new o.InvokeMemberMethodExpr('listen',
        [compileElement.renderNode, o.literal(eventName), eventListener]);

    compileElement.view.createMethod.addStmt(listenExpr.toStmt());
  }

  void listenToDirective(
      o.Expression directiveInstance, String observablePropName) {
    var subscription =
        o.variable('subscription_${compileElement.view.subscriptions.length}');
    this.compileElement.view.subscriptions.add(subscription);
    o.Expression eventListener;
    if (!_isSimple) {
      eventListener = new o.InvokeMemberMethodExpr(
          'evt', [new o.ReadClassMemberExpr(_methodName)]);
    } else {
      var appView =
          _hasComponentHostListener ? compileElement.compViewExpr : o.THIS_EXPR;
      var handler = _simpleHandler;
      eventListener = appView.callMethod(
          'eventHandler${_handlerType == HandlerType.simpleNoArgs ? 0 : 1}',
          [handler]);
    }
    this.compileElement.view.createMethod.addStmt(subscription
        .set(directiveInstance
            .prop(observablePropName)
            .callMethod(o.BuiltinMethod.SubscribeObservable, [eventListener]))
        .toDeclStmt(null, [o.StmtModifier.Final]));
  }
}

List<CompileEventListener> collectEventListeners(List<BoundEventAst> hostEvents,
    List<DirectiveAst> dirs, CompileElement compileElement,
    {bool includeComponentOutputs: true}) {
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
    if (includeComponentOutputs == false &&
        directiveAst.directive.isComponent) {
      continue;
    }
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

o.Expression _extractFunction(o.Expression returnExpr) {
  assert(returnExpr is o.InvokeMethodExpr);
  var callExpr = returnExpr as o.InvokeMethodExpr;
  return new o.ReadPropExpr(callExpr.receiver, callExpr.name);
}

Set<String> _nativeEventSet;

/// Returns true if event is an html event that is handled by DOM apis
/// directly and doesn't need to go through plugin system.
bool isNativeHtmlEvent(String eventName) {
  const commonEvents = const <String>[
    'abort',
    'afterprint',
    'animationend',
    'animationiteration',
    'animationstart',
    'appinstalled',
    'audioend',
    'audiostart',
    'beforeprint',
    'beforeunload',
    'blur',
    'change',
    'click',
    'compositionend',
    'compositionstart',
    'compositionupdate',
    'contextmenu',
    'dblclick',
    'drag',
    'dragend',
    'dragenter',
    'dragleave',
    'dragover',
    'dragstart',
    'drop',
    'error',
    'focus',
    'fullscreenchange',
    'fullscreenerror',
    'gotpointercapture',
    'lostpointercapture',
    'input',
    'invalid',
    'keydown',
    'keypress',
    'keyup',
    'languagechange',
    'load',
    'mousedown',
    'mouseenter',
    'mouseleave',
    'mousemove',
    'mouseout',
    'mouseover',
    'mouseup',
    'notificationclick',
    'orientationchange',
    'pause',
    'pointercancel',
    'pointerdown',
    'pointerenter',
    'pointerleave',
    'pointerlockchange',
    'pointerlockerror',
    'pointermove',
    'pointerout',
    'pointerover',
    'pointerup',
    'reset',
    'resize',
    'scroll',
    'select',
    'show',
    'touchcancel',
    'touchend',
    'touchmove',
    'touchstart',
    'transitionend',
    'unload',
    'wheel'
  ];
  if (_nativeEventSet == null) {
    _nativeEventSet = new Set<String>();
    for (String name in commonEvents) {
      _nativeEventSet.add(name);
    }
  }
  return _nativeEventSet.contains(eventName);
}
