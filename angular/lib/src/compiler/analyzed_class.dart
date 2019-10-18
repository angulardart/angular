import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';

import 'expression_parser/ast.dart' as ast;

/// A wrapper around [ClassElement] which exposes the functionality
/// needed for the view compiler to find types for expressions.
class AnalyzedClass {
  final ClassElement _classElement;
  final Map<String, DartType> locals;

  /// Whether this class has mock-like behavior.
  ///
  /// The heuristic used to determine mock-like behavior is if the analyzed
  /// class or one of its ancestors, other than [Object], implements
  /// [noSuchMethod].
  final bool isMockLike;

  // The type provider associated with this class.
  TypeProvider get _typeProvider => _classElement.context.typeProvider;

  AnalyzedClass(
    this._classElement, {
    this.isMockLike = false,
    this.locals = const {},
  });

  AnalyzedClass.from(AnalyzedClass other,
      {Map<String, DartType> additionalLocals = const {}})
      : this._classElement = other._classElement,
        this.isMockLike = other.isMockLike,
        this.locals = {}..addAll(other.locals)..addAll(additionalLocals);
}

/// Returns the [expression] type evaluated within context of [analyzedClass].
///
/// Returns dynamic if [expression] can't be resolved.
DartType getExpressionType(ast.AST expression, AnalyzedClass analyzedClass) {
  final typeResolver =
      _TypeResolver(analyzedClass._classElement, analyzedClass.locals);
  return expression.visit(typeResolver);
}

/// Returns the element type of [dartType], assuming it implements `Iterable`.
///
/// Returns null otherwise.
DartType getIterableElementType(DartType dartType) => dartType is InterfaceType
    ? dartType.lookUpInheritedGetter('single')?.returnType
    : null;

/// Returns an int type using the [analyzedClass]'s context.
DartType intType(AnalyzedClass analyzedClass) =>
    analyzedClass._typeProvider.intType;

/// Returns an bool type using the [analyzedClass]'s context.
DartType boolType(AnalyzedClass analyzedClass) =>
    analyzedClass._typeProvider.boolType;

/// Returns whether the type [expression] is [String].
bool isString(ast.AST expression, AnalyzedClass analyzedClass) {
  final type = getExpressionType(expression, analyzedClass);
  return type.isDartCoreString;
}

String typeToCode(DartType type) {
  if (type == null) {
    return null;
  } else if (type.isDynamic) {
    return 'dynamic';
  } else if (type is InterfaceType) {
    var typeArguments = type.typeArguments;
    if (typeArguments.isEmpty) {
      return type.element.name;
    } else {
      final typeArgumentsStr = typeArguments.map(typeToCode).join(', ');
      return '${type.element.name}<$typeArgumentsStr>';
    }
  } else if (type is TypeParameterType) {
    return type.element.name;
  } else if (type.isVoid) {
    return 'void';
  } else {
    throw UnimplementedError('(${type.runtimeType}) $type');
  }
}

PropertyInducingElement _getField(AnalyzedClass clazz, String name) {
  var getter =
      clazz._classElement.lookUpGetter(name, clazz._classElement.library);
  return getter?.variable;
}

MethodElement _getMethod(AnalyzedClass clazz, String name) {
  return clazz._classElement.lookUpMethod(name, clazz._classElement.library);
}

