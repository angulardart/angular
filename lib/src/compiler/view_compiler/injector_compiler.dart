import "package:angular2/core.dart" show Injectable;
import "package:angular2/src/facade/lang.dart" show isPresent, isBlank;

import "../compile_metadata.dart"
    show
        CompileInjectorModuleMetadata,
        CompileDiDependencyMetadata,
        CompileTokenMap,
        CompileProviderMetadata;
import "../identifiers.dart" show Identifiers, identifierToken;
import "../output/output_ast.dart" as o;
import "../parse_util.dart"
    show ParseSourceSpan, ParseLocation, ParseSourceFile;
import "../provider_parser.dart" show AppProviderParser;
import "../template_ast.dart" show ProviderAst;
import "constants.dart" show InjectMethodVars;
import "util.dart" show createDiTokenExpression, convertValueToOutputAst;

var mainModuleProp = o.THIS_EXPR.prop("mainModule");
var parentInjectorProp = o.THIS_EXPR.prop("parent");

class InjectorCompileResult {
  List<o.Statement> statements;
  String injectorFactoryVar;
  InjectorCompileResult(this.statements, this.injectorFactoryVar) {}
}

@Injectable()
class InjectorCompiler {
  InjectorCompileResult compileInjector(
      CompileInjectorModuleMetadata injectorModuleMeta) {
    var builder = new _InjectorBuilder(injectorModuleMeta);
    var sourceFileName = isPresent(injectorModuleMeta.moduleUrl)
        ? '''in InjectorModule ${ injectorModuleMeta . name} in ${ injectorModuleMeta . moduleUrl}'''
        : '''in InjectorModule ${ injectorModuleMeta . name}''';
    var sourceFile = new ParseSourceFile("", sourceFileName);
    var providerParser = new AppProviderParser(
        new ParseSourceSpan(new ParseLocation(sourceFile, null, null, null),
            new ParseLocation(sourceFile, null, null, null)),
        injectorModuleMeta.providers);
    providerParser.parse().forEach((provider) => builder.addProvider(provider));
    var injectorClass = builder.build();
    var injectorFactoryVar = '''${ injectorClass . name}Factory''';
    var injectorFactoryFnVar = '''${ injectorClass . name}FactoryClosure''';
    var injectorFactoryFn = o
        .fn(
            injectorClass.constructorMethod.params,
            [
              new o.ReturnStatement(o.variable(injectorClass.name).instantiate(
                  injectorClass.constructorMethod.params
                      .map((param) => o.variable(param.name))
                      .toList()))
            ],
            o.importType(Identifiers.Injector))
        .toDeclStmt(injectorFactoryFnVar);
    var injectorFactoryStmt = o
        .variable(injectorFactoryVar)
        .set(o.importExpr(Identifiers.InjectorFactory, [
          o.importType(injectorModuleMeta)
        ]).instantiate(
            [o.variable(injectorFactoryFnVar)],
            o.importType(Identifiers.InjectorFactory,
                [o.importType(injectorModuleMeta)], [o.TypeModifier.Const])))
        .toDeclStmt(null, [o.StmtModifier.Final]);
    return new InjectorCompileResult(
        [injectorClass, injectorFactoryFn, injectorFactoryStmt],
        injectorFactoryVar);
  }
}

class _InjectorBuilder {
  CompileInjectorModuleMetadata _mainModuleType;
  var _instances = new CompileTokenMap<o.Expression>();
  List<o.ClassField> _fields = [];
  List<o.Statement> _ctorStmts = [];
  List<o.ClassGetter> _getters = [];
  bool _needsMainModule = false;
  _InjectorBuilder(this._mainModuleType) {
    this._instances.add(identifierToken(Identifiers.Injector), o.THIS_EXPR);
  }
  addProvider(ProviderAst resolvedProvider) {
    var providerValueExpressions = resolvedProvider.providers
        .map((provider) => this._getProviderValue(provider))
        .toList();
    var propName =
        '''_${ resolvedProvider . token . name}_${ this . _instances . size}''';
    var instance = this._createProviderProperty(
        propName,
        resolvedProvider,
        providerValueExpressions,
        resolvedProvider.multiProvider,
        resolvedProvider.eager);
    this._instances.add(resolvedProvider.token, instance);
  }

