import '../expression_parser/ast.dart'
    show AST, ASTWithSource, ImplicitReceiver, MethodCall, PropertyRead;
import 'constants.dart';

enum HandlerType { simpleNoArgs, simpleOneArg, notSimple }

/// Classifies this event binding by it's form.
///
/// The simple form looks like
///
///     (event)="handler($event)"
///
/// or
///
///     (event)="handler()"
///
/// Since these types of handlers are so common, we can optimize the code
/// generated for them.
HandlerType handlerTypeFromExpression(AST handler) {
  var eventHandler = handler;
  if (eventHandler is ASTWithSource) {
    eventHandler = (eventHandler as ASTWithSource).ast;
  }
  if (eventHandler is! MethodCall) {
    return HandlerType.notSimple;
  }
  var call = eventHandler as MethodCall;
  if (call.receiver is! ImplicitReceiver) {
    return HandlerType.notSimple;
  }
  if (call.args.isEmpty) {
    return HandlerType.simpleNoArgs;
  }
  if (call.args.length != 1) {
    return HandlerType.notSimple;
  }
  var singleArg = call.args.single;
  if (singleArg is! PropertyRead) {
    return HandlerType.notSimple;
  }
  var property = singleArg as PropertyRead;
  if (property.name == EventHandlerVars.event.name &&
      property.receiver is ImplicitReceiver) {
    return HandlerType.simpleOneArg;
  } else {
    return HandlerType.notSimple;
  }
}

final RegExp _eventNameRegExp = new RegExp(r'[^a-zA-Z0-9_]');

/// Sanitizes event name so it can be used to construct a class member
/// handler method name.
String sanitizeEventName(String name) {
  return name.replaceAll(_eventNameRegExp, '_');
}
