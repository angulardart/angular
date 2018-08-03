import "../compile_metadata.dart" show CompileIdentifierMetadata;
import "abstract_emitter.dart"
    show
        OutputEmitter,
        EmitterVisitorContext,
        AbstractEmitterVisitor,
        catchErrorVar,
        catchStackVar;
import "output_ast.dart" as o;
import "path_util.dart" show getImportModulePath;

var _debugModuleUrl = "asset://debug/lib";
var _METADATA_MAP_VAR = '_METADATA';
String debugOutputAstAsDart(
    dynamic /* o . Statement | o . Expression | o . Type | List < dynamic > */ ast) {
  var converter = _DartEmitterVisitor(_debugModuleUrl);
  var ctx = EmitterVisitorContext.createRoot([], {});
  List<dynamic> asts;
  if (ast is! List) {
    asts = [ast];
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
  @override
  String emitStatements(String moduleUrl, List<o.Statement> stmts,
      List<String> exportedVars, Map<String, String> deferredModules) {
    var srcParts = [];
    // Note: We are not creating a library here as Dart does not need it.
    // Dart analyzer might complain about it though.
    var converter = _DartEmitterVisitor(moduleUrl);
    var ctx = EmitterVisitorContext.createRoot(exportedVars, deferredModules);
    converter.visitAllStatements(stmts, ctx);
    converter.importsWithPrefixes.forEach((importedModuleUrl, prefix) {
      String importPath = getImportModulePath(moduleUrl, importedModuleUrl);
      srcParts.add(prefix.isEmpty
          ? "import '$importPath';"
          : (deferredModules.containsKey(importedModuleUrl)
              ? "import '$importPath' deferred as $prefix;"
              : "import '$importPath' as $prefix;"));
    });
    srcParts.add(ctx.toSource());
    return srcParts.join("\n");
  }
}

class _DartEmitterVisitor extends AbstractEmitterVisitor
    implements o.TypeVisitor<void, EmitterVisitorContext> {
  // List of packages that are public api and can be imported without prefix.
  static const List<String> whiteListedImports = [
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

  var importsWithPrefixes = Map<String, String>();

  /// Whether this is currently emitting a const expression.
  var _inConstContext = false;

  _DartEmitterVisitor(this._moduleUrl) : super(true);

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
      o.DeclareVarStmt stmt, EmitterVisitorContext context) {
    if (stmt.hasModifier(o.StmtModifier.Static)) {
      context.print('static ');
    }
    if (stmt.hasModifier(o.StmtModifier.Final)) {
      context.print('final ');
    } else if (stmt.hasModifier(o.StmtModifier.Const)) {
      context.print('const ');
    } else if (stmt.type == null) {
      context.print('var ');
    }
    if (stmt.type != null) {
      stmt.type.visitType(this, context);
      context.print(' ');
    }
    if (stmt.value == null) {
      // No initializer.
      context.println('${stmt.name};');
    } else {
      context.print('${stmt.name} = ');
      stmt.value.visitExpression(this, context);
      context.println(';');
    }
  }

  @override
  void visitCastExpr(o.CastExpr ast, EmitterVisitorContext context) {
    context.print('(');
    ast.value.visitExpression(this, context);
    context.print(' as ');
    ast.type.visitType(this, context);
    context.print(')');
  }

  @override
  void visitDeclareClassStmt(o.ClassStmt stmt, EmitterVisitorContext context) {
    context.pushClass(stmt);
    context.print('class ${stmt.name}');
    _visitTypeParameters(stmt.typeParameters, context);
    if (stmt.parent != null) {
      context.print(' extends ');
      stmt.parent.visitExpression(this, context);
    }
    context.println(' {');
    context.incIndent();
    for (var field in stmt.fields) {
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

  void _visitClassField(o.ClassField field, EmitterVisitorContext context) {
    if (field.hasModifier(o.StmtModifier.Static)) {
      context.print('static ');
    }
    if (field.hasModifier(o.StmtModifier.Final)) {
      context.print('final ');
    } else if (field.type == null) {
      context.print('var ');
    }
    if (field.type != null) {
      field.type.visitType(this, context);
      context.print(' ');
    }
    context.print('${field.name}');
    if (field.initializer != null) {
      context.print(' = ');
      field.initializer.visitExpression(this, context);
    }
    context.println(';');
  }

  void _visitClassGetter(o.ClassGetter getter, EmitterVisitorContext context) {
    if (getter.type != null) {
      getter.type.visitType(this, context);
      context.print(' ');
    }
    context.println('get ${getter.name} {');
    context.incIndent();
    visitAllStatements(getter.body, context);
    context.decIndent();
    context.println('}');
  }

  void _visitClassConstructor(o.ClassStmt stmt, EmitterVisitorContext context) {
    context.print('${stmt.name}(');
    _visitParams(stmt.constructorMethod.params, context);
    context.print(')');
    var ctorStmts = stmt.constructorMethod.body;
    var superCtorExpr = ctorStmts.isNotEmpty
        ? _getSuperConstructorCallExpr(ctorStmts[0])
        : null;
    if (superCtorExpr != null) {
      context.print(': ');
      context.enterSuperCall();
      superCtorExpr.visitExpression(this, context);
      context.exitSuperCall();
      ctorStmts = ctorStmts.sublist(1);
    }
    if (ctorStmts.isEmpty) {
      // Empty constructor body.
      context.println(';');
    } else {
      context.println(' {');
      context.incIndent();
      visitAllStatements(ctorStmts, context);
      context.decIndent();
      context.println('}');
    }
  }

  void _visitClassMethod(o.ClassMethod method, EmitterVisitorContext context) {
    context.enterMethod(method);
    for (var annotation in method.annotations) {
      context.print('@$annotation ');
    }
    if (method.hasModifier(o.StmtModifier.Static)) {
      context.print('static ');
    }
    if (method.type != null) {
      method.type.visitType(this, context);
    } else {
      context.print('void');
    }
    context.print(' ${method.name}(');
    _visitParams(method.params, context);
    context.println(') {');
    context.incIndent();
    visitAllStatements(method.body, context);
    context.decIndent();
    context.println('}');
    context.exitMethod();
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
      // Don't emit an explicit bound for dynamic, since bounds are implicitly
      // dynamic.
      if (typeParameter.bound != null &&
          typeParameter.bound != o.DYNAMIC_TYPE) {
        context.print(' extends ');
        typeParameter.bound.visitType(this, context);
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
    if (stmt.type != null) {
      stmt.type.visitType(this, context);
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
        return ".addAll";
      case o.BuiltinMethod.SubscribeObservable:
        return "listen";
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
    if (context.activeMethod != null &&
        !context.activeMethod.containsParameterName(ast.name) &&
        !context.inSuperCall) {
      context.print('${ast.name}');
    } else {
      context.print('this.${ast.name}');
    }
  }

  @override
  void visitWriteClassMemberExpr(
      o.WriteClassMemberExpr expr, EmitterVisitorContext context) {
    var lineWasEmpty = context.lineIsEmpty();
    if (!lineWasEmpty) {
      context.print('(');
    }
    context.print('${expr.name} = ');
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
    if (ast.valueType != null) {
      context.print('<String, ');
      ast.valueType.visitType(this, context);
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
    expr.fn.visitExpression(this, context);
    var types = expr.typeArgs;
    if (types != null && types.isNotEmpty) {
      context.print('<');
      for (var i = 0; i < types.length; i++) {
        types[i].visitType(this, context);
        if (i < types.length - 1) {
          context.print(', ');
        }
      }
      context.print('>');
    }
    context.print('(');
    visitAllExpressions(expr.args, context, ',');
    context.print(')');
  }

  @override
  void visitInstantiateExpr(
      o.InstantiateExpr ast, EmitterVisitorContext context) {
    final wasInConstContext = _inConstContext;
    if (!wasInConstContext && _isConstType(ast.type)) {
      context.print('const ');
      _inConstContext = true;
    }
    ast.classExpr.visitExpression(this, context);
    var types = ast.typeArguments;
    if (types != null && types.isNotEmpty) {
      context.print('<');
      for (var i = 0; i < types.length; i++) {
        types[i].visitType(this, context);
        if (i < types.length - 1) {
          context.print(', ');
        }
      }
      context.print('>');
    }
    context.print('(');
    visitAllExpressions(ast.args, context, ',');
    context.print(')');
    _inConstContext = wasInConstContext;
  }

  @override
  void visitBuiltinType(o.BuiltinType type, EmitterVisitorContext context) {
    String typeStr;
    switch (type.name) {
      case o.BuiltinTypeName.Bool:
        typeStr = "bool";
        break;
      case o.BuiltinTypeName.Dynamic:
        typeStr = "dynamic";
        break;
      case o.BuiltinTypeName.Function:
        typeStr = "Function";
        break;
      case o.BuiltinTypeName.Number:
        typeStr = "num";
        break;
      case o.BuiltinTypeName.Int:
        typeStr = "int";
        break;
      case o.BuiltinTypeName.Double:
        typeStr = "double";
        break;
      case o.BuiltinTypeName.String:
        typeStr = "String";
        break;
      case o.BuiltinTypeName.Null:
        typeStr = "Null";
        break;
      case o.BuiltinTypeName.Void:
        typeStr = "void";
        break;
      default:
        throw StateError('Unsupported builtin type ${type.name}');
    }
    context.print(typeStr);
  }

  @override
  void visitExternalType(o.ExternalType ast, EmitterVisitorContext context) {
    _visitIdentifier(ast.value, ast.typeParams, context);
  }

  @override
  void visitFunctionType(o.FunctionType type, EmitterVisitorContext context) {
    if (type.returnType != null) {
      type.returnType.visitType(this, context);
    } else {
      context.print('void');
    }
    context.print(' Function(');
    visitAllObjects((o.OutputType param) {
      param.visitType(this, context);
    }, type.paramTypes, context, ',');
    context.print(')');
  }

  @override
  void visitArrayType(o.ArrayType type, EmitterVisitorContext context) {
    context.print('List<');
    if (type.of != null) {
      type.of.visitType(this, context);
    } else {
      context.print('dynamic');
    }
    context.print('>');
  }

  @override
  void visitMapType(o.MapType type, EmitterVisitorContext context) {
    context.print('Map<String, ');
    if (type.valueType != null) {
      type.valueType.visitType(this, context);
    } else {
      context.print('dynamic');
    }
    context.print('>');
  }

  void _visitParams(List<o.FnParam> params, EmitterVisitorContext context) {
    visitAllObjects((param) {
      if (param.type != null) {
        param.type.visitType(this, context);
        context.print(" ");
      }
      context.print(param.name as String);
    }, params, context, ",");
  }

  void _visitIdentifier(CompileIdentifierMetadata value,
      List<o.OutputType> typeParams, EmitterVisitorContext context) {
    String prefix = '';
    bool isDeferred = false;
    if (value.moduleUrl != null && value.moduleUrl != _moduleUrl) {
      prefix = importsWithPrefixes[value.moduleUrl];
      if (prefix == null) {
        if (whiteListedImports.contains(value.moduleUrl)) {
          prefix = '';
        } else {
          prefix = 'import${importsWithPrefixes.length}';
          if (context.deferredModules.containsKey(value.moduleUrl)) {
            isDeferred = true;
            prefix = context.deferredModules[value.moduleUrl];
          }
        }
        importsWithPrefixes[value.moduleUrl] = prefix;
      }
    } else if (value.emitPrefix) {
      prefix = value.prefix ?? '';
    }
    if (isDeferred) {
      if (prefix.isNotEmpty) {
        context.print(value.name.isEmpty ? prefix : '$prefix.');
      }
    } else {
      if (value.moduleUrl != null && value.moduleUrl != _moduleUrl) {
        context.print(prefix.isEmpty ? '' : '$prefix.');
      }
      if (value.emitPrefix && value.prefix != null && value.prefix.isNotEmpty) {
        context.print('${value.prefix}.');
      }
    }
    context.print(value.name);
    if (typeParams != null && typeParams.length > 0) {
      context.print('<');
      visitAllObjects<o.OutputType>(
          (type) => type.visitType(this, context), typeParams, context, ',');
      context.print('>');
    }
  }
}

o.Expression _getSuperConstructorCallExpr(o.Statement stmt) {
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

bool _isConstType(o.OutputType type) {
  return type != null && type.hasModifier(o.TypeModifier.Const);
}
