import '../analyzed_class.dart';
import '../compile_metadata.dart' show CompileDirectiveMetadata;
import '../expression_parser/ast.dart';
import '../html_events.dart';
import '../output/output_ast.dart' as o;
import '../template_ast.dart' show BoundEventAst, DirectiveAst;
import 'compile_element.dart' show CompileElement;
import 'compile_method.dart' show CompileMethod;
import 'constants.dart' show EventHandlerVars;
import 'expression_converter.dart' show convertCdStatementToIr, NameResolver;
import 'ir/provider_source.dart';
import 'parse_utils.dart';

/// Generates code to listen to a single eventName on a [CompileElement].
///
/// Since multiple directives on an element could potentially listen to the
/// same event, this class collects the individual handlers as actions and
/// creates a single member method on the component that calls each of the
/// handlers and then applies logical AND to determine resulting
/// prevent default value.
class CompileEventListener {
  /// Resolves names used in actions of this event listener.
  ///
  /// Each event listener needs a scoped copy of its view's [NameResolver] to
  /// ensure locals are cached only in the methods they're used.
  final NameResolver _nameResolver;

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
    for (var existingListener in targetEventListeners) {
      if (existingListener.eventName == eventName) return existingListener;
    }
    var listener = CompileEventListener(
        compileElement, eventName, targetEventListeners.length);
    targetEventListeners.add(listener);
    return listener;
  }

  CompileEventListener(this.compileElement, this.eventName, int listenerIndex)
      : _nameResolver = compileElement.view.nameResolver.scope() {
    _method = CompileMethod(compileElement.view.genDebugInfo);
    _methodName =
        '_handle_${sanitizeEventName(eventName)}_${compileElement.nodeIndex}_'
        '$listenerIndex';
    // TODO: type event param as Identifiers.HTML_EVENT if non-custom event or
    // stream.
    _eventParam = o.FnParam(EventHandlerVars.event.name, o.importType(null));
  }

  void _addAction(BoundEventAst hostEvent, CompileDirectiveMetadata directive,
      ProviderSource directiveInstance, AnalyzedClass clazz) {
    if (_isTearoff(hostEvent)) {
      hostEvent = _rewriteTearoff(hostEvent, clazz);
    }
    if (_isSimple) {
      _handlerType = hostEvent.handlerType;
      _isSimple = _method.isEmpty && _handlerType != HandlerType.notSimple;
    }
    if (directive != null && directive.isComponent) {
      _hasComponentHostListener = true;
    }
    var context = directiveInstance?.build() ?? o.ReadClassMemberExpr('ctx');
    var actionStmts = convertCdStatementToIr(_nameResolver, context,
        hostEvent.handler, hostEvent.sourceSpan, compileElement.view.component);
    _method.addStmts(actionStmts);
  }

  void _finish() {
    final stmts = _method.finish();
    if (_isSimple) {
      // If debug info is enabled, the first statement is a call to [dbg], so
      // retrieve last statement to ensure it's the handler invocation.
      _simpleHandler = _extractFunction(convertStmtIntoExpression(stmts.last));
    } else {
      // Declare variables for locals used in this event listener.
      stmts.insertAll(0, _nameResolver.getLocalDeclarations());
      compileElement.view.methods.add(o.ClassMethod(
          _methodName, [_eventParam], stmts, null, [o.StmtModifier.Private]));
    }
  }

  void _listenToRenderer() {
    final handlerExpr = _createEventHandlerExpr();
    if (isNativeHtmlEvent(eventName)) {
      compileElement.view.addDomEventListener(
          compileElement.renderNode, eventName, handlerExpr);
    } else {
      compileElement.view.addCustomEventListener(
          compileElement.renderNode, eventName, handlerExpr);
    }
  }

  void _listenToDirective(
    DirectiveAst directiveAst,
    o.Expression directiveInstance,
    String observablePropName,
  ) {
    final handlerExpr = _createEventHandlerExpr();
    compileElement.view.createSubscription(
        directiveInstance.prop(observablePropName), handlerExpr,
        isMockLike: directiveAst.directive.analyzedClass.isMockLike);
  }

  o.Expression _createEventHandlerExpr() {
    o.Expression handlerExpr;
    var numArgs;

    if (_isSimple) {
      handlerExpr = _simpleHandler;
      numArgs = _handlerType == HandlerType.simpleNoArgs ? 0 : 1;
    } else {
      handlerExpr = o.ReadClassMemberExpr(_methodName);
      numArgs = 1;
    }

    final wrapperName = 'eventHandler$numArgs';
    if (_hasComponentHostListener) {
      return compileElement.componentView
          .callMethod(wrapperName, [handlerExpr]);
    } else {
      return o.InvokeMemberMethodExpr(wrapperName, [handlerExpr]);
    }
  }

  bool _isTearoff(BoundEventAst hostEvent) =>
      _handler(hostEvent) is PropertyRead;

  BoundEventAst _rewriteTearoff(BoundEventAst hostEvent, AnalyzedClass clazz) =>
      BoundEventAst(hostEvent.name, rewriteTearoff(_handler(hostEvent), clazz),
          hostEvent.sourceSpan);

  AST _handler(BoundEventAst hostEvent) {
    var eventHandler = hostEvent.handler;
    if (eventHandler is ASTWithSource) {
      return eventHandler.ast;
    }
    return eventHandler;
  }
}

List<CompileEventListener> collectEventListeners(
    List<BoundEventAst> hostEvents,
    List<DirectiveAst> dirs,
    CompileElement compileElement,
    AnalyzedClass analyzedClass) {
  List<CompileEventListener> eventListeners = [];
  for (var hostEvent in hostEvents) {
    var listener = CompileEventListener.getOrCreate(
        compileElement, hostEvent.name, eventListeners);
    listener._addAction(hostEvent, null, null, analyzedClass);
  }
  for (var i = 0, len = dirs.length; i < len; i++) {
    final directiveAst = dirs[i];
    // Don't collect component host event listeners because they're registered
    // by the component implementation.
    if (directiveAst.directive.isComponent) continue;
    for (var hostEvent in directiveAst.hostEvents) {
      var listener = CompileEventListener.getOrCreate(
          compileElement, hostEvent.name, eventListeners);
      listener._addAction(hostEvent, directiveAst.directive,
          compileElement.directiveInstances[i], analyzedClass);
    }
  }
  for (int i = 0, len = eventListeners.length; i < len; i++) {
    eventListeners[i]._finish();
  }
  return eventListeners;
}

void bindDirectiveOutputs(DirectiveAst directiveAst,
    o.Expression directiveInstance, List<CompileEventListener> eventListeners) {
  directiveAst.directive.outputs.forEach((observablePropName, eventName) {
    for (var listener in eventListeners) {
      if (listener.eventName != eventName) continue;
      listener._listenToDirective(
          directiveAst, directiveInstance, observablePropName);
    }
  });
}

void bindRenderOutputs(List<CompileEventListener> eventListeners) {
  for (var listener in eventListeners) {
    listener._listenToRenderer();
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
  return o.ReadPropExpr(callExpr.receiver, callExpr.name);
}
