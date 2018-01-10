import "package:angular/src/facade/exceptions.dart" show BaseException;

import "../compile_metadata.dart" show CompileIdentifierMetadata;
import "abstract_emitter.dart"
    show
        OutputEmitter,
        EmitterVisitorContext,
        AbstractEmitterVisitor,
        CATCH_ERROR_VAR,
        CATCH_STACK_VAR;
import "output_ast.dart" as o;
import "path_util.dart" show getImportModulePath;

var _debugModuleUrl = "asset://debug/lib";
var _METADATA_MAP_VAR = '_METADATA';
String debugOutputAstAsDart(
    dynamic /* o . Statement | o . Expression | o . Type | List < dynamic > */ ast) {
  var converter = new _DartEmitterVisitor(_debugModuleUrl);
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
      throw new BaseException("Don't know how to print debug info for $ast");
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
    var converter = new _DartEmitterVisitor(moduleUrl);
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
    implements o.TypeVisitor {
  // List of packages that are public api and can be imported without prefix.
  static const List<String> whiteListedImports = const [
    'package:angular/angular.dart',
    'dart:core',
    // 'dart:html',
    // StaticNodeDebugInfo, DebugContext.
    'asset:angular/lib/src/debug/debug_context.dart',
    'package:angular/src/debug/debug_context.dart',
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
    // AppView, DebugAppView.
    'asset:angular/lib/src/core/linker/app_view.dart',
    'package:angular/src/core/linker/app_view.dart',
    'asset:angular/lib/src/debug/debug_app_view.dart',
    'package:angular/src/debug/debug_app_view.dart',
    // RenderComponentType.
    'asset:angular/lib/src/core/render/api.dart',
    'package:angular/src/core/render/api.dart',
  ];

  final String _moduleUrl;

  var importsWithPrefixes = new Map<String, String>();

  _DartEmitterVisitor(this._moduleUrl) : super(true);

  @override
  dynamic visitNamedExpr(o.NamedExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('${ast.name}: ');
    ast.expr.visitExpression(this, ctx);
    return null;
  }

  @override
  dynamic visitExternalExpr(o.ExternalExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    this._visitIdentifier(ast.value, ast.typeParams, ctx);
    return null;
  }

  @override
  dynamic visitDeclareVarStmt(o.DeclareVarStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (stmt.hasModifier(o.StmtModifier.Static)) {
      ctx.print('static ');
    }
    if (stmt.hasModifier(o.StmtModifier.Final)) {
      ctx.print('final ');
    } else if (stmt.hasModifier(o.StmtModifier.Const)) {
      ctx.print('const ');
    } else if (stmt.type == null) {
      ctx.print('var ');
    }
    if (stmt.type != null) {
      stmt.type.visitType(this, ctx);
      ctx.print(' ');
    }
    if (stmt.value == null) {
      // No initializer.
      ctx.println('${stmt.name};');
    } else {
      ctx.print('${stmt.name} = ');
      stmt.value.visitExpression(this, ctx);
      ctx.println(';');
    }
    return null;
  }

  @override
  dynamic visitCastExpr(o.CastExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('(');
    ast.value.visitExpression(this, ctx);
    ctx.print(' as ');
    ast.type.visitType(this, ctx);
    ctx.print(')');
    return null;
  }

  @override
  dynamic visitDeclareClassStmt(o.ClassStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.pushClass(stmt);
    ctx.print('class ${stmt.name}');
    if (stmt.parent != null) {
      ctx.print(' extends ');
      stmt.parent.visitExpression(this, ctx);
    }
    ctx.println(' {');
    ctx.incIndent();
    for (var field in stmt.fields) {
      _visitClassField(field, ctx);
    }
    if (stmt.constructorMethod != null) {
      this._visitClassConstructor(stmt, ctx);
    }
    for (var getter in stmt.getters) {
      _visitClassGetter(getter, ctx);
    }
    for (var method in stmt.methods) {
      _visitClassMethod(method, ctx);
    }
    ctx.decIndent();
    ctx.println('}');
    ctx.popClass();
    return null;
  }

  void _visitClassField(o.ClassField field, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (field.hasModifier(o.StmtModifier.Static)) {
      ctx.print('static ');
    }
    if (field.hasModifier(o.StmtModifier.Final)) {
      ctx.print('final ');
    } else if (field.type == null) {
      ctx.print('var ');
    }
    if (field.type != null) {
      field.type.visitType(this, ctx);
      ctx.print(' ');
    }
    ctx.print('${field.name}');
    if (field.initializer != null) {
      ctx.print(' = ');
      field.initializer.visitExpression(this, context);
    }
    ctx.println(';');
  }

  void _visitClassGetter(o.ClassGetter getter, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (getter.type != null) {
      getter.type.visitType(this, ctx);
      ctx.print(' ');
    }
    ctx.println('get ${getter.name} {');
    ctx.incIndent();
    this.visitAllStatements(getter.body, ctx);
    ctx.decIndent();
    ctx.println('}');
  }

  void _visitClassConstructor(o.ClassStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('${stmt.name}(');
    this._visitParams(stmt.constructorMethod.params, ctx);
    ctx.print(')');
    var ctorStmts = stmt.constructorMethod.body;
    var superCtorExpr =
        ctorStmts.length > 0 ? getSuperConstructorCallExpr(ctorStmts[0]) : null;
    if (superCtorExpr != null) {
      ctx.print(': ');
      ctx.enterSuperCall();
      superCtorExpr.visitExpression(this, ctx);
      ctx.exitSuperCall();
      ctorStmts = ctorStmts.sublist(1);
    }
    if (ctorStmts.isEmpty) {
      // Empty constructor body.
      ctx.println(';');
    } else {
      ctx.println(' {');
      ctx.incIndent();
      this.visitAllStatements(ctorStmts, ctx);
      ctx.decIndent();
      ctx.println('}');
    }
  }

  void _visitClassMethod(o.ClassMethod method, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.enterMethod(method);
    for (var annotation in method.annotations) {
      ctx.print('@$annotation ');
    }
    if (method.type != null) {
      method.type.visitType(this, ctx);
    } else {
      ctx.print('void');
    }
    ctx.print(' ${method.name}(');
    this._visitParams(method.params, ctx);
    ctx.println(') {');
    ctx.incIndent();
    this.visitAllStatements(method.body, ctx);
    ctx.decIndent();
    ctx.println('}');
    ctx.exitMethod();
  }

  @override
  dynamic visitFunctionExpr(o.FunctionExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('(');
    this._visitParams(ast.params, ctx);
    ctx.println(') {');
    ctx.incIndent();
    this.visitAllStatements(ast.statements, ctx);
    ctx.decIndent();
    ctx.print('}');
    return null;
  }

  @override
  dynamic visitDeclareFunctionStmt(
      o.DeclareFunctionStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (stmt.type != null) {
      stmt.type.visitType(this, ctx);
    } else {
      ctx.print('void');
    }
    ctx.print(' ${stmt.name}(');
    this._visitParams(stmt.params, ctx);
    ctx.println(') {');
    ctx.incIndent();
    this.visitAllStatements(stmt.statements, ctx);
    ctx.decIndent();
    ctx.println('}');
    return null;
  }

  @override
  String getBuiltinMethodName(o.BuiltinMethod method) {
    var name;
    switch (method) {
      case o.BuiltinMethod.ConcatArray:
        name = ".addAll";
        break;
      case o.BuiltinMethod.SubscribeObservable:
        name = "listen";
        break;
      default:
        throw new BaseException('Unknown builtin method: $method');
    }
    return name;
  }

  @override
  dynamic visitReadVarExpr(o.ReadVarExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (identical(ast.builtin, o.BuiltinVar.MetadataMap)) {
      ctx.print(_METADATA_MAP_VAR);
    } else {
      super.visitReadVarExpr(ast, ctx);
    }
    return null;
  }

  @override
  dynamic visitReadClassMemberExpr(o.ReadClassMemberExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (ctx.activeMethod != null &&
        !ctx.activeMethod.containsParameterName(ast.name) &&
        !ctx.inSuperCall) {
      ctx.print('${ast.name}');
    } else {
      ctx.print('this.${ast.name}');
    }
    return null;
  }

  @override
  dynamic visitWriteClassMemberExpr(
      o.WriteClassMemberExpr expr, dynamic context) {
    EmitterVisitorContext ctx = context;
    var lineWasEmpty = ctx.lineIsEmpty();
    if (!lineWasEmpty) {
      ctx.print('(');
    }
    ctx.print('${expr.name} = ');
    expr.value.visitExpression(this, ctx);
    if (!lineWasEmpty) {
      ctx.print(')');
    }
    return null;
  }

  @override
  dynamic visitTryCatchStmt(o.TryCatchStmt stmt, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.println('try {');
    ctx.incIndent();
    this.visitAllStatements(stmt.bodyStmts, ctx);
    ctx.decIndent();
    ctx.println('} catch (${CATCH_ERROR_VAR.name}, ${CATCH_STACK_VAR.name}) {');
    ctx.incIndent();
    this.visitAllStatements(stmt.catchStmts, ctx);
    ctx.decIndent();
    ctx.println('}');
    return null;
  }

  @override
  dynamic visitBinaryOperatorExpr(o.BinaryOperatorExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    switch (ast.operator) {
      case o.BinaryOperator.Identical:
        ctx.print('identical(');
        ast.lhs.visitExpression(this, ctx);
        ctx.print(', ');
        ast.rhs.visitExpression(this, ctx);
        ctx.print(')');
        break;
      case o.BinaryOperator.NotIdentical:
        ctx.print('!identical(');
        ast.lhs.visitExpression(this, ctx);
        ctx.print(', ');
        ast.rhs.visitExpression(this, ctx);
        ctx.print(')');
        break;
      default:
        super.visitBinaryOperatorExpr(ast, ctx);
    }
    return null;
  }

  @override
  dynamic visitLiteralVargsExpr(o.LiteralVargsExpr ast, dynamic context) {
    this.visitAllExpressions(
      ast.entries,
      context,
      ',',
      newLine: ast.entries.isNotEmpty,
      keepOnSameLine: true,
    );
    return ast;
  }

  @override
  dynamic visitLiteralArrayExpr(o.LiteralArrayExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (isConstType(ast.type)) {
      ctx.print('const ');
    }
    if (ast.type == o.DYNAMIC_TYPE) {
      ctx.print('<dynamic>');
    }
    return super.visitLiteralArrayExpr(ast, ctx);
  }

  @override
  dynamic visitLiteralMapExpr(o.LiteralMapExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (isConstType(ast.type)) {
      ctx.print('const ');
    }
    if (ast.valueType != null) {
      ctx.print('<String, ');
      ast.valueType.visitType(this, ctx);
      ctx.print('>');
    }
    return super.visitLiteralMapExpr(ast, ctx);
  }

  @override
  dynamic visitInstantiateExpr(o.InstantiateExpr ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print(isConstType(ast.type) ? 'const' : 'new');
    ctx.print(" ");
    ast.classExpr.visitExpression(this, ctx);
    var types = ast.types;
    if (types != null) {
      ctx.print('<');
      for (var i = 0; i < types.length; i++) {
        types[i].visitType(this, ctx);
        if (i < types.length - 1) {
          ctx.print(', ');
        }
      }
      ctx.print('>');
    }
    ctx.print('(');
    this.visitAllExpressions(ast.args, ctx, ',');
    ctx.print(')');
    return null;
  }

  @override
  dynamic visitBuiltinType(o.BuiltinType type, dynamic context) {
    EmitterVisitorContext ctx = context;
    var typeStr;
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
      default:
        throw new BaseException('Unsupported builtin type ${type.name}');
    }
    ctx.print(typeStr);
    return null;
  }

  @override
  dynamic visitExternalType(o.ExternalType ast, dynamic context) {
    EmitterVisitorContext ctx = context;
    this._visitIdentifier(ast.value, ast.typeParams, ctx);
    return null;
  }

  @override
  dynamic visitFunctionType(o.FunctionType type, dynamic context) {
    EmitterVisitorContext ctx = context;
    if (type.returnType != null) {
      type.returnType.visitType(this, ctx);
    } else {
      ctx.print('void');
    }
    ctx.print(' Function(');
    visitAllObjects((o.OutputType param) {
      param.visitType(this, ctx);
    }, type.paramTypes, ctx, ',');
    ctx.print(')');
    return null;
  }

  @override
  dynamic visitArrayType(o.ArrayType type, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('List<');
    if (type.of != null) {
      type.of.visitType(this, ctx);
    } else {
      ctx.print('dynamic');
    }
    ctx.print('>');
    return null;
  }

  @override
  dynamic visitMapType(o.MapType type, dynamic context) {
    EmitterVisitorContext ctx = context;
    ctx.print('Map<String, ');
    if (type.valueType != null) {
      type.valueType.visitType(this, ctx);
    } else {
      ctx.print('dynamic');
    }
    ctx.print('>');
    return null;
  }

  void _visitParams(List<o.FnParam> params, dynamic context) {
    EmitterVisitorContext ctx = context;
    this.visitAllObjects((param) {
      if (param.type != null) {
        param.type.visitType(this, ctx);
        ctx.print(" ");
      }
      ctx.print(param.name);
    }, params, ctx, ",");
  }

  void _visitIdentifier(CompileIdentifierMetadata value,
      List<o.OutputType> typeParams, dynamic context) {
    EmitterVisitorContext ctx = context;
    String prefix = '';
    bool isDeferred = false;
    if (value.moduleUrl != null && value.moduleUrl != _moduleUrl) {
      prefix = importsWithPrefixes[value.moduleUrl];
      if (prefix == null) {
        if (whiteListedImports.contains(value.moduleUrl)) {
          prefix = '';
        } else {
          prefix = 'import${importsWithPrefixes.length}';
          if (ctx.deferredModules.containsKey(value.moduleUrl)) {
            isDeferred = true;
            prefix = ctx.deferredModules[value.moduleUrl];
          }
        }
        importsWithPrefixes[value.moduleUrl] = prefix;
      }
    } else if (value.emitPrefix) {
      prefix = value.prefix ?? '';
    }
    if (isDeferred) {
      if (prefix.isNotEmpty) {
        ctx.print(value.name.isEmpty ? prefix : '$prefix.');
      }
    } else {
      if (value.moduleUrl != null && value.moduleUrl != _moduleUrl) {
        ctx.print(prefix.isEmpty ? '' : '$prefix.');
      }
      if (value.emitPrefix && value.prefix != null && value.prefix.isNotEmpty) {
        ctx.print('${value.prefix}.');
      }
    }
    ctx.print(value.name);
    if (typeParams != null && typeParams.length > 0) {
      ctx.print('<');
      visitAllObjects(
          (type) => type.visitType(this, ctx), typeParams, ctx, ',');
      ctx.print('>');
    }
  }
}

o.Expression getSuperConstructorCallExpr(o.Statement stmt) {
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

bool isConstType(o.OutputType type) {
  return type != null && type.hasModifier(o.TypeModifier.Const);
}