  o.ClassStmt build() {
    this._ctorStmts.add(o.SUPER_EXPR.callFn([
          o.variable(parentInjectorProp.name),
          o.literal(this._needsMainModule),
          o.variable(mainModuleProp.name)
        ]).toStmt());
    List<o.Statement> getMethodStmts = this._instances.keys().map((token) {
      var providerExpr = this._instances.get(token);
      return new o.IfStmt(
          InjectMethodVars.token.identical(createDiTokenExpression(token)),
          [new o.ReturnStatement(providerExpr)]);
    }).toList();
    getMethodStmts.add(new o.IfStmt(
        InjectMethodVars.token
            .identical(
                createDiTokenExpression(identifierToken(this._mainModuleType)))
            .and(o.not(mainModuleProp.equals(o.NULL_EXPR))),
        [new o.ReturnStatement(mainModuleProp)]));
    var methods = [
      new o.ClassMethod(
          "getInternal",
          [
            new o.FnParam(InjectMethodVars.token.name, o.DYNAMIC_TYPE),
            new o.FnParam(InjectMethodVars.notFoundResult.name, o.DYNAMIC_TYPE)
          ],
          (new List.from(getMethodStmts)
            ..addAll([new o.ReturnStatement(InjectMethodVars.notFoundResult)])),
          o.DYNAMIC_TYPE)
    ];
    var ctor = new o.ClassMethod(
        null,
        [
          new o.FnParam(
              parentInjectorProp.name, o.importType(Identifiers.Injector)),
          new o.FnParam(mainModuleProp.name, o.importType(this._mainModuleType))
        ],
        this._ctorStmts);
    var injClassName = '''${ this . _mainModuleType . name}Injector''';
    return new o.ClassStmt(
        injClassName,
        o.importExpr(
            Identifiers.CodegenInjector, [o.importType(this._mainModuleType)]),
        this._fields,
        this._getters,
        ctor,
        methods);
  }

  o.Expression _getProviderValue(CompileProviderMetadata provider) {
    o.Expression result;
    if (isPresent(provider.useExisting)) {
      result = this._getDependency(
          new CompileDiDependencyMetadata(token: provider.useExisting));
    } else if (isPresent(provider.useFactory)) {
      var deps =
          isPresent(provider.deps) ? provider.deps : provider.useFactory.diDeps;
      var depsExpr = deps.map((dep) => this._getDependency(dep)).toList();
      result = o.importExpr(provider.useFactory).callFn(depsExpr);
    } else if (isPresent(provider.useClass)) {
      var deps =
          isPresent(provider.deps) ? provider.deps : provider.useClass.diDeps;
      var depsExpr = deps.map((dep) => this._getDependency(dep)).toList();
      result = o
          .importExpr(provider.useClass)
          .instantiate(depsExpr, o.importType(provider.useClass));
    } else {
      result = convertValueToOutputAst(provider.useValue);
    }
    if (isPresent(provider.useProperty)) {
      result = result.prop(provider.useProperty);
    }
    return result;
  }

  o.Expression _createProviderProperty(String propName, ProviderAst provider,
      List<o.Expression> providerValueExpressions, bool isMulti, bool isEager) {
    var resolvedProviderValueExpr;
    var type;
    if (isMulti) {
      resolvedProviderValueExpr = o.literalArr(providerValueExpressions);
      type = new o.ArrayType(o.DYNAMIC_TYPE);
    } else {
      resolvedProviderValueExpr = providerValueExpressions[0];
      type = providerValueExpressions[0].type;
    }
    if (isBlank(type)) {
      type = o.DYNAMIC_TYPE;
    }
    if (isEager) {
      this._fields.add(new o.ClassField(propName, type));
      this._ctorStmts.add(
          o.THIS_EXPR.prop(propName).set(resolvedProviderValueExpr).toStmt());
    } else {
      var internalField = '''_${ propName}''';
      this._fields.add(new o.ClassField(internalField, type));
      // Note: Equals is important for JS so that it also checks the undefined case!
      var getterStmts = [
        new o.IfStmt(o.THIS_EXPR.prop(internalField).isBlank(), [
          o.THIS_EXPR
              .prop(internalField)
              .set(resolvedProviderValueExpr)
              .toStmt()
        ]),
        new o.ReturnStatement(o.THIS_EXPR.prop(internalField))
      ];
      this._getters.add(new o.ClassGetter(propName, getterStmts, type));
    }
    return o.THIS_EXPR.prop(propName);
  }

  o.Expression _getDependency(CompileDiDependencyMetadata dep) {
    var result = null;
    if (dep.isValue) {
      result = o.literal(dep.value);
    }
    if (!dep.isSkipSelf) {
      if (isBlank(result)) {
        result = this._instances.get(dep.token);
      }
      if (isBlank(result) &&
          dep.token.equalsTo(identifierToken(this._mainModuleType))) {
        this._needsMainModule = true;
        result = mainModuleProp;
      }
    }
    if (isBlank(result)) {
      var args = [createDiTokenExpression(dep.token)];
      if (dep.isOptional) {
        args.add(o.NULL_EXPR);
      }
      result = parentInjectorProp.callMethod("get", args);
    }
    return result;
  }
}
