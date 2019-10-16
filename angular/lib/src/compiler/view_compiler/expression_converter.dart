import 'package:source_span/source_span.dart' show SourceSpan;
import 'package:angular/src/compiler/analyzed_class.dart';
import 'package:angular/src/compiler/chars.dart';
import 'package:angular/src/compiler/compile_metadata.dart'
    show CompileDirectiveMetadata;
import 'package:angular/src/compiler/expression_parser/ast.dart'
    as compiler_ast;
import 'package:angular/src/compiler/identifiers.dart';
import 'package:angular/src/compiler/output/output_ast.dart' as o;
import 'package:angular_compiler/cli.dart';

final _implicitReceiverVal = o.variable("#implicit");

abstract class NameResolver {
  o.Expression callPipe(
    String name,
    o.Expression input,
    List<o.Expression> args,
  );

  /// Returns a variable that references the [name] local.
  o.Expression getLocal(String name);

  /// Returns variable declarations for all locals used in this scope.
  List<o.Statement> getLocalDeclarations();

  /// Creates a closure that returns a list of [type] when [values] change.
  o.Expression createLiteralList(
    List<o.Expression> values, {
    o.OutputType type,
  });

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
  SourceSpan expressionSourceSpan,
  CompileDirectiveMetadata metadata, {
  o.OutputType boundType,
}) {
  assert(nameResolver != null);
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
  SourceSpan span,
) {
  try {
    return ast.visit(visitor, true /* visitingRoot */);
  } on BuildError catch (e) {
    if (span == null) rethrow;
    throwFailure(span.message(e.message));
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
  final o.OutputType _boundType;

  _AstToExpressionVisitor(
    this._nameResolver,
    this._implicitReceiver,
    this._metadata,
    this._boundType,
  ) {
    assert(_nameResolver != null);
  }

  @override
  o.Expression visitBinary(compiler_ast.Binary ast, _) {
    o.BinaryOperator op;
    switch (ast.operation) {
      case "+":
        op = o.BinaryOperator.Plus;
        break;
      case "-":
        op = o.BinaryOperator.Minus;
        break;
      case "*":
        op = o.BinaryOperator.Multiply;
        break;
      case "/":
        op = o.BinaryOperator.Divide;
        break;
      case "%":
        op = o.BinaryOperator.Modulo;
        break;
      case "&&":
        op = o.BinaryOperator.And;
        break;
      case "||":
        op = o.BinaryOperator.Or;
        break;
      case "==":
        op = o.BinaryOperator.Equals;
        break;
      case "!=":
        op = o.BinaryOperator.NotEquals;
        break;
      case "===":
        op = o.BinaryOperator.Identical;
        break;
      case "!==":
        op = o.BinaryOperator.NotIdentical;
        break;
      case "<":
        op = o.BinaryOperator.Lower;
        break;
      case ">":
        op = o.BinaryOperator.Bigger;
        break;
      case "<=":
        op = o.BinaryOperator.LowerEquals;
        break;
      case ">=":
        op = o.BinaryOperator.BiggerEquals;
        break;
      default:
        throwFailure('Unsupported operation "${ast.operation}"');
    }
    return o.BinaryOperatorExpr(
      op,
      ast.left.visit(this, false /* visitingRoot */),
      ast.right.visit(this, false /* visitingRoot */),
    );
  }

  @override
  o.Expression visitConditional(compiler_ast.Conditional ast, _) {
    o.Expression value = ast.condition.visit(this, false /* visitingRoot */);
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
    o.Expression e = ast.target.visit(this, false /* visitingRoot */);
    return e.callFn(_visitAll(ast.args, false /* visitingRoot */),
        namedParams: _visitAll(ast.namedArgs, false /* visitingRoot */)
            .cast<o.NamedExpr>());
  }

  @override
  o.Expression visitIfNull(compiler_ast.IfNull ast, _) {
    o.Expression value = ast.condition.visit(this, false /* visitingRoot */);
    return value.ifNull(ast.nullExp.visit(this, false /* visitingRoot */));
  }

  @override
  o.Expression visitImplicitReceiver(compiler_ast.ImplicitReceiver ast, _) =>
      _implicitReceiverVal;

  /// Trim text in preserve whitespace mode if it contains \n preceding
  /// interpolation.
  String _compressWhitespacePreceding(String value) {
    if (_metadata.template.preserveWhitespace ||
        value.contains('\u00A0') ||
        value.contains(ngSpace) ||
        !value.contains('\n')) return replaceNgSpace(value);
    return replaceNgSpace(value.replaceAll('\n', '').trimLeft());
  }

  /// Trim text in preserve whitespace mode if it contains \n following
  /// interpolation.
  String _compressWhitespaceFollowing(String value) {
    if (_metadata.template.preserveWhitespace ||
        value.contains('\u00A0') ||
        value.contains(ngSpace) ||
        !value.contains('\n')) return replaceNgSpace(value);
    return replaceNgSpace(value.replaceAll('\n', '').trimRight());
  }

  @override
  o.Expression visitInterpolation(compiler_ast.Interpolation ast, _) {
    final expressionsAreString =
        ast.expressions.every((ast) => isString(ast, _metadata.analyzedClass));

    final interpolateIdentifiers = expressionsAreString
        ? Interpolation.interpolateString
        : Interpolation.interpolate;

    /// Handle most common case where prefix and postfix are empty.
    if (ast.expressions.length == 1) {
      String firstArg = _compressWhitespacePreceding(ast.strings[0]);
      String secondArg = _compressWhitespaceFollowing(ast.strings[1]);
      final firstExpression = ast.expressions[0];
      if (firstArg.isEmpty && secondArg.isEmpty) {
        if (firstExpression is compiler_ast.LiteralPrimitive) {
          if (firstExpression.value == null) {
            return o.literal('');
          } else {
            return o.literal('${firstExpression.value}');
          }
        }
        var args = <o.Expression>[
          firstExpression.visit(this, false /* visitingRoot */)
        ];
        return o.importExpr(interpolateIdentifiers[0]).callFn(args);
      } else {
        var args = <o.Expression>[
          o.literal(firstArg),
          firstExpression.visit(this, false /* visitingRoot */),
          o.literal(secondArg),
        ];
        return o.importExpr(interpolateIdentifiers[1]).callFn(args);
      }
    } else {
      var args = <o.Expression>[];
      for (var i = 0; i < ast.strings.length - 1; i++) {
        String literalText = i == 0
            ? _compressWhitespacePreceding(ast.strings[i])
            : replaceNgSpace(ast.strings[i]);
        args.add(o.literal(literalText));
        args.add(ast.expressions[i].visit(this, false /* visitingRoot */));
      }
      args.add(o.literal(
          _compressWhitespaceFollowing(ast.strings[ast.strings.length - 1])));
      return o
          .importExpr(interpolateIdentifiers[ast.expressions.length])
          .callFn(args);
    }
  }

  @override
  o.Expression visitKeyedRead(compiler_ast.KeyedRead ast, _) => ast.obj
      .visit(this, false /* visitingRoot */)
      .key(ast.key.visit(this, false /* visitingRoot */));

  @override
  o.Expression visitKeyedWrite(compiler_ast.KeyedWrite ast, _) {
    o.Expression obj = ast.obj.visit(this, false /* visitingRoot */);
    o.Expression key = ast.key.visit(this, false /* visitingRoot */);
    o.Expression value = ast.value.visit(this, false /* visitingRoot */);
    return obj.key(key).set(value);
  }

  @override
  o.Expression visitLiteralArray(
      compiler_ast.LiteralArray ast, bool visitingRoot) {
    return _nameResolver.createLiteralList(
      _visitAll(ast.expressions, false /*visitingRoot */),
      type: visitingRoot ? _boundType : null,
    );
  }

  @override
  o.Expression visitLiteralPrimitive(compiler_ast.LiteralPrimitive ast, _) =>
      o.literal(ast.value);

  @override
  o.Expression visitMethodCall(compiler_ast.MethodCall ast, _) {
    var args = _visitAll(ast.args, false /*visitingRoot */);
    var namedArgs =
        _visitAll(ast.namedArgs, false /*visitingRoot */).cast<o.NamedExpr>();
    o.Expression receiver = ast.receiver.visit(this, false /*visitingRoot */);
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
  o.Expression visitPrefixNot(compiler_ast.PrefixNot ast, _) =>
      o.not(ast.expression.visit(this, false /*visitingRoot */));

  @override
  o.Expression visitPropertyRead(compiler_ast.PropertyRead ast, _) {
    o.Expression receiver = ast.receiver.visit(this, false /*visitingRoot */);
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
    o.Expression receiver = ast.receiver.visit(this, false /*visitingRoot */);
    if (identical(receiver, _implicitReceiverVal)) {
      var varExpr = _nameResolver.getLocal(ast.name);
      if (varExpr != null) {
        throwFailure('Cannot assign to a reference or variable "${ast.name}"');
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
    return receiver.isBlank().conditional(o.NULL_EXPR, receiver.prop(ast.name));
  }

  @override
  o.Expression visitSafeMethodCall(compiler_ast.SafeMethodCall ast, _) {
    var receiver = ast.receiver.visit(this, false /*visitingRoot */);
    var args = _visitAll(ast.args, false /*visitingRoot */);
    return receiver
        .isBlank()
        .conditional(o.NULL_EXPR, receiver.callMethod(ast.name, args));
  }

  @override
  o.Expression visitStaticRead(compiler_ast.StaticRead ast, _) =>
      o.importExpr(ast.id.identifier, isConst: true);

  @override
  o.Expression visitNamedExpr(compiler_ast.NamedExpr ast, _) => o.NamedExpr(
      ast.name, ast.expression.visit(this, false /*visitingRoot */));

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
    return isStaticMember(memberName, _metadata.analyzedClass)
        ? o.importExpr(_metadata.identifier)
        : _implicitReceiver;
  }
}

bool _isBoolType(o.OutputType type) {
  if (type == o.BOOL_TYPE) return true;
  if (type is o.ExternalType) {
    String name = type.value.name;
    return 'bool' == name.trim();
  }
  return false;
}