// TODO(het): Make this work with chained expressions.
/// Returns [true] if [expression] is immutable.
bool isImmutable(ast.AST expression, AnalyzedClass analyzedClass) {
  if (expression is ast.LiteralPrimitive ||
      expression is ast.StaticRead ||
      expression is ast.EmptyExpr) {
    return true;
  }
  if (expression is ast.IfNull) {
    return isImmutable(expression.condition, analyzedClass) &&
        isImmutable(expression.nullExp, analyzedClass);
  }
  if (expression is ast.Binary) {
    return isImmutable(expression.left, analyzedClass) &&
        isImmutable(expression.right, analyzedClass);
  }
  if (expression is ast.Interpolation) {
    return expression.expressions.every((e) => isImmutable(e, analyzedClass));
  }
  if (expression is ast.PropertyRead) {
    if (analyzedClass == null) return false;
    var receiver = expression.receiver;
    if (receiver is ast.ImplicitReceiver ||
        (receiver is ast.StaticRead && receiver.analyzedClass != null)) {
      var clazz =
          receiver is ast.StaticRead ? receiver.analyzedClass : analyzedClass;
      var field = _getField(clazz, expression.name);
      if (field != null) {
        return !field.isSynthetic && (field.isFinal || field.isConst);
      }
      if (_getMethod(clazz, expression.name) != null) {
        // methods are immutable
        return true;
      }
    }
    return false;
  }
  return false;
}

bool isStaticGetterOrMethod(String name, AnalyzedClass analyzedClass) {
  final member = analyzedClass._classElement.getGetter(name) ??
      analyzedClass._classElement.getMethod(name);
  return member != null && member.isStatic;
}

bool isStaticSetter(String name, AnalyzedClass analyzedClass) {
  final setter = analyzedClass._classElement.getSetter(name);
  return setter != null && setter.isStatic;
}

/// Rewrites an event tear-off as a method call.
///
/// If [original] is a [ast.PropertyRead], and a method with the same name
/// exists in [analyzedClass], then convert [original] into a [ast.MethodCall].
///
/// If the underlying method has any parameters, then assume one parameter of
/// '$event'.
ast.ASTWithSource rewriteTearOff(
    ast.ASTWithSource original, AnalyzedClass analyzedClass) {
  var unwrappedExpression = original.ast;

  if (unwrappedExpression is ast.PropertyRead) {
    // Find the method, either on "this." or "super.".
    final method = analyzedClass._classElement.type.lookUpInheritedMethod(
      unwrappedExpression.name,
    );

    // If not found, we do not perform any re-write.
    if (method == null) {
      return original;
    }

    // If we have no positional parameters (optional or otherwise), then we
    // translate the call into "foo()". If we have at least one, we translate
    // the call into "foo($event)".
    final positionalParameters = method.parameters.where((p) => !p.isNamed);
    if (positionalParameters.isEmpty) {
      return ast.ASTWithSource.from(
          original, _simpleMethodCall(unwrappedExpression));
    } else {
      return ast.ASTWithSource.from(
          original, _complexMethodCall(unwrappedExpression));
    }
  }
  return original;
}

ast.AST _simpleMethodCall(ast.PropertyRead propertyRead) =>
    ast.MethodCall(propertyRead.receiver, propertyRead.name, []);

final _eventArg = ast.PropertyRead(ast.ImplicitReceiver(), '\$event');

ast.AST _complexMethodCall(ast.PropertyRead propertyRead) =>
    ast.MethodCall(propertyRead.receiver, propertyRead.name, [_eventArg]);

/// Returns [true] if [expression] could be [null].
bool canBeNull(ast.AST expression) {
  if (expression is ast.LiteralPrimitive ||
      expression is ast.EmptyExpr ||
      expression is ast.Interpolation) {
    return false;
  }
  if (expression is ast.IfNull) {
    if (!canBeNull(expression.condition)) return false;
    return canBeNull(expression.nullExp);
  }
  return true;
}

/// A visitor for evaluating the `DartType` of an `AST` expression.
///
/// Type resolution is best effort as we don't have a fully analyzed expression.
/// The following ASTs are currently resolvable:
///
/// * `MethodCall`
/// * `PropertyRead`
/// * `SafeMethodCall`
/// * `SafePropertyRead`
class _TypeResolver extends ast.AstVisitor<DartType, dynamic> {
  final DartType _dynamicType;
  final DartType _stringType;
  final InterfaceType _implicitReceiverType;
  final Map<String, DartType> _variables;

  _TypeResolver(ClassElement classElement, this._variables)
      : _dynamicType = classElement.context.typeProvider.dynamicType,
        _stringType = classElement.context.typeProvider.stringType,
        _implicitReceiverType = classElement.type;

