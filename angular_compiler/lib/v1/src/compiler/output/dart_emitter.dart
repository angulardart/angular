import '../compile_metadata.dart' show CompileIdentifierMetadata;
import 'abstract_emitter.dart'
    show
        OutputEmitter,
        EmitterVisitorContext,
        AbstractEmitterVisitor,
        catchErrorVar,
        catchStackVar;
import 'output_ast.dart' as o;
import 'path_util.dart' show getImportModulePath;

var _debugModuleUrl = 'asset://debug/lib';
var _METADATA_MAP_VAR = '_METADATA';
String debugOutputAstAsDart(
  dynamic /* o . Statement | o . Expression | o . Type | List < dynamic > */ ast, {
  bool emitNullSafeSyntax = false,
}) {
  var converter = _DartEmitterVisitor(
    _debugModuleUrl,
    emitNullSafeSyntax: emitNullSafeSyntax,
  );
  var ctx = EmitterVisitorContext.createRoot();
  late List<Object> asts;
  if (ast is! List<Object>) {
    asts = [ast as Object];
  }
  for (var ast in asts) {
    if (ast is o.Statement) {
      ast.visitStatement(converter, ctx);
    } else if (ast is o.Expression) {
      ast.visitExpression(converter, ctx);
    } else if (ast is o.OutputType) {
      ast.visitType(converter, ctx);
    } else {
      throw StateError("Don't know how to print debug info for $ast");
    }
  }
  return ctx.toSource();
}

class DartEmitter implements OutputEmitter {
  /// Whether to emit null-safe syntax (i.e. it would be valid to do so).
  final bool emitNullSafeSyntax;

  DartEmitter({
    this.emitNullSafeSyntax = false,
  });

  @override
  String emitStatements(
    String moduleUrl,
    List<o.Statement> stmts,
  ) {
    final srcParts = <String>[];
    final converter = _DartEmitterVisitor(
      moduleUrl,
      emitNullSafeSyntax: emitNullSafeSyntax,
    );
    final ctx = EmitterVisitorContext.createRoot();
    converter.visitAllStatements(stmts, ctx);
    converter.importsWithPrefixes.forEach((importedModuleUrl, prefix) {
      var importPath = getImportModulePath(moduleUrl, importedModuleUrl);
      srcParts.add(prefix.isEmpty
          ? "import '$importPath';"
          : "import '$importPath' as $prefix;");
    });
    srcParts.add(ctx.toSource());
    return srcParts.join('\n');
  }
}

