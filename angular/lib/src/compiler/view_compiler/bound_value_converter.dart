import 'package:angular/src/compiler/compile_metadata.dart'
    show CompileDirectiveMetadata;
import 'package:angular/src/compiler/i18n/message.dart';
import 'package:angular/src/compiler/ir/model.dart' as ir;
import 'package:angular/src/compiler/output/output_ast.dart' as o;
import 'package:angular/src/compiler/view_compiler/compile_view.dart';
import 'package:angular/src/compiler/view_compiler/constants.dart';
import 'package:angular_compiler/cli.dart';

import 'expression_converter.dart' show NameResolver, convertCdExpressionToIr;

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

  /// Creates a new [BoundValueConverter] with a scoped [NameResolver].
  BoundValueConverter scopeNamespace();

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
        boundExpression.expression.ast,
        boundExpression.sourceSpan,
        _metadata,
        boundType: type,
      );

  @override
  o.Expression visitBoundI18nMessage(ir.BoundI18nMessage boundI18nMessage,
          [_]) =>
      _createI18nMessage(boundI18nMessage.value);

  @override
  o.Expression visitStringLiteral(ir.StringLiteral stringLiteral, [_]) =>
      o.literal(stringLiteral.value);

  @override
  o.Expression visitSimpleEventHandler(ir.SimpleEventHandler handler, [_]) {
    var expr = _convertToExpression(handler);
    if (expr is o.InvokeMethodExpr) {
      var tearOff = _tearOffSimpleHandler(expr);
      return _wrapHandler(tearOff, handler.numArgs);
    }
    final message = "Expected method for event binding.";
    throwFailure(handler.sourceSpan?.message(message) ?? message);
  }

  /// Converts a [method] invocation to a tear-off.
  ///
  /// This doesn't retain any of [method]'s argument, but is only used for
  /// simple event handlers where the arguments are known to be nothing, or the
  /// event itself.
  o.Expression _tearOffSimpleHandler(o.InvokeMethodExpr method) =>
      o.ReadPropExpr(method.receiver, method.name);

  @override
  o.Expression visitComplexEventHandler(ir.ComplexEventHandler handler, [_]) {
    var statements = _convertToStatements(handler);
    return _wrapHandler(_createEventHandler(statements), 1);
  }

  o.Expression _convertToExpression(ir.SimpleEventHandler handler) {
    return convertCdExpressionToIr(
      _nameResolver,
      // If the handler has a directive instance set, then we'll use that as
      // the implicit receiver for the handler expression. Otherwise, we
      // assume the default receiver for the view.
      handler.directiveInstance?.build() ?? _implicitReceiver,
      handler.handler.ast,
      handler.sourceSpan,
      _metadata,
    );
  }

  List<o.Statement> _convertToStatements(ir.ComplexEventHandler handler) {
    return [
      for (final handler in handler.handlers)
        if (handler is ir.SimpleEventHandler)
          _convertToExpression(handler).toStmt()
        else if (handler is ir.ComplexEventHandler)
          ..._convertToStatements(handler)
        else
          throw ArgumentError('Unknown ${ir.EventHandler} type: $handler')
    ];
  }

  o.Expression _wrapHandler(o.Expression handlerExpr, int numArgs) =>
      o.InvokeMemberMethodExpr(
        'eventHandler$numArgs',
        [handlerExpr],
      );

  o.Expression _createEventHandler(List<o.Statement> statements);
}

/// Converts values bound by a directive change detector.
class _DirectiveBoundValueConverter extends BoundValueConverter {
  _DirectiveBoundValueConverter(
    CompileDirectiveMetadata metadata,
    o.Expression implicitReceiver,
    NameResolver nameResolver,
  ) : super(metadata, implicitReceiver, nameResolver);

  @override
  BoundValueConverter scopeNamespace() => _DirectiveBoundValueConverter(
        _metadata,
        _implicitReceiver,
        _nameResolver.scope(),
      );

  @override
  o.Expression _createI18nMessage(I18nMessage message) {
    throw UnsupportedError(
        'Cannot create internationalized message expression without a view');
  }

  @override
  o.Expression _createEventHandler(List<o.Statement> statements) {
    throw UnsupportedError(
        'Cannot create event handler expression without a view');
  }
}

// Converts values bound in a view.
class _ViewBoundValueConverter extends BoundValueConverter {
  final CompileView _view;

  _ViewBoundValueConverter(this._view, {NameResolver nameResolver})
      : super(
          _view.component,
          DetectChangesVars.cachedCtx,
          nameResolver ?? _view.nameResolver,
        );

  @override
  o.Expression _createI18nMessage(I18nMessage message) =>
      _view.createI18nMessage(message);

  @override
  o.Expression _createEventHandler(List<o.Statement> statements) =>
      _view.createEventHandler(
        statements,
        localDeclarations: _nameResolver.getLocalDeclarations(),
      );

  @override
  BoundValueConverter scopeNamespace() =>
      _ViewBoundValueConverter(_view, nameResolver: _nameResolver.scope());
}
