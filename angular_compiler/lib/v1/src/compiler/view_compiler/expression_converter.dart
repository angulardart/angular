import 'package:source_span/source_span.dart' show SourceSpan;
import 'package:angular_compiler/v1/src/compiler/analyzed_class.dart';
import 'package:angular_compiler/v1/src/compiler/chars.dart';
import 'package:angular_compiler/v1/src/compiler/compile_metadata.dart'
    show CompileDirectiveMetadata;
import 'package:angular_compiler/v1/src/compiler/expression_parser/ast.dart'
    as compiler_ast;
import 'package:angular_compiler/v1/src/compiler/identifiers.dart';
import 'package:angular_compiler/v1/src/compiler/output/output_ast.dart' as o;
import 'package:angular_compiler/v2/context.dart';

final _implicitReceiverVal = o.variable('#implicit');

abstract class NameResolver {
  o.Expression callPipe(
    String name,
    o.Expression input,
    List<o.Expression> args,
  );

  /// Returns a variable that references the [name] local.
  o.Expression? getLocal(String name);

  /// Returns variable declarations for all locals used in this scope.
  List<o.Statement> getLocalDeclarations();

  int createUniqueBindIndex();

  /// Creates a name resolver with shared state for use in a new method scope.
  NameResolver scope();
}

/// Converts a bound [AST] expression to an [o.Expression].
///
/// If specified, [boundType] is the type of the input to which [expression] is
/// bound. This is used to support empty expressions for boolean inputs, and to
/// type annotate collection literal bindings.
o.Expression convertCdExpressionToIr(
  NameResolver nameResolver,
  o.Expression implicitReceiver,
  compiler_ast.AST expression,
  SourceSpan? expressionSourceSpan,
  CompileDirectiveMetadata metadata, {
  o.OutputType? boundType,
}) {
  final visitor = _AstToExpressionVisitor(
    nameResolver,
    implicitReceiver,
    metadata,
    boundType,
  );
  return _visit(expression, visitor, expressionSourceSpan);
}

/// Visits [ast] using [visitor].
///
/// If [span] is non-null, it will be used to provide context to any
/// [BuildError] thrown by [visitor].
R _visit<R>(
  compiler_ast.AST ast,
  compiler_ast.AstVisitor<R, bool> visitor,
  SourceSpan? span,
) {
  try {
    return ast.visit(visitor, true /* visitingRoot */);
  } on BuildError catch (e) {
    if (span == null) rethrow;
    throw BuildError.forSourceSpan(span, e.toString());
  }
}