class _DartEmitterVisitor extends AbstractEmitterVisitor
    implements o.TypeVisitor<void, EmitterVisitorContext> {
  // List of packages that are public api and can be imported without prefix.
  static const _allowListedImports = [
    'package:angular/angular.dart',
    'dart:core',
    // ElementRef.
    'asset:angular/lib/src/core/linker/element_ref.dart',
    'package:angular/src/core/linker/element_ref.dart',
    // ViewContainer.
    'asset:angular/lib/src/core/linker/view_container.dart',
    'package:angular/src/core/linker/view_container.dart',
    // TemplateRef.
    'asset:angular/lib/src/core/linker/template_ref.dart',
    'package:angular/src/core/linker/template_ref.dart',
    // ChangeDetectionStrategy, Differs*
    'asset:angular/lib/src/core/change_detection/change_detection.dart',
    'package:angular/src/core/change_detection/change_detection.dart',
    // NgIf.
    'asset:angular/lib/src/common/directives/ng_if.dart',
    'package:angular/src/common/directives/ng_if.dart',
    // AppView.
    'asset:angular/lib/src/core/linker/app_view.dart',
    'package:angular/src/core/linker/app_view.dart',
    // RenderComponentType.
    'asset:angular/lib/src/core/render/api.dart',
    'package:angular/src/core/render/api.dart',
  ];

  final String _moduleUrl;

  final importsWithPrefixes = <String, String>{};

  /// Whether this is currently emitting a const expression.
  var _inConstContext = false;

  /// Whether this is currently emitting a new instance of a class.
  var _inInvokeOrNewInstance = false;

  _DartEmitterVisitor(
    this._moduleUrl, {
    required bool emitNullSafeSyntax,
  }) : super(
          true,
          emitNullSafeSyntax: emitNullSafeSyntax,
        );

  @override
  void visitNamedExpr(o.NamedExpr ast, EmitterVisitorContext context) {
    context.print('${ast.name}: ');
    ast.expr.visitExpression(this, context);
  }

  @override
  void visitExternalExpr(o.ExternalExpr ast, EmitterVisitorContext context) {
    _visitIdentifier(ast.value, ast.typeParams, context);
  }

  @override
  void visitDeclareVarStmt(
    o.DeclareVarStmt stmt,
    EmitterVisitorContext context,
  ) {
    if (stmt.hasModifier(o.StmtModifier.Static)) {
      context.print('static ');
    }
    var type = stmt.type;
    if (stmt.hasModifier(o.StmtModifier.Late)) {
      var modifier = 'late';
      if (stmt.hasModifier(o.StmtModifier.Final)) {
        modifier = '$modifier final';
      }
      if (!emitNullSafeSyntax) {
        modifier = '/*$modifier*/ ';
      } else {
        modifier = '$modifier ';
      }
      context.print(modifier);
    } else if (stmt.hasModifier(o.StmtModifier.Final)) {
      context.print('final ');
    } else if (stmt.hasModifier(o.StmtModifier.Const)) {
      _inConstContext = true;
      context.print('const ');
    } else if (type == null) {
      context.print('var ');
    }
    if (type != null) {
      type.visitType(this, context);
      context.print(' ');
    }
    var value = stmt.value;
    if (value == null) {
      // No initializer.
      context.println('${stmt.name};');
    } else {
      context.print('${stmt.name} = ');
      value.visitExpression(this, context);
      context.println(';');
    }
    // A variable declaration can't be nested in any const contexts so it's safe
    // to set this to false rather than whatever the previous value was.
    _inConstContext = false;
  }

  @override
  void visitCastExpr(o.CastExpr ast, EmitterVisitorContext context) {
    context.print('(');
    ast.value.visitExpression(this, context);
    context.print(' as ');
    ast.type!.visitType(this, context);
    context.print(')');
  }

  @override
  void visitDeclareClassStmt(o.ClassStmt stmt, EmitterVisitorContext context) {
    context.pushClass(stmt);
    context.print('class ${stmt.name}');
    _visitTypeParameters(stmt.typeParameters, context);
    var parent = stmt.parent;
    if (parent != null) {
      context.print(' extends ');
      parent.visitExpression(this, context);
    }
    context.println(' {');
    context.incIndent();
    // Group fields without initializers to allow dart2js to combine
    // their initialization. e.g. `a = b = c = null`
    for (var field in stmt.fields.where((f) => f.initializer != null)) {
      _visitClassField(field, context);
    }
    for (var field in stmt.fields.where((f) => f.initializer == null)) {
      _visitClassField(field, context);
    }
    if (stmt.constructorMethod != null) {
      _visitClassConstructor(stmt, context);
    }
    for (var getter in stmt.getters) {
      _visitClassGetter(getter, context);
    }
    for (var method in stmt.methods) {
      _visitClassMethod(method, context);
    }
    context.decIndent();
    context.println('}');
    context.popClass();
  }

  void _visitAnnotations(
    List<o.Expression>? annotations,
    EmitterVisitorContext context,
  ) {
    if (annotations == null) {
      return;
    }
    for (final annotation in annotations) {
      context.print('@');
      annotation.visitExpression(this, context);
      context.println();
    }
  }

  void _visitClassField(o.ClassField field, EmitterVisitorContext context) {
    if (field.hasModifier(o.StmtModifier.Static)) {
      context.print('static ');
    }
    if (field.hasModifier(o.StmtModifier.Late)) {
      var modifier = 'late';
      if (field.hasModifier(o.StmtModifier.Final)) {
        modifier = '$modifier final';
      }
      if (!emitNullSafeSyntax) {
        modifier = '/*$modifier*/ ';
      } else {
        modifier = '$modifier ';
      }
      context.print(modifier);
    } else if (field.hasModifier(o.StmtModifier.Final)) {
      context.print('final ');
    } else if (field.type == null) {
      context.print('var ');
    }
    var type = field.type;
    if (type != null) {
      type.visitType(this, context);
      context.print(' ');
    }
    context.print('${field.name}');
    var initializer = field.initializer;
    if (initializer != null) {
      context.print(' = ');
      initializer.visitExpression(this, context);
    }
    context.println(';');
  }

  void _visitClassGetter(o.ClassGetter getter, EmitterVisitorContext context) {
    _visitAnnotations(getter.annotations, context);
    if (getter.hasModifier(o.StmtModifier.Static)) {
      context.print('static ');
    }
    if (getter.type != null) {
      getter.type!.visitType(this, context);
      context.print(' ');
    }
    context.println('get ${getter.name} {');
    context.incIndent();
    visitAllStatements(getter.body, context);
    context.decIndent();
    context.println('}');
  }

  void _visitClassConstructor(o.ClassStmt stmt, EmitterVisitorContext context) {
    final method = stmt.constructorMethod!;
    _visitAnnotations(method.annotations, context);
    context.print('${stmt.name}(');
    _visitParams(method.params, context);
    context.print(')');
    var initializerStmts = method.initializers;
    var superCtorExpr = initializerStmts.isNotEmpty
        ? _getSuperConstructorCallExpr(initializerStmts[0])
        : null;
    if (superCtorExpr != null) {
      context.print(': ');
      superCtorExpr.visitExpression(this, context);
    }
    var ctorStmts = method.body;
    if (ctorStmts.isEmpty) {
      // Empty constructor body.
      context.println(';');
    } else {
      context.println(' {');
      context.incIndent();
      visitAllStatements(ctorStmts as List<o.Statement>, context);
      context.decIndent();
      context.println('}');
    }
  }

  void _visitClassMethod(o.ClassMethod method, EmitterVisitorContext context) {
    _visitAnnotations(method.annotations, context);
    if (method.hasModifier(o.StmtModifier.Static)) {
      context.print('static ');
    }
    if (method.type != null) {
      method.type!.visitType(this, context);
    } else {
      context.print('void');
    }
    context.print(' ${method.name}(');
    _visitParams(method.params, context);
    context.println(') {');
    context.incIndent();
    visitAllStatements(method.body as List<o.Statement>, context);
    context.decIndent();
    context.println('}');
  }

  void _visitTypeArguments(
    List<o.OutputType>? typeArguments,
    EmitterVisitorContext context,
  ) {
    if (typeArguments == null || typeArguments.isEmpty) {
      return;
    }
    context.print('<');
    visitAllObjects((o.OutputType typeArgument) {
      typeArgument.visitType(this, context);
    }, typeArguments, context, ',');
    context.print('>');
  }

  void _visitTypeParameters(
    List<o.TypeParameter> typeParameters,
    EmitterVisitorContext context,
  ) {
    if (typeParameters.isEmpty) {
      return;
    }
    context.print('<');
    visitAllObjects((o.TypeParameter typeParameter) {
      context.print(typeParameter.name);
      var bound = typeParameter.bound;
      // Don't emit an explicit bound for dynamic, since bounds are implicitly
      // dynamic.
      if (bound != null && bound != o.DYNAMIC_TYPE) {
        context.print(' extends ');
        bound.visitType(this, context);
      }
    }, typeParameters, context, ', ');
    context.print('>');
  }

  @override
  void visitFunctionExpr(o.FunctionExpr ast, EmitterVisitorContext context) {
    context.print('(');
    _visitParams(ast.params, context);
    context.println(') {');
    context.incIndent();
    visitAllStatements(ast.statements, context);
    context.decIndent();
    context.print('}');
  }

  @override
  void visitDeclareFunctionStmt(
      o.DeclareFunctionStmt stmt, EmitterVisitorContext context) {
    _visitAnnotations(stmt.annotations, context);
    var type = stmt.type;
    if (type != null) {
      type.visitType(this, context);
    } else if (!stmt.isGetter) {
      context.print('void');
    }
    if (stmt.isGetter) {
      context.print(' get');
    }
    context.print(' ${stmt.name}');
    if (!stmt.isGetter) {
      _visitTypeParameters(stmt.typeParameters, context);
      context.print('(');
      _visitParams(stmt.params, context);
      context.println(') {');
    } else {
      context.print(' {');
    }
    context.incIndent();
    visitAllStatements(stmt.statements, context);
    context.decIndent();
    context.println('}');
  }

  @override
  String getBuiltinMethodName(o.BuiltinMethod method) {
    switch (method) {
      case o.BuiltinMethod.ConcatArray:
        return '.addAll';
      case o.BuiltinMethod.SubscribeObservable:
        return 'listen';
      default:
        throw StateError('Unknown builtin method: $method');
    }
  }

  @override
  void visitReadVarExpr(o.ReadVarExpr ast, EmitterVisitorContext context) {
    if (identical(ast.builtin, o.BuiltinVar.MetadataMap)) {
      context.print(_METADATA_MAP_VAR);
    } else {
      super.visitReadVarExpr(ast, context);
    }
  }

  @override
  void visitReadClassMemberExpr(
      o.ReadClassMemberExpr ast, EmitterVisitorContext context) {
    context.print('this.${ast.name}');
  }

  @override
  void visitWriteClassMemberExpr(
      o.WriteClassMemberExpr expr, EmitterVisitorContext context) {
    var lineWasEmpty = context.lineIsEmpty();
    if (!lineWasEmpty) {
      context.print('(');
    }
    context.print('this.${expr.name} = ');
    expr.value.visitExpression(this, context);
    if (!lineWasEmpty) {
      context.print(')');
    }
  }

  @override
  void visitTryCatchStmt(o.TryCatchStmt stmt, EmitterVisitorContext context) {
    context.println('try {');
    context.incIndent();
    visitAllStatements(stmt.bodyStmts, context);
    context.decIndent();
    context.println('} catch (${catchErrorVar.name}, ${catchStackVar.name}) {');
    context.incIndent();
    visitAllStatements(stmt.catchStmts, context);
    context.decIndent();
    context.println('}');
  }

  @override
  void visitBinaryOperatorExpr(
      o.BinaryOperatorExpr ast, EmitterVisitorContext context) {
    switch (ast.operator) {
      case o.BinaryOperator.Identical:
        context.print('identical(');
        ast.lhs.visitExpression(this, context);
        context.print(', ');
        ast.rhs.visitExpression(this, context);
        context.print(')');
        break;
      case o.BinaryOperator.NotIdentical:
        context.print('!identical(');
        ast.lhs.visitExpression(this, context);
        context.print(', ');
        ast.rhs.visitExpression(this, context);
        context.print(')');
        break;
      default:
        super.visitBinaryOperatorExpr(ast, context);
    }
  }

  @override
  void visitLiteralVargsExpr(
      o.LiteralVargsExpr ast, EmitterVisitorContext context) {
    visitAllExpressions(
      ast.entries,
      context,
      ',',
      newLine: ast.entries.isNotEmpty,
      keepOnSameLine: true,
    );
  }

  @override
  void visitLiteralArrayExpr(
      o.LiteralArrayExpr ast, EmitterVisitorContext context) {
    final wasInConstContext = _inConstContext;
    if (!wasInConstContext && _isConstType(ast.type)) {
      context.print('const ');
      _inConstContext = true;
    }
    if (ast.type == o.DYNAMIC_TYPE) {
      context.print('<dynamic>');
    } else if (ast.type == o.OBJECT_TYPE) {
      context.print('<Object>');
    } else {
      // TODO(b/171268745): Remove one-off hack for a const <Object>[].
      final type = ast.type;
      if (type is o.ArrayType && type.of == o.OBJECT_TYPE) {
        context.print('<Object>');
      }
    }
    super.visitLiteralArrayExpr(ast, context);
    _inConstContext = wasInConstContext;
  }

  @override
  void visitLiteralMapExpr(
      o.LiteralMapExpr ast, EmitterVisitorContext context) {
    final wasInConstContext = _inConstContext;
    if (!wasInConstContext && _isConstType(ast.type)) {
      context.print('const ');
      _inConstContext = true;
    }
    var valueType = ast.valueType;
    if (valueType != null) {
      context.print('<String, ');
      valueType.visitType(this, context);
      context.print('>');
    }
    super.visitLiteralMapExpr(ast, context);
    _inConstContext = wasInConstContext;
  }

  @override
  void visitInvokeFunctionExpr(
    o.InvokeFunctionExpr expr,
    EmitterVisitorContext context,
  ) {
    final wasInNewInstance = _inInvokeOrNewInstance;
    _inInvokeOrNewInstance = true;
    expr.fn.visitExpression(this, context);
    _inInvokeOrNewInstance = wasInNewInstance;
    _visitTypeArguments(expr.typeArgs, context);
    context.print('(');
    visitAllExpressions(expr.args, context, ',');
    visitAllNamedExpressions(
      expr.namedArgs,
      context,
      ',',
      alwaysAddSeperator: expr.args.isNotEmpty,
    );
    context.print(')');
  }

  @override
  void visitInstantiateExpr(
      o.InstantiateExpr ast, EmitterVisitorContext context) {
    final wasInNewInstance = _inInvokeOrNewInstance;
    final wasInConstContext = _inConstContext;
    if (!wasInConstContext && _isConstType(ast.type)) {
      context.print('const ');
      _inConstContext = true;
    }
    _inInvokeOrNewInstance = true;
    ast.classExpr.visitExpression(this, context);
    _inInvokeOrNewInstance = wasInNewInstance;
    _visitTypeArguments(ast.typeArguments, context);
    context.print('(');
    visitAllExpressions(ast.args, context, ',');
    visitAllNamedExpressions(
      ast.namedArgs,
      context,
      ',',
      alwaysAddSeperator: ast.args.isNotEmpty,
    );
    context.print(')');
    _inConstContext = wasInConstContext;
  }

  @override
  void visitBuiltinType(o.BuiltinType type, EmitterVisitorContext context) {
    String typeStr;
    switch (type.name) {
      case o.BuiltinTypeName.Bool:
        typeStr = 'bool';
        break;
      case o.BuiltinTypeName.Dynamic:
        typeStr = 'dynamic';
        break;
      case o.BuiltinTypeName.Object:
        typeStr = 'Object';
        break;
      case o.BuiltinTypeName.Function:
        typeStr = 'Function';
        break;
      case o.BuiltinTypeName.Number:
        typeStr = 'num';
        break;
      case o.BuiltinTypeName.Int:
        typeStr = 'int';
        break;
      case o.BuiltinTypeName.Double:
        typeStr = 'double';
        break;
      case o.BuiltinTypeName.String:
        typeStr = 'String';
        break;
      case o.BuiltinTypeName.Null:
        typeStr = 'Null';
        break;
      case o.BuiltinTypeName.Never:
        typeStr = emitNullSafeSyntax ? 'Never' : 'Null /*Never*/';
        break;
      case o.BuiltinTypeName.Void:
        typeStr = 'void';
        break;
      default:
        throw StateError('Unsupported builtin type ${type.name}');
    }
    if (type.modifiers.contains(o.TypeModifier.Nullable)) {
      final suffix = emitNullSafeSyntax ? '?' : '/*?*/';
      typeStr = '$typeStr$suffix';
    }
    context.print(typeStr);
  }

  @override
  void visitExternalType(o.ExternalType ast, EmitterVisitorContext context) {
    final nullable = ast.modifiers.contains(o.TypeModifier.Nullable);
    _visitIdentifier(
      ast.value,
      ast.typeParams,
      context,
      nullable: nullable,
    );
  }

  @override
  void visitFunctionType(o.FunctionType type, EmitterVisitorContext context) {
    var returnType = type.returnType;
    if (returnType != null) {
      returnType.visitType(this, context);
    } else {
      context.print('void');
    }
    context.print(' Function(');
    visitAllObjects((o.OutputType param) {
      param.visitType(this, context);
    }, type.paramTypes, context, ',');
    context.print(')');
    if (type.modifiers.contains(o.TypeModifier.Nullable)) {
      final postfix = emitNullSafeSyntax ? '?' : '/*?*/';
      context.print(postfix);
    }
  }

  @override
  void visitArrayType(o.ArrayType type, EmitterVisitorContext context) {
    context.print('List<');
    var typeOf = type.of;
    if (typeOf != null) {
      typeOf.visitType(this, context);
    } else {
      context.print('dynamic');
    }
    context.print('>');
    if (type.modifiers.contains(o.TypeModifier.Nullable)) {
      final postfix = emitNullSafeSyntax ? '?' : '/*?*/';
      context.print(postfix);
    }
  }

  @override
  void visitMapType(o.MapType type, EmitterVisitorContext context) {
    context.print('Map<String, ');
    var valueType = type.valueType;
    if (valueType != null) {
      valueType.visitType(this, context);
    } else {
      context.print('dynamic');
    }
    context.print('>');
  }

  void _visitParams(List<o.FnParam> params, EmitterVisitorContext context) {
    visitAllObjects((o.FnParam param) {
      var type = param.type;
      if (type != null) {
        type.visitType(this, context);
        context.print(' ');
      }
      context.print(param.name);
    }, params, context, ',');
  }

  void _visitIdentifier(
    CompileIdentifierMetadata value,
    List<o.OutputType>? typeParams,
    EmitterVisitorContext context, {
    bool nullable = false,
  }) {
    final prefix = _computeModulePrefix(
      value,
      context,
    );
    String? postfix;
    if (nullable) {
      postfix = emitNullSafeSyntax ? '?' : '/*?*/';
    }
    _emitIdentifier(
      value.name,
      typeParams,
      context,
      prefix: prefix,
      postfix: postfix,
    );
  }

  /// Determines the import prefix for accessing symbols for [value].
  String _computeModulePrefix(
    CompileIdentifierMetadata value,
    EmitterVisitorContext context,
  ) {
    final moduleUrl = value.moduleUrl;
    var prefix = '';
    if (moduleUrl != null && moduleUrl != _moduleUrl) {
      if (importsWithPrefixes.containsKey(moduleUrl)) {
        prefix = importsWithPrefixes[moduleUrl]!;
      } else {
        if (_allowListedImports.contains(moduleUrl)) {
          prefix = '';
        } else {
          prefix = 'import${importsWithPrefixes.length}';
        }
        importsWithPrefixes[moduleUrl] = prefix;
      }
    }
    // The naming is unfortunate, but this usually (but not always) refers to
    // static members or other accessors.
    if (value.emitPrefix && value.prefix?.isNotEmpty == true) {
      if (prefix.isNotEmpty) {
        prefix = '$prefix.';
      }
      prefix = '$prefix${value.prefix}';
    }
    return prefix;
  }

  /// Handles actually emitting the [identifier], with a [prefix], if needed.
  void _emitIdentifier(
    String identifier,
    List<o.OutputType>? typeParams,
    EmitterVisitorContext context, {
    String? prefix,
    String? postfix,
  }) {
    if (prefix?.isNotEmpty == true) {
      context.print(identifier.isEmpty ? prefix! : '$prefix.');
    }
    context.print(identifier);
    _visitTypeArguments(typeParams, context);
    if (postfix?.isNotEmpty == true) {
      context.print(postfix!);
    }
  }
}

o.Expression? _getSuperConstructorCallExpr(o.Statement stmt) {
  if (stmt is o.ExpressionStatement) {
    var expr = stmt.expr;
    if (expr is o.InvokeFunctionExpr) {
      var fn = expr.fn;
      if (fn is o.ReadVarExpr) {
        if (identical(fn.builtin, o.BuiltinVar.Super)) {
          return expr;
        }
      }
    }
  }
  return null;
}

bool _isConstType(o.OutputType? type) {
  return type != null && type.hasModifier(o.TypeModifier.Const);
}