  @override
  DartType visitBinary(ast.Binary ast, _) {
    // Special case for adding two strings together.
    if (ast.operation == '+' &&
        ast.left.visit(this, _) == _stringType &&
        ast.right.visit(this, _) == _stringType) {
      return _stringType;
    }
    return _dynamicType;
  }

  @override
  DartType visitConditional(ast.Conditional ast, _) => _dynamicType;

  @override
  DartType visitEmptyExpr(ast.EmptyExpr ast, _) => _dynamicType;

  @override
  DartType visitFunctionCall(ast.FunctionCall ast, _) => _dynamicType;

  @override
  DartType visitIfNull(ast.IfNull ast, _) => _dynamicType;

  @override
  DartType visitImplicitReceiver(ast.ImplicitReceiver ast, _) =>
      _implicitReceiverType;

  @override
  DartType visitInterpolation(ast.Interpolation ast, _) => _stringType;

  @override
  DartType visitKeyedRead(ast.KeyedRead ast, _) => _dynamicType;

  @override
  DartType visitKeyedWrite(ast.KeyedWrite ast, _) => _dynamicType;

  @override
  DartType visitLiteralArray(ast.LiteralArray ast, _) => _dynamicType;

  @override
  DartType visitLiteralPrimitive(ast.LiteralPrimitive ast, _) =>
      ast.value is String ? _stringType : _dynamicType;

  @override
  DartType visitMethodCall(ast.MethodCall ast, _) {
    DartType receiverType = ast.receiver.visit(this, _);
    return _lookupMethodReturnType(receiverType, ast.name);
  }

  @override
  DartType visitNamedExpr(ast.NamedExpr ast, _) => _dynamicType;

  @override
  DartType visitPipe(ast.BindingPipe ast, _) => _dynamicType;

  @override
  DartType visitPrefixNot(ast.PrefixNot ast, _) => _dynamicType;

  @override
  DartType visitPropertyRead(ast.PropertyRead ast, _) {
    DartType receiverType = ast.receiver.visit(this, _);
    if (identical(receiverType, _implicitReceiverType)) {
      // This may be a local variable.
      for (var variableName in _variables.keys) {
        if (variableName == ast.name) {
          return _variables[variableName] ?? _dynamicType;
        }
      }
    }
    return _lookupGetterReturnType(receiverType, ast.name);
  }

  @override
  DartType visitPropertyWrite(ast.PropertyWrite ast, _) => _dynamicType;

  @override
  DartType visitSafeMethodCall(ast.SafeMethodCall ast, _) {
    DartType receiverType = ast.receiver.visit(this, _);
    return _lookupMethodReturnType(receiverType, ast.name);
  }

  @override
  DartType visitSafePropertyRead(ast.SafePropertyRead ast, _) {
    DartType receiverType = ast.receiver.visit(this, _);
    return _lookupGetterReturnType(receiverType, ast.name);
  }

  @override
  DartType visitStaticRead(ast.StaticRead ast, _) =>
      ast.id.analyzedClass == null
          ? _dynamicType
          : ast.id.analyzedClass._classElement.type;

  /// Returns the return type of [getterName] on [receiverType], if it exists.
  ///
  /// Returns dynamic if [receiverType] has no [getterName].
  DartType _lookupGetterReturnType(DartType receiverType, String getterName) {
    if (receiverType is InterfaceType) {
      var getter = receiverType.lookUpInheritedGetter(getterName);
      if (getter != null) return getter.returnType;
    }
    return _dynamicType;
  }

  /// Returns the return type of [methodName] on [receiverType], if it exists.
  ///
  /// Returns dynamic if [receiverType] has no [methodName].
  DartType _lookupMethodReturnType(DartType receiverType, String methodName) {
    if (receiverType is InterfaceType) {
      var method = receiverType.lookUpInheritedMethod(methodName);
      if (method != null) return method.returnType;
    }
    return _dynamicType;
  }
}
