import 'package:angular/src/compiler/compile_metadata.dart'
    show CompileDirectiveMetadata;
import 'package:angular/src/compiler/i18n/message.dart';
import 'package:angular/src/compiler/ir/model.dart' as ir;
import 'package:angular/src/compiler/output/output_ast.dart' as o;
import 'package:angular/src/compiler/view_compiler/compile_view.dart';
import 'package:angular/src/compiler/view_compiler/constants.dart';
import 'package:angular/src/compiler/view_compiler/event_binder.dart';
import 'package:angular_compiler/cli.dart';

import 'expression_converter.dart'
    show NameResolver, convertCdExpressionToIr, convertCdStatementToIr;

/// An abstract utility for converting bound values to output expressions.
abstract class BoundValueConverter
    implements ir.BindingSourceVisitor<o.Expression, o.OutputType> {
  final CompileDirectiveMetadata _metadata;
  final o.Expression _implicitReceiver;
  final NameResolver _nameResolver;

  BoundValueConverter(
    this._metadata,
    this._implicitReceiver,
    this._nameResolver,
  );

  /// Creates a bound value converter for a directive change detector.
  ///
  /// The [implicitReceiver] is the receiver on which bound expressions are
  /// implicitly invoked. For example, if [implicitReceiver] is the variable
  /// `ctx`, the expression `foo(bar)` is rewritten as `ctx.foo(ctx.bar)`.
  ///
  /// The [nameResolver] is used to uniquely name any variables created during
  /// the process of converting bound values to expressions.
  factory BoundValueConverter.forDirective(
    CompileDirectiveMetadata metadata,
    o.Expression implicitReceiver,
    NameResolver nameResolver,
  ) = _DirectiveBoundValueConverter;

  /// Creates a bound value converter for expressions in a [view].
  ///
  /// The [implicitReceiver] is the receiver on which bound expressions are
  /// implicitly invoked. For example, if [implicitReceiver] is the variable
  /// `ctx`, the expression `foo(bar)` is rewritten as `ctx.foo(ctx.bar)`.
  factory BoundValueConverter.forView(
    CompileView view,
  ) = _ViewBoundValueConverter;

  o.Expression convertSourceToExpression(
          ir.BindingSource source, o.OutputType type) =>
      source.accept(this, type);

  o.Expression _createI18nMessage(I18nMessage message);

  @override
  o.Expression visitBoundExpression(ir.BoundExpression boundExpression,
          [o.OutputType type]) =>
      convertCdExpressionToIr(
        _nameResolver,
        _implicitReceiver,
        boundExpression.expression,
        boundExpression.sourceSpan,
        _metadata,
        type,
      );

  @override
  o.Expression visitBoundI18nMessage(ir.BoundI18nMessage boundI18nMessage,
          [_]) =>
      _createI18nMessage(boundI18nMessage.value);

  @override
  o.Expression visitStringLiteral(ir.StringLiteral stringLiteral, [_]) =>
      o.literal(stringLiteral.value);

  o.Expression visitSimpleEventHandler(ir.SimpleEventHandler handler, [_]) {
    List<o.Statement> actionStmts = _convertToStatements(handler);
    var returnExpr = convertStmtIntoExpression(actionStmts.last);
    if (returnExpr is! o.InvokeMethodExpr) {
      final message = "Expected method for event binding.";
      throwFailure(handler.sourceSpan?.message(message) ?? message);
    }
    var simpleHandler = extractFunction(returnExpr);
    return wrapHandler(simpleHandler, handler.numArgs);
  }

  List<o.Statement> _convertToStatements(ir.EventHandler handler) {
    if (handler is ir.SimpleEventHandler) {
      return convertCdStatementToIr(
        _nameResolver,
        _implicitReceiver,
        handler.handler,
        handler.sourceSpan,
        _metadata,
      );
    } else if (handler is ir.ComplexEventHandler) {
      return [
        for (var nestedHandler in handler.handlers)
          ..._convertToStatements(nestedHandler)
      ];
    }
    throw ArgumentError.value(
        handler, 'handler', 'Unknown ${ir.EventHandler} type.');
  }

  o.Expression visitComplexEventHandler(ir.ComplexEventHandler handler, [_]) {
    var statements = _convertToStatements(handler);
    return wrapHandler(_createEventHandler(statements, handler), 1);
  }

  o.Expression _createEventHandler(
      List<o.Statement> statements, ir.ComplexEventHandler handler);
}

/// Converts values bound by a directive change detector.
class _DirectiveBoundValueConverter extends BoundValueConverter {
  _DirectiveBoundValueConverter(
    CompileDirectiveMetadata metadata,
    o.Expression implicitReceiver,
    NameResolver nameResolver,
  ) : super(metadata, implicitReceiver, nameResolver);

  @override
  o.Expression _createI18nMessage(I18nMessage message) {
    throw UnsupportedError(
        'Cannot create internationalized message expression without a view');
  }

  @override
  o.Expression _createEventHandler(
      List<o.Statement> statements, ir.ComplexEventHandler handler) {
    throw UnsupportedError(
        'Cannot create event handler expression without a view');
  }
}

// Converts values bound in a view.
class _ViewBoundValueConverter extends BoundValueConverter {
  final CompileView _view;

  _ViewBoundValueConverter(this._view)
      : super(_view.component, DetectChangesVars.cachedCtx, _view.nameResolver);

  @override
  o.Expression _createI18nMessage(I18nMessage message) =>
      _view.createI18nMessage(message);

  @override
  o.Expression _createEventHandler(
          List<o.Statement> statements, ir.ComplexEventHandler handler) =>
      _view.createEventHandler(handler.methodName, statements);
}

o.Expression wrapHandler(o.Expression handlerExpr, int numArgs) =>
    o.InvokeMemberMethodExpr(
      'eventHandler$numArgs',
      [handlerExpr],
    );

o.Expression extractFunction(o.Expression returnExpr) {
  assert(returnExpr is o.InvokeMethodExpr);
  final callExpr = returnExpr as o.InvokeMethodExpr;
  return o.ReadPropExpr(callExpr.receiver, callExpr.name);
}