class _AstToExpressionVisitor
    implements compiler_ast.AstVisitor<o.Expression, bool> {
  final NameResolver _nameResolver;
  final o.Expression _implicitReceiver;
  final CompileDirectiveMetadata _metadata;

  /// The type to which this expression is bound.
  ///
  /// This is used to support empty expressions for booleans bindings, and type
  /// pure proxy fields for collection literals.
  final o.OutputType? _boundType;

  _AstToExpressionVisitor(
    this._nameResolver,
    this._implicitReceiver,
    this._metadata,
    this._boundType,
  );

  @override
  o.Expression visitBinary(compiler_ast.Binary ast, _) {
    o.BinaryOperator op;
    switch (ast.operator) {
      case '+':
        op = o.BinaryOperator.Plus;
        break;
      case '-':
        op = o.BinaryOperator.Minus;
        break;
      case '*':
        op = o.BinaryOperator.Multiply;
        break;
      case '/':
        op = o.BinaryOperator.Divide;
        break;
      case '%':
        op = o.BinaryOperator.Modulo;
        break;
      case '&&':
        op = o.BinaryOperator.And;
        break;
      case '||':
        op = o.BinaryOperator.Or;
        break;
      case '==':
        op = o.BinaryOperator.Equals;
        break;
      case '!=':
        op = o.BinaryOperator.NotEquals;
        break;
      case '===':
        op = o.BinaryOperator.Identical;
        break;
      case '!==':
        op = o.BinaryOperator.NotIdentical;
        break;
      case '<':
        op = o.BinaryOperator.Lower;
        break;
      case '>':
        op = o.BinaryOperator.Bigger;
        break;
      case '<=':
        op = o.BinaryOperator.LowerEquals;
        break;
      case '>=':
        op = o.BinaryOperator.BiggerEquals;
        break;
      default:
        throw BuildError.withoutContext(
          'Unsupported operation "${ast.operator}"',
        );
    }
    return o.BinaryOperatorExpr(
      op,
      ast.left.visit(this, false /* visitingRoot */),
      ast.right.visit(this, false /* visitingRoot */),
    );
  }

  @override
  o.Expression visitConditional(compiler_ast.Conditional ast, _) {
    var value = ast.condition.visit(this, false /* visitingRoot */);
    return value.conditional(
      ast.trueExp.visit(this, false /* visitingRoot */),
      ast.falseExp.visit(this, false /* visitingRoot */),
    );
  }

  @override
  o.Expression visitEmptyExpr(compiler_ast.EmptyExpr ast, _) =>
      _isBoolType(_boundType)
          ? o.LiteralExpr(true, o.BOOL_TYPE)
          : o.LiteralExpr('', o.STRING_TYPE);

  @override
  o.Expression visitPipe(compiler_ast.BindingPipe ast, _) {
    var input = ast.exp.visit(this, false /* visitingRoot */);
    var args = _visitAll(ast.args, false /* visitingRoot */);
    var value = _nameResolver.callPipe(ast.name, input, args);
    return value;
  }

  @override
  o.Expression visitFunctionCall(compiler_ast.FunctionCall ast, _) {
    var e = ast.target.visit(this, false /* visitingRoot */);
    return e.callFn(_visitAll(ast.args, false /* visitingRoot */),
        namedParams: _visitAll(ast.namedArgs, false /* visitingRoot */)
            .cast<o.NamedExpr>());
  }

  @override
  o.Expression visitIfNull(compiler_ast.IfNull ast, _) {
    var value = ast.condition.visit(this, false /* visitingRoot */);
    return value.ifNull(ast.nullExp.visit(this, false /* visitingRoot */));
  }

  @override
  o.Expression visitImplicitReceiver(compiler_ast.ImplicitReceiver ast, _) =>
      _implicitReceiverVal;

  /// Trim text in preserve whitespace mode if it contains \n preceding
  /// interpolation.
  String _compressWhitespacePreceding(String value) {
    if (_metadata.template!.preserveWhitespace! ||
        value.contains('\u00A0') ||
        value.contains(ngSpace) ||
        !value.contains('\n')) return replaceNgSpace(value);
    return replaceNgSpace(value.replaceAll('\n', '').trimLeft());
  }

  /// Trim text in preserve whitespace mode if it contains \n following
  /// interpolation.
  String _compressWhitespaceFollowing(String value) {
    if (_metadata.template!.preserveWhitespace! ||
        value.contains('\u00A0') ||
        value.contains(ngSpace) ||
        !value.contains('\n')) return replaceNgSpace(value);
    return replaceNgSpace(value.replaceAll('\n', '').trimRight());
  }

  @override
  o.Expression visitInterpolation(compiler_ast.Interpolation ast, _) {
    final expressionsAreString =
        ast.expressions.every((ast) => isString(ast, _metadata.analyzedClass!));

    final interpolateIdentifiers = expressionsAreString
        ? Interpolation.interpolateString
        : Interpolation.interpolate;

    /// Handle most common case where prefix and postfix are empty.
    if (ast.expressions.length == 1) {
      var firstArg = _compressWhitespacePreceding(ast.strings[0]);
      var secondArg = _compressWhitespaceFollowing(ast.strings[1]);
      final firstExpression = ast.expressions[0];
      final expressionArg =
          firstExpression.visit(this, false /* visitingRoot */);
      if (_isPrimitiveCheck(firstExpression, _metadata.analyzedClass)) {
        // If the interpolated expression is a primitive type, check the
        // expression directly (instead of checking the interpolated result)
        // as an optimization.
        return expressionArg;
      }
      if (firstArg.isEmpty && secondArg.isEmpty) {
        if (firstExpression is compiler_ast.LiteralPrimitive) {
          if (firstExpression.value == null) {
            return o.literal('');
          } else {
            return o.literal('${firstExpression.value}');
          }
        }
        var args = <o.Expression>[expressionArg];
        return o.importExpr(interpolateIdentifiers[0]).callFn(args);
      } else {
        var args = <o.Expression>[
          o.literal(firstArg),
          expressionArg,
          o.literal(secondArg),
        ];
        return o.importExpr(interpolateIdentifiers[1]).callFn(args);
      }
    } else {
      var args = <o.Expression>[];
      for (var i = 0; i < ast.strings.length - 1; i++) {
        var literalText = i == 0
            ? _compressWhitespacePreceding(ast.strings[i])
            : replaceNgSpace(ast.strings[i]);
        args.add(o.literal(literalText));
        args.add(ast.expressions[i].visit(this, false /* visitingRoot */));
      }
      args.add(o.literal(
          _compressWhitespaceFollowing(ast.strings[ast.strings.length - 1])));
      if (ast.expressions.length < 3) {
        return o
            .importExpr(interpolateIdentifiers[ast.expressions.length])
            .callFn(args);
      } else {
        return o
            .importExpr(Interpolation.interpolateFallback)
            .callFn([o.literalArr(args)]);
      }
    }
  }

  @override
  o.Expression visitKeyedRead(compiler_ast.KeyedRead ast, _) => ast.receiver
      .visit(this, false /* visitingRoot */)
      .key(ast.key.visit(this, false /* visitingRoot */));

  @override
  o.Expression visitKeyedWrite(compiler_ast.KeyedWrite ast, _) {
    var obj = ast.receiver.visit(this, false /* visitingRoot */);
    var key = ast.key.visit(this, false /* visitingRoot */);
    var value = ast.value.visit(this, false /* visitingRoot */);
    return obj.key(key).set(value);
  }

  @override
  o.Expression visitLiteralPrimitive(compiler_ast.LiteralPrimitive ast, _) =>
      o.literal(ast.value);

  @override
  o.Expression visitMethodCall(compiler_ast.MethodCall ast, _) {
    var args = _visitAll(ast.args, false /*visitingRoot */);
    var namedArgs =
        _visitAll(ast.namedArgs, false /*visitingRoot */).cast<o.NamedExpr>();
    var receiver = ast.receiver.visit(this, false /*visitingRoot */);
    if (identical(receiver, _implicitReceiverVal)) {
      var varExpr = _nameResolver.getLocal(ast.name);
      if (varExpr != null) {
        return varExpr.callFn(args, namedParams: namedArgs);
      } else {
        receiver =
            _getImplicitOrStaticReceiver(ast.name, isStaticGetterOrMethod);
      }
    }
    return receiver.callMethod(ast.name, args, namedParams: namedArgs);
  }

  @override
  o.Expression visitPostfixNotNull(compiler_ast.PostfixNotNull ast, _) =>
      ast.expression.visit(this, false /*visitingRoot */).notNull();

  @override
  o.Expression visitPrefixNot(compiler_ast.PrefixNot ast, _) =>
      o.not(ast.expression.visit(this, false /*visitingRoot */));

  @override
  o.Expression visitPropertyRead(compiler_ast.PropertyRead ast, _) {
    var receiver = ast.receiver.visit(this, false /*visitingRoot */);
    if (identical(receiver, _implicitReceiverVal)) {
      var result = _nameResolver.getLocal(ast.name);
      if (result != null) {
        return result;
      }
      receiver = _getImplicitOrStaticReceiver(ast.name, isStaticGetterOrMethod);
    }
    return receiver.prop(ast.name);
  }

  @override
  o.Expression visitPropertyWrite(compiler_ast.PropertyWrite ast, _) {
    var receiver = ast.receiver.visit(this, false /*visitingRoot */);
    if (identical(receiver, _implicitReceiverVal)) {
      var varExpr = _nameResolver.getLocal(ast.name);
      if (varExpr != null) {
        throw BuildError.withoutContext(
          'Cannot assign to a reference or variable "${ast.name}"',
        );
      }
      receiver = _getImplicitOrStaticReceiver(ast.name, isStaticSetter);
    }
    return receiver
        .prop(ast.name)
        .set(ast.value.visit(this, false /*visitingRoot */));
  }

  @override
  o.Expression visitSafePropertyRead(compiler_ast.SafePropertyRead ast, _) {
    var receiver = ast.receiver.visit(this, false /*visitingRoot */);
    return receiver.prop(ast.name, checked: true);
  }

  @override
  o.Expression visitSafeMethodCall(compiler_ast.SafeMethodCall ast, _) {
    var receiver = ast.receiver.visit(this, false /*visitingRoot */);
    var args = _visitAll(ast.args, false /*visitingRoot */);
    return receiver.callMethod(ast.name, args, checked: true);
  }

  @override
  o.Expression visitStaticRead(compiler_ast.StaticRead ast, _) =>
      o.importExpr(ast.id.identifier);

  @override
  o.Expression visitNamedExpr(compiler_ast.NamedExpr ast, _) => o.NamedExpr(
      ast.name, ast.expression!.visit(this, false /*visitingRoot */));

  @override
  o.Expression visitVariableRead(compiler_ast.VariableRead ast, _) =>
      o.ReadVarExpr(ast.name);

  List<o.Expression> _visitAll(List<compiler_ast.AST> asts, bool visitingRoot) {
    final expressions = <o.Expression>[];
    for (var ast in asts) {
      expressions.add(ast.visit(this, visitingRoot));
    }
    return expressions;
  }

  /// Returns the receiver necessary to access [memberName].
  ///
  /// If [memberName] is a static member of the current view's component,
  /// determined by the predicate [isStaticMember], the static receiver is
  /// returned. Otherwise the implicit receiver is returned.
  o.Expression _getImplicitOrStaticReceiver(
    String memberName,
    bool Function(String, AnalyzedClass) isStaticMember,
  ) {
    return isStaticMember(memberName, _metadata.analyzedClass!)
        ? o.importExpr(_metadata.identifier!)
        : _implicitReceiver;
  }
}

bool _isBoolType(o.OutputType? type) {
  if (type == o.BOOL_TYPE) return true;
  if (type is o.ExternalType) {
    var name = type.value.name;
    return 'bool' == name.trim();
  }
  return false;
}

bool _isPrimitiveCheck(
    compiler_ast.AST expression, AnalyzedClass? analyzedClass) {
  return (!isImmutable(expression, analyzedClass) &&
      (isBool(expression, analyzedClass!) ||
          isNumber(expression, analyzedClass) ||
          isDouble(expression, analyzedClass) ||
          isInt(expression, analyzedClass)));
}
