import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';

import 'expression_parser/ast.dart' as ast;

/// A wrapper around [ClassElement] which exposes the functionality
/// needed for the view compiler to find types for expressions.
class AnalyzedClass {
  final ClassElement classElement;
  final Map<String, DartType?> locals;

  /// Whether this class has mock-like behavior.
  ///
  /// The heuristic used to determine mock-like behavior is if the analyzed
  /// class or one of its ancestors, other than [Object], implements
  /// [noSuchMethod].
  ///
  /// Note that is the value is _never_ true for null-safe libraries, as we no
  /// longer support null streams/stream subscriptions in the generated code.
  final bool isMockLike;

  // The type provider associated with this class.
  TypeProvider get _typeProvider => classElement.library.typeProvider;

  AnalyzedClass(
    this.classElement, {
    this.isMockLike = false,
    this.locals = const {},
  });

  AnalyzedClass.from(AnalyzedClass other,
      {Map<String, DartType?> additionalLocals = const {}})
      : classElement = other.classElement,
        isMockLike = other.isMockLike,
        locals = {}
          ..addAll(other.locals)
          ..addAll(additionalLocals);
}

/// Returns the [expression] type evaluated within context of [analyzedClass].
///
/// Returns dynamic if [expression] can't be resolved.
DartType getExpressionType(ast.AST expression, AnalyzedClass analyzedClass) {
  final typeResolver =
      _TypeResolver(analyzedClass.classElement, analyzedClass.locals);
  return expression.visit(typeResolver);
}

/// Returns the element type of [dartType], assuming it implements `Iterable`.
///
/// Returns null otherwise.
DartType? getIterableElementType(DartType dartType) => dartType is InterfaceType
    ? dartType.lookUpInheritedGetter('single')?.returnType
    : null;

/// Returns an int type using the [analyzedClass]'s context.
DartType intType(AnalyzedClass analyzedClass) =>
    analyzedClass._typeProvider.intType;

/// Returns an bool type using the [analyzedClass]'s context.
DartType boolType(AnalyzedClass analyzedClass) =>
    analyzedClass._typeProvider.boolType;

/// Returns whether the type [expression] is [bool].
bool isBool(ast.AST expression, AnalyzedClass analyzedClass) {
  final type = getExpressionType(expression, analyzedClass);
  return type.isDartCoreBool;
}

/// Returns whether the type [expression] is [double].
bool isDouble(ast.AST expression, AnalyzedClass analyzedClass) {
  final type = getExpressionType(expression, analyzedClass);
  return type.isDartCoreDouble;
}

/// Returns whether the type [expression] is [int].
bool isInt(ast.AST expression, AnalyzedClass analyzedClass) {
  final type = getExpressionType(expression, analyzedClass);
  return type.isDartCoreInt;
}

/// Returns whether the type [expression] is [num].
bool isNumber(ast.AST expression, AnalyzedClass analyzedClass) {
  final type = getExpressionType(expression, analyzedClass);
  return type.isDartCoreNum;
}

/// Returns whether the type [expression] is [String].
bool isString(ast.AST expression, AnalyzedClass analyzedClass) {
  final type = getExpressionType(expression, analyzedClass);
  return type.isDartCoreString;
}

String typeToCode(DartType type) {
  if (type.isDynamic) {
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

PropertyInducingElement? _getField(AnalyzedClass clazz, String name) {
  var getter =
      clazz.classElement.lookUpGetter(name, clazz.classElement.library);
  return getter?.variable;
}

MethodElement? _getMethod(AnalyzedClass clazz, String name) {
  var element = clazz.classElement;
  return element.lookUpMethod(name, element.library);
}

// TODO(het): Make this work with chained expressions.
/// Returns [true] if [expression] is immutable.
bool isImmutable(ast.AST expression, AnalyzedClass? analyzedClass) {
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
        (receiver is ast.StaticRead && receiver.id.analyzedClass != null)) {
      var clazz = receiver is ast.StaticRead
          ? receiver.id.analyzedClass!
          : analyzedClass;
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
  final member = analyzedClass.classElement.getGetter(name) ??
      analyzedClass.classElement.getMethod(name);
  return member != null && member.isStatic;
}

bool isStaticSetter(String name, AnalyzedClass analyzedClass) {
  final setter = analyzedClass.classElement.getSetter(name);
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
    final method = analyzedClass.classElement.thisType.lookUpInheritedMethod(
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
  final Map<String, DartType?> _variables;

  _TypeResolver(ClassElement classElement, this._variables)
      : _dynamicType = classElement.library.typeProvider.dynamicType,
        _stringType = classElement.library.typeProvider.stringType,
        _implicitReceiverType = classElement.thisType;

  @override
  DartType visitBinary(ast.Binary ast, _) {
    // Special case for adding two strings together.
    if (ast.operator == '+' &&
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
  DartType visitInterpolation(ast.Interpolation _ast, _) {
    if (_ast.expressions.length == 1) {
      final type = _ast.expressions[0].visit(this, _);
      if (_isPrimitive(type)) {
        return type;
      }
      return _stringType;
    }
    return _stringType;
  }

  @override
  DartType visitKeyedRead(ast.KeyedRead ast, _) => _dynamicType;

  @override
  DartType visitKeyedWrite(ast.KeyedWrite ast, _) => _dynamicType;

  @override
  DartType visitLiteralPrimitive(ast.LiteralPrimitive ast, _) =>
      ast.value is String ? _stringType : _dynamicType;

  @override
  DartType visitMethodCall(ast.MethodCall ast, _) {
    var receiverType = ast.receiver.visit(this, _);
    return _lookupMethodReturnType(receiverType, ast.name);
  }

  @override
  DartType visitNamedExpr(ast.NamedExpr ast, _) => _dynamicType;

  @override
  DartType visitPipe(ast.BindingPipe ast, _) => _dynamicType;

  @override
  DartType visitPrefixNot(ast.PrefixNot ast, _) => _dynamicType;

  @override
  DartType visitPostfixNotNull(ast.PostfixNotNull ast, _) => _dynamicType;

  @override
  DartType visitPropertyRead(ast.PropertyRead ast, _) {
    var receiverType = ast.receiver.visit(this, _);
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
    var receiverType = ast.receiver.visit(this, _);
    return _lookupMethodReturnType(receiverType, ast.name);
  }

  @override
  DartType visitSafePropertyRead(ast.SafePropertyRead ast, _) {
    var receiverType = ast.receiver.visit(this, _);
    return _lookupGetterReturnType(receiverType, ast.name);
  }

  @override
  DartType visitStaticRead(ast.StaticRead ast, _) =>
      ast.id.analyzedClass == null
          ? _dynamicType
          : ast.id.analyzedClass!.classElement.thisType;

  @override
  DartType visitVariableRead(ast.VariableRead ast, _) => _dynamicType;

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

  bool _isPrimitive(DartType type) =>
      type.isDartCoreBool ||
      type.isDartCoreDouble ||
      type.isDartCoreInt ||
      type.isDartCoreNum;
}
